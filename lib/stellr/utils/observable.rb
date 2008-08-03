module Stellr
  module Utils
    module Observable

      def listeners
        @listeners ||= []
      end

      def add_listener( &block )
        listeners << block
      end

      def notify_listeners( event )
        listeners.each do |l|
          l.call event
        end
      end
    end
  end
end
