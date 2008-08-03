module Stellr
  module Collections

    # Static collection implementation.
    #
    # This kind of collection is for situations where your index usually doesn't 
    # change but instead is rebuilt from scratch once in a while.
    #
    # This collection keeps two indexes, one for searching, and one where all index
    # modifications take place. Once you are finished building the new index,
    # call the switch method to put it live. The old index is then dropped and
    # the new one is used for searching from now on.
    class Static < WriteableCollection

      def initialize( name, options )
        super( name, options )
        reader
        writer
      end

      def switch
        @logger.info "switching indexes"
        @writer_monitor.synchronize do
          flush
          optimize
          close_writer
          @reader_monitor.synchronize do
            close_reader
            relink_indexes
            clear!
          end
        end
      end

      protected

      def open_writer
        create_directories unless File.exists? indexing_directory # and File.exists? searching_directory
        IndexWriter.new writer_options
      end

      def writer_options
        {
          :path        => indexing_directory,
          :create      => true,
          :field_infos => create_field_infos,
          :analyzer    => create_analyzer
        }
      end
      
      def open_reader
        already_retried = false
        begin
          switch unless File.symlink? searching_directory
          IndexReader.new searching_directory
        rescue Ferret::FileNotFoundError
          switch
          unless already_retried
            already_retried = true
            retry
          end
        end
      end

      def create_directories
        FileUtils.mkdir_p index_storage_directory( '0' )
        FileUtils.mkdir_p index_storage_directory( '1' )
        FileUtils.ln_s index_storage_directory( '0' ), indexing_directory, :force => true
        FileUtils.ln_s index_storage_directory( '1' ), searching_directory, :force => true
      end

      def indexing_directory
        File.join( collection_directory, "indexing" )
      end
      
      def searching_directory
        File.join( collection_directory, "searching" )
      end

      def index_storage_directory( suffix )
        File.join( collection_directory, suffix )      
      end
      
      def relink_indexes
        searching = File.readlink( searching_directory ).untaint
        indexing  = File.readlink( indexing_directory ).untaint
        @logger.info "relink_indexes: #{searching} will now be used for indexing"
        File.delete indexing_directory
        File.delete searching_directory
        FileUtils.ln_s indexing, searching_directory, :force => true
        FileUtils.ln_s searching,  indexing_directory, :force => true
      end
      
    end

  end
end
