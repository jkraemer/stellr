module Stellr
  module Search
  
    # A single search result
    class SearchResult
      attr_reader :score, :doc_id

      def initialize(id, score, field_data)
        @doc_id = id
        @score = score
        @field_data = field_data
      end

      # retrieve contents of the field +name+
      def field(name)
        @field_data[name]
      end
      alias [] field
    end
  end
end
