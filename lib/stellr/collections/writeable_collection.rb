module Stellr
  module Collections

    # Base class for collection implementations that allow index updates
    class WriteableCollection < SearchableCollection

      def initialize( name, options )
        super
        @writer_monitor = Monitor.new
        @processed_records = 0
        @writer = nil
      end

      # Adds the given record to the index.
      #
      # Record may be a hash, or a Ferret::Document instance
      def add_record( record, boost = nil )
        raise ArgumentError.new("record must contain :id field") if record[:id].nil?
        if boost
          if Ferret::Document === record
            record.boost = boost
          else
            hash, record = record, Ferret::Document.new( boost )
            hash.each_pair do |k,v|
              record[k] = v
            end
          end
        end
        @writer_monitor.synchronize do
          @processed_records += 1
          w = writer
          w.delete :id, record[:id].to_s # ensure uniqueness by :id field
          w << record
        end
        true
      end
      alias :<< :add_record

      def delete_record( record )
        raise ArgumentError.new("record must contain :id field") if record[:id].nil?
        @writer_monitor.synchronize do
          @processed_records += 1
          writer.delete :id, record[:id].to_s
        end
        true
      end

      # true if records have been processed since the last call to clear!
      def dirty?
        @processed_records > 0
      end

      def clear!
        @processed_records = 0
      end

      # called whenever the strategy thinks it's a good time do do something
      # timeconsuming (like switching indexes, optimizing, flushing, ...)
      def batch_finished
      end

      # close this collection
      def close
        close_writer
        super
      end

      # flush any unwritten changes to the index
      def flush
        @writer_monitor.synchronize do
          writer.commit
        end
      end

      # optimize the index
      def optimize
        @writer_monitor.synchronize do
          writer.optimize
        end
      end

    protected
      
      # should open a writer and return it
      def open_writer
        raise 'not implemented'
      end

      def writer
        @writer_monitor.synchronize do
          @writer ||= open_writer
        end
      end
      
      
      def close_writer
        @writer_monitor.synchronize do
          notify_listeners( :closing_writer )
          return unless @writer
          @writer.close
          @writer = nil
        end
      end 

      def create_field_infos
        field_infos = FieldInfos.new @options[:field_defaults] || {}
        @options[:fields].each do |name, definition|
          field_infos.add_field( name, definition )
        end if @options[:fields]
        # provide default settings for :id field
        field_infos.add_field :id, :store => :yes, :index => :untokenized unless field_infos[:id]
        field_infos
      end
      
    end

  end

end
