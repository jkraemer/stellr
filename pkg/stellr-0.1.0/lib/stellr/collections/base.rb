module Stellr
  module Collections

    # Base class for collection implementations
    class Base
      include Ferret::Index
      include Stellr::Utils::Shutdown
      include Stellr::Utils::Observable
      attr_reader :name

      def self.create( name, options )
        collection_class = collection_class_for_options options
        collection       = collection_class.new( name, options )
        if strategy_class = strategy_class_for_options( options )
          strategy_class.new( collection, options )
        else
          collection
        end
      end

      def initialize( name, options )
        @logger = options[:logger]
        @name = name
        @options = options.dup
      end

      # called whenever the strategy thinks it's a good time do do something
      # timeconsuming (like switching indexes, optimizing, flushing, ...)
      def batch_finished
      end

      def on_shutdown( mode )
        close
      end

      # close this collection
      def close
      end

    protected
      
      
      def collection_directory
        @options[:path]
      end
      

      def self.collection_class_for_options( options )
        if (c = options.delete(:collection))
          options[:collection_class] = collection_class_for_key c
        end
        Object.module_eval("::#{options[:collection_class] || 'Stellr::Collections::RSync'}", __FILE__, __LINE__)
      end
      def self.collection_class_for_key(key)
        case key
        when :static
          'Stellr::Collections::Static'
        when :rsync
          'Stellr::Collections::RSync'
        end
      end

      def self.strategy_class_for_options( options )
        if (c = options.delete(:strategy))
          options[:strategy_class] = strategy_class_for_key c
        end
        Object.module_eval("::#{options[:strategy_class]}", __FILE__, __LINE__) if options[:strategy_class]
      end
      def self.strategy_class_for_key(key)
        case key
        when :queueing
          'Stellr::Strategies::Queueing'
        end
      end
    end

  end

end
