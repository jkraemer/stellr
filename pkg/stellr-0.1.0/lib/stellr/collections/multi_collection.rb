module Stellr
  module Collections

    # 
    class MultiCollection < SearchableCollection

      def initialize( name, collections, options = {} )
        super name, options
        @collections = {}
        collections.each do |collection|
          @collections[collection.name] = collection
          collection.add_listener do |event|
            handle_event(collection.name, event)
          end
        end
      end

    protected

      def open_reader
        IndexReader.new @collections.values.map{|c| c.reader}
      end

      def handle_event(collection_name, event)
        @logger.debug "handle_event: #{event.inspect}"
        close_reader if event == :closing_reader
      end

    end

  end
end
