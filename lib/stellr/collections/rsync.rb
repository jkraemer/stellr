module Stellr
  module Collections

    # RSync collection implementation.
    #
    # Keeps two indexes around - one for searching and one for indexing. The
    # difference when compared with the Static collection is that every
    # now and then the changes are synced from the latter to the former using RSync,
    # so no complete rebuild is necessary after a switch.
    class RSync < Static

      def batch_finished
        switch if dirty?
      end

      # we want the indexes to be in sync after close, so do a last switch
      alias :close :switch

      protected

      def writer_options
        super.merge :create => @options[:recreate]
      end
      
      # overridden to sync the indexes after re-linking
      def relink_indexes
        super
        sync_indexes
      end

      def sync_indexes
        logger.debug "syncing #{searching_directory} to #{indexing_directory} ..."
        system("rsync -r --delete #{searching_directory}/ #{indexing_directory}")
        logger.debug "done."
      end

    end

  end
end
