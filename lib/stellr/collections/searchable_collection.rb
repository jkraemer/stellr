module Stellr
  module Collections

    # Base class for searchable collection implementations
    class SearchableCollection < Base

      def initialize( name, options )
        super name, options
        @reader_monitor = Monitor.new
        @query_parser_monitor = Monitor.new
        @reader = @searcher = @query_parser = nil
      end


      # Search this collection.
      # Options is a hash taking the usual Ferret::Search::Searcher options,
      # plus:
      # [+page+]          Page of results to show, starting with 1
      # [+per_page+]      Number of records per page, default 10.
      # [+fields+]        Array of fields to search in
      # [+get_fields+]    Array of fields to retrieve in addition to the
      #                   :id field
      #
      # The page and per_page options take precedence over any given limit and
      # offset values.
      def search(query, options = {})
        results = Stellr::Search::SearchResults.new

        if options[:page]
          results.current_page = options.delete(:page).to_i
          options[:limit] = results.per_page = (options.delete(:per_page).to_i rescue nil) || 10
          options[:offset] = (p = results.current_page - 1) <= 0 ? 0 : p * results.per_page
        end

        get_fields = options.delete :get_fields
        # TODO replace synchronization with some kind of shared read/exclusive
        # write locking mechanism allowing parallel searches but guarding
        # against the reader instance being shut down while we're inside
        # retrieve_field_data
        @reader_monitor.synchronize do
          q = process_query query, options
          @logger.debug "options: #{options.inspect}"
          results.total_hits = searcher.search_each q, options do |id, score|
            field_data = retrieve_field_data(id, get_fields)
            results << Stellr::Search::SearchResult.new( id, score, field_data )
          end
          @logger.info "query #{query} : #{results.total_hits} results"
        end
        return results
      end

      def highlight( doc_id, query, options = {})
        return searcher.highlight(process_query(query, options), doc_id, options[:field], options)
      rescue
        @logger.error "error in highlight: #{$!}. Document #{doc_id}, Query: #{query}, options: #{options.inspect}"
        ''
      end

      def size
        reader.num_docs
      end

      def on_shutdown( mode )
        close
      end

      # close this collection
      def close
        close_reader
      end

      protected
      
      # should open a reader and return it
      def open_reader
        raise 'not implemented'
      end

      def reader
        @reader_monitor.synchronize do
          @reader ||= open_reader
        end
      end

      def searcher
        @reader_monitor.synchronize do
          @searcher ||= Ferret::Search::Searcher.new reader
        end
      end

      def query_parser
        @query_parser_monitor.synchronize do
          @query_parser ||= create_query_parser
        end
      end

      def create_query_parser(options = {})
        Ferret::QueryParser.new( { :analyzer => create_analyzer, :or_default => false }.merge( options ) )
      end

      # reads field data for +:id+ and any other given fields from 
      # the document given by +id+
      # unsynchronized reader access occurs, so only use from within blocks
      # synchronizing on @reader_monitor.
      def retrieve_field_data(id, fields = nil)
        doc = reader[id]
        field_data = { :id => doc[:id] }
        fields.each do |f|
          field_data[f] = doc[f]
        end if fields
        return field_data
      end

      # Turn a query string into a Ferret Query object.
      # unsynchronized reader access occurs, so only use from
      # within blocks synchronizing on @reader_monitor.
      def process_query(query, options)
        @logger.debug "process_query: #{query.inspect}"
        q = query.dup
        if String === q
          @query_parser_monitor.synchronize do
            qp = query_parser
            tokenized_fields = reader.tokenized_fields
            qp.fields = options[:fields] || tokenized_fields # reader.fields
            qp.tokenized_fields = tokenized_fields
            @logger.debug "tokenized_fields: #{tokenized_fields}"
            q = qp.parse q
          end
        end
        @logger.debug "processed query: #{q.inspect}"
        return q
      rescue
        @logger.error "error processing query: #{$!}"
      end
      
      def collection_directory
        @options[:path]
      end
      
      def close_reader
        @reader_monitor.synchronize do
          notify_listeners( :closing_reader )
          return unless @reader
          @query_parser = nil
          @searcher.close if @searcher
          @searcher = nil
          @reader.close
          @reader = nil
        end
      end

      # TODO allow declarative analyzer specification in options
      def create_analyzer
        if class_name = @options[:analyzer] 
          @logger.debug "instantiating analyzer #{class_name}"
          return class_name.constantize.new
        end
        return Ferret::Analysis::StandardAnalyzer.new
      end

    end

  end

end

