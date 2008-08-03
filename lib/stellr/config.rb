require 'yaml'
require 'erb'

module Stellr
  # = Config
  #
  # The +stellr+ and +stellr-search+ commands both rely on a YAML file
  # to provide some basic configuration:
  #
  # +:port+      Port the server should listen to
  # +:host+      Hostname or IP of the server
  # +:script+    Optional ruby file to load during startup. This is the place to load custom code like self made Analyzers you intend to use.
  # +:log_level+ Log level, default is +:debug+
  # +:base_dir+  Base directory where the server will store index data, log
  #              files and configuration data.
  # +:data_dir+  Index directory, relative to +base_dir+. Defaults to +data+
  # +:log_dir+   Log file directory, relative to +base_dir+. Defaults to +log+
  # +:conf_dir+  Configuration directory, relative to +base_dir+. Defaults to +conf+. Here stellr will keep the configuration of registered collections, one YAML file per collection.
  # +:tmp_dir+   Temp directory, relative to +base_dir+. Defaults to +tmp+
  #
  #
  class Config
    DEFAULTS = { :port           => 9010,
                 :host           => 'localhost',
                 :base_dir       => '/var/stellr',
                 :data_dir       => 'data',
                 :log_dir        => 'log',
                 :tmp_dir        => 'tmp',
                 :conf_dir       => 'conf',
                 :log_level      => :warn }
                 
                 
    # Configfile search order:
    #  - argument
    #  - /etc/stellr.yml
    #  - +gem_directory+/config/stellr.yml 
    #
    def initialize( config_file = nil, extra_options = {} )
      load_config config_file
      @config.update extra_options
      @config.each { |k,v| v.untaint } # we trust our config file
    end
    
    def data_dir
      resolve_directory_name( :data_dir )
    end
    
    def log_dir
      resolve_directory_name( :log_dir )
    end
    
    def tmp_dir
      resolve_directory_name( :tmp_dir ) 
    end
    
    def conf_dir
      resolve_directory_name( :conf_dir ) 
    end
    
    def collection_dir
    end

    def drb_uri
      "druby://#{host}:#{port}"
    end
    
    protected

    def method_missing( method_name, *args )
      return @config[method_name] if @config.has_key?( method_name )
      raise NameError.new( "unknown configuration key: #{method_name}" )
    end

    def resolve_directory_name( sub_dir )
      raise NameError.new unless @config.has_key?( sub_dir )
      File.join( base_dir, @config[sub_dir] )      
    end
            
    def load_config( config_file )
      config_file ||= "/etc/stellr.yml"
      config_file = File.join( File.dirname(__FILE__), "../../config/stellr.yml" ) unless File.exists?( config_file )
      
      @config = DEFAULTS.merge(
                  YAML.load( ERB.new( IO.read(config_file) ).result )
                )
    end
  end
end
