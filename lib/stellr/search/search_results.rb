module Stellr
  module Search

    # Thin wrapper around an array of search results
    class SearchResults
      attr_accessor :total_hits, :current_page, :per_page
      alias total_entries total_hits

      def initialize
        @results = []
      end
      
      def to_json
        {
          :results => @results,
          :total_hits => total_hits,
          :current_page => current_page,
          :per_page => per_page
        }.to_json
      end

      def method_missing(symbol, *args, &block)
        @results.send(symbol, *args, &block)
      end

      def respond_to?(name)
        self.methods.include?(name) || @results.respond_to?(name)
      end


      # code from here on derived from will_paginate's collection.rb

      # The total number of pages.
      def total_pages
        @total_pages ||= per_page > 0 ? (total_hits / per_page.to_f).ceil : 0
      end
      alias page_count total_pages

      # Current offset of the paginated collection. If we're on the first page,
      # it is always 0. If we're on the 2nd page and there are 30 entries per page,
      # the offset is 30. This property is useful if you want to render ordinals
      # besides your records: simply start with offset + 1.
      #
      def offset
        (current_page - 1) * per_page
      end

      # current_page - 1 or nil if there is no previous page
      def previous_page
        current_page > 1 ? (current_page - 1) : nil
      end

      # current_page + 1 or nil if there is no next page
      def next_page
        current_page < page_count ? (current_page + 1) : nil
      end
    end
  end
end
