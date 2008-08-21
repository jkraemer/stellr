require 'logger'

module Stellr
  class Server
    include Utils::Shutdown
    protected :shutdown

    attr_accessor :config
    attr_reader   :collections

    def initialize( config )
      @config = config
      create_directories
      @logger = Logger.new File.join(config.log_dir, 'stellr.log')
      @logger.level = Logger.const_get config.log_level.to_s.upcase
      @collections = {}
      @collections.extend MonitorMixin
    end
    
    def add_record( collection_name, record, boost = nil )
      collection( collection_name ).add_record record, boost
    end
    alias :<< :add_record
    
    def delete_record( collection_name, record )
      collection( collection_name ).delete_record record
    end
    
    def size( collection_name )
      collection( collection_name ).size
    end

    # Initialize a collection.
    #
    # Before anything can be done with a collection, it has to be registered
    # through this method. When called for a non-existing collection, this will
    # also create the empty physical index. The given options are saved to a yml
    # file so they can be loaded again later on.
    #
    # Calling register for an existing collection will update the saved index
    # configuration from the options given, unless the options hash is nil.
    # An already existing physical index won't be touched and used as is.
    # Remember that changing Ferret options like analyzers or field
    # configuration requires an index rebuild to be effective for existing
    # content. Stellr doesn't take care of this.
    #
    # If you access the server through the Stellr::Client class you don't need
    # to call +register+ explicitly as the client will do it when connecting.
    #
    # Name is the name of the collection to create.
    #
    # Options is a hash, consisting of:
    # [+collection+]  The collection implementation to use, may be one of :static or :rsync (default)
    # [+strategy+]    The strategy implementation to use (optional, atm there is only :queueing)
    # [+fields+]            +hash+ (see http://ferret.davebalmain.com/api/classes/Ferret/Index/FieldInfo.html)
    # [+recreate+]          Recreate the index (defaults to +false+). A true value will lead to the deletion of any already indexed data.
    # [+analyzer+]          The class name (String) of the Analyzer to use for this collection. By default, Ferret's StandardAnalyzer will be used. 
    # [+field_defaults+] Default setting for unconfigured fields
    #
    # Example
    #   register 'standard_index', { :recreate => false,
    #                                :fields   =>  { :author  => { :index       => :untokenized,
    #                                                  :store       => :no,
    #                                                  :term_vector => :with_offsets,
    #                                                  :boost       => 2.0 },
    #                                                :content => { :index       => :tokenized } }
    #                              }
    #
    #
    def register( name, options = {} )
      untaint_collection_name name
      @collections.synchronize do
        collection = (@collections[name] ||= create_collection( name, options ))
        save_collection_config name, options unless options.nil? or options.empty?
        collection
      end
    end

    # Initializes a read-only virtual collection that may be used to search
    # across multiple physical collections.
    #
    # Returns the name of the collection to be used with further calls.
    def register_multi_collection( names, options = {} )
      key = ".multi_#{names.join '_'}" # '.' is not allowed for regular collection names, so we are safe from name collisions
      @collections.synchronize do
        @collections[key] ||= create_multi_collection( key, names.map{ |name| collection(name) }, options )
      end
      return key
    end

    def collection( name )
      @collections.synchronize do
        if @collections.has_key?( name )
          return @collections[name] 
        else
          @logger.info "trying to initialize collection #{name} from stored configuration..."
          return @collections[name] = create_collection( name, nil )
        end
      end
      raise "UnknownCollection #{name}"
    end

    protected
    
    # pass through commands to collection
    def method_missing(method, *args)
      if args.size >= 1
        collection_name = args.shift
        return collection( collection_name ).send( method, *args )
      end
      super
    end

    def create_multi_collection( name, collections, options = {} )
      Stellr::Collections::MultiCollection.new name, collections, { :logger => @logger }.merge(options)
    end

    # initializes a new collection object
    #
    # if nil is given for options, the method tries to locate a previously
    # saved collection configuration and restore from it.
    def create_collection( name, options )
      options ||= load_collection_config name
      raise "No options given for collection #{name} and no stored configuration found." if options.nil?

      options[:path] = File.join( @config.data_dir, name )
      return Collections::Base.create( name, {:logger => @logger}.merge(options) )
    end

    # TODO move into collection?
    def save_collection_config( name, options )
      path = collection_config_path name
      ( File.open(path, 'w') << YAML.dump(options) ).close
      @logger.info "wrote collection config to #{path}"
      @logger.debug "config is now:\n#{options.inspect}"
    end

    def load_collection_config( name )
      path = collection_config_path name
      @logger.debug "trying to load collection config from #{path}"
      conf = begin
        YAML.load( File.read(path) ) if File.readable?(path)
      rescue
        @logger.error "error loading config: #{$!}\n#{$!.backtrace.join "\n"}"
        nil
      end
      @logger.info "loaded collection config from #{path}" unless conf.nil?
      return conf
    end

    def collection_config_path( name )
      untaint_collection_name name
      File.join @config.conf_dir, "#{name.untaint}.yml"
    end
    
    def untaint_collection_name(name)
      raise "invalid collection name >#{name}<, may only contain a-zA-Z0-9_-" unless name =~ /^([a-zA-Z0-9_-]+)$/
      name.untaint
    end

    # called by shutdown
    def on_shutdown( mode )
      @collections.synchronize do
        @collections.values.each { |coll| coll.shutdown mode }
      end
    end

    def create_directories
      FileUtils.mkdir_p config.log_dir
      FileUtils.mkdir_p config.tmp_dir
      FileUtils.mkdir_p config.conf_dir
      FileUtils.mkdir_p config.data_dir
    end

  end
end
