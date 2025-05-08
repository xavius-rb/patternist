# frozen_string_literal: true

module Patternist
  module Controllers
    # Provides pagination support for collections
    # This module can work with any pagination gem (e.g., kaminari, will_paginate)
    module Pagination
      # Default page size for collections
      DEFAULT_PAGE_SIZE = 25

      protected

      # Paginates a collection using the configured paginator
      # @param collection [Object] The collection to paginate
      # @return [Object] The paginated collection
      def paginate(collection)
        return collection unless pagination_enabled?

        page = (params[:page] || 1).to_i
        per_page = (params[:per_page] || default_page_size).to_i

        if defined?(Kaminari)
          collection.page(page).per(per_page)
        elsif defined?(WillPaginate)
          collection.paginate(page: page, per_page: per_page)
        else
          collection
        end
      end

      # @return [Boolean] Whether pagination is enabled
      def pagination_enabled?
        defined?(Kaminari) || defined?(WillPaginate)
      end

      # @return [Integer] The default page size
      def default_page_size
        self.class.const_get(:PER_PAGE) rescue DEFAULT_PAGE_SIZE
      end
    end
  end
end