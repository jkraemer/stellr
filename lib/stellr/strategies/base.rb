module Stellr
  module Strategies
    class Base
      include Stellr::Utils::Shutdown

      def initialize( collection, options )
        @collection = collection
        @options = options.dup
      end

      def method_missing(name, *args)
        @collection.send name, *args
      end
    end
  end
end
