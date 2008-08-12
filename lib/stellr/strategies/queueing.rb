module Stellr

  module Strategies

    # Queueing strategy. Any index modifying methods return immediately, actions 
    # are queued and executed asynchronously in order of arrival.
    #
    # Unless you're using the static collection type, indexes will be switched
    # whenever options[:max_batch_size] (which defaults to 200) is reached,
    # and when the queue is empty.
    #
    # with static collections manually calling switch is required, and this call
    # will block until the switch is actually done. 
    #
    # However this does not mean that
    # all records from the queue have been processed, the switch may also occur
    # between processing of add_record or add_records calls.
    #
    # FIXME fix this: switch should be an operation that is enqueued just like
    # add_record so it occurs at the point in time the client desires.
    # Is implicit switching really that useful? Definitely not with static collections...
    class Queueing < Base

      def initialize( collection, options )
        super collection, options
        @options[:max_batch_size] ||= 200
        @queue = Queue.new
        @thread = spawn_indexing_thread
      end

      def add_record( record, boost = nil )
        enqueue :add, [record, boost]
      end
      
      def add_records(records)
        enqueue :bulk_add, records
      end
      
      def delete_record( record )
        enqueue :delete, record
      end

      protected

      def on_shutdown( mode )
        @queue << 'shutting down' # letztes queue item damit process_queue nicht haengt
        @thread.join
        # save_queue :TODO:
        @collection.shutdown mode
      end

      # called by the indexer thread as long as the server runs
      def process_queue
        counter = 0
        max_batch_size = @options[:max_batch_size]
        begin
          while record = @queue.deq and not shutting_down?( :abort )
            process_record( *record )
            break if ((counter += 1) > max_batch_size) or @queue.empty?
          end
          @collection.batch_finished
        rescue Exception => e
          puts "OH NO! #{e}\n#{e.backtrace.join "\n"}"
        end
      end

      # process a single task from the queue
      # TODO refacoring: rename to process_task
      def process_record( action, data )
        case action
          when :add
            @collection.add_record( *data )
          when :bulk_add
            @collection.add_records data
          when :delete
            @collection.delete_record data
          else
            raise "UnknownAction"
        end
      end

      # Spawns the thread executing the main loop
      def spawn_indexing_thread
        Thread.new do
          process_queue while !shutting_down?
        end
      end

      # add a task to the queue
      def enqueue( action, record )
        return false if shutting_down?
        @queue << [ action, record ]
        true
      end

    end

  end
end
