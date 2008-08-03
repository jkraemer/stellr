module Stellr
  module Utils
    module Shutdown

      # shutdown modes:
      #   - :abort - stops immediately
      #   - :graceful process all remaining queue entries and stop
      def shutdown( mode = :abort )
        @shutdown = mode
        on_shutdown mode
      end
      
      def shutting_down?( mode = nil )
        if defined? @shutdown
          mode.nil? || @shutdown == mode
        else
          false
        end
      end

      protected

      # override to hook into the shutdown process
      def on_shutdown
      end

    
    end
  end
end
