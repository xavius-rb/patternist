# frozen_string_literal: true

module Patternist
  module Controllers
    # Provides pagination support for collections
    #
    # This module can work with any pagination gem (e.g., kaminari, will_paginate)
    # and provides a unified interface for paginating collections. It automatically
    # detects available pagination gems and uses appropriate methods.
    #
    # @example Basic usage
    #   class PostsController
    #     include Patternist::Controllers::Pagination
    #
    #     def index
    #       @posts = paginate(Post.all)
    #     end
    #   end
    #
    # @example Custom page size
    #   class PostsController
    #     include Patternist::Controllers::Pagination
    #
    #     PER_PAGE = 50  # Override default page size
    #
    #     def index
    #       @posts = paginate(Post.all)
    #     end
    #   end
    #
    # @example Bulk operations with pagination
    #   def bulk_update
    #     items = paginate_bulk_operation(selected_items) do |batch|
    #       batch.update_all(status: 'processed')
    #     end
    #   end
    module Pagination
      # Default page size for collections when no custom PER_PAGE is defined
      DEFAULT_PAGE_SIZE = 25

      # Default batch size for bulk operations
      DEFAULT_BULK_BATCH_SIZE = 100

      protected

      # Paginates a collection using the configured paginator
      #
      # Automatically detects and uses available pagination gems:
      # - Kaminari (preferred)
      # - WillPaginate
      # - Falls back to returning the original collection if no gem is available
      #
      # @param collection [Object] The collection to paginate (e.g., ActiveRecord::Relation)
      # @param page [Integer, nil] Override page number (uses params[:page] if not provided)
      # @param per_page [Integer, nil] Override page size (uses params[:per_page] or default if not provided)
      # @return [Object] The paginated collection
      # @raise [ParameterError] If page or per_page parameters are invalid
      #
      # @example Basic pagination
      #   paginate(Post.all)
      #
      # @example With custom parameters
      #   paginate(Post.all, page: 2, per_page: 10)
      def paginate(collection, page: nil, per_page: nil)
        return collection unless pagination_enabled?

        page_num = validate_page_param(page || params[:page] || 1)
        per_page_num = validate_per_page_param(per_page || params[:per_page] || default_page_size)

        paginate_with_gem(collection, page_num, per_page_num)
      end

      # Performs bulk operations with pagination to handle large datasets efficiently
      #
      # This method processes large collections in smaller batches to avoid memory
      # issues and provide better performance for bulk operations.
      #
      # @param collection [Object] The collection to process
      # @param batch_size [Integer] Size of each batch (defaults to DEFAULT_BULK_BATCH_SIZE)
      # @yield [Object] Block to execute for each batch
      # @yieldparam batch [Object] Current batch of items
      # @return [Array] Results from each batch operation
      # @raise [ParameterError] If batch_size is invalid
      #
      # @example Bulk update operation
      #   results = paginate_bulk_operation(Post.published) do |batch|
      #     batch.update_all(featured: true)
      #   end
      #
      # @example Bulk delete with custom batch size
      #   paginate_bulk_operation(old_posts, batch_size: 50) do |batch|
      #     batch.delete_all
      #   end
      def paginate_bulk_operation(collection, batch_size: DEFAULT_BULK_BATCH_SIZE, &block)
        unless block_given?
          raise ParameterError, "Block is required for bulk operations"
        end

        batch_size = validate_batch_size(batch_size)
        results = []

        if collection.respond_to?(:find_in_batches)
          # ActiveRecord-style batching
          collection.find_in_batches(batch_size: batch_size) do |batch|
            results << yield(batch)
          end
        elsif collection.respond_to?(:each_slice)
          # Array-style batching
          collection.each_slice(batch_size) do |batch|
            results << yield(batch)
          end
        else
          # Fallback: process entire collection at once
          results << yield(collection)
        end

        results
      end

      # @return [Boolean] Whether pagination is enabled (pagination gem available)
      def pagination_enabled?
        defined?(Kaminari) || defined?(WillPaginate)
      end

      # @return [Integer] The default page size for this controller
      #
      # Checks for a PER_PAGE constant in the controller class, falls back to DEFAULT_PAGE_SIZE
      #
      # @example Setting custom page size
      #   class PostsController
      #     PER_PAGE = 50
      #     include Patternist::Controllers::Pagination
      #   end
      def default_page_size
        self.class.const_get(:PER_PAGE)
      rescue NameError
        DEFAULT_PAGE_SIZE
      end

      # Returns pagination metadata for API responses
      # @param collection [Object] The paginated collection
      # @return [Hash] Pagination metadata
      #
      # @example
      #   pagination_meta(@posts)
      #   #=> {
      #   #     current_page: 2,
      #   #     total_pages: 10,
      #   #     total_count: 250,
      #   #     per_page: 25
      #   #   }
      def pagination_meta(collection)
        if defined?(Kaminari) && collection.respond_to?(:current_page)
          {
            current_page: collection.current_page,
            total_pages: collection.total_pages,
            total_count: collection.total_count,
            per_page: collection.limit_value
          }
        elsif defined?(WillPaginate) && collection.respond_to?(:current_page)
          {
            current_page: collection.current_page,
            total_pages: collection.total_pages,
            total_count: collection.total_entries,
            per_page: collection.per_page
          }
        else
          {}
        end
      end

      private

      # Paginates collection using the appropriate gem
      # @param collection [Object] Collection to paginate
      # @param page [Integer] Page number
      # @param per_page [Integer] Items per page
      # @return [Object] Paginated collection
      def paginate_with_gem(collection, page, per_page)
        if defined?(Kaminari)
          collection.page(page).per(per_page)
        elsif defined?(WillPaginate)
          collection.paginate(page: page, per_page: per_page)
        else
          collection
        end
      end

      # Validates page parameter
      # @param page [Object] Page parameter to validate
      # @return [Integer] Validated page number
      # @raise [ParameterError] If page is invalid
      def validate_page_param(page)
        page_int = page.to_i

        if page_int < 1
          raise ParameterError, "Page must be a positive integer, got: #{page}"
        end

        page_int
      end

      # Validates per_page parameter
      # @param per_page [Object] Per page parameter to validate
      # @return [Integer] Validated per page number
      # @raise [ParameterError] If per_page is invalid
      def validate_per_page_param(per_page)
        per_page_int = per_page.to_i

        if per_page_int < 1
          raise ParameterError, "Per page must be a positive integer, got: #{per_page}"
        end

        if per_page_int > 1000  # Reasonable upper limit
          raise ParameterError, "Per page cannot exceed 1000, got: #{per_page_int}"
        end

        per_page_int
      end

      # Validates batch size parameter
      # @param batch_size [Object] Batch size to validate
      # @return [Integer] Validated batch size
      # @raise [ParameterError] If batch_size is invalid
      def validate_batch_size(batch_size)
        batch_size_int = batch_size.to_i

        if batch_size_int < 1
          raise ParameterError, "Batch size must be a positive integer, got: #{batch_size}"
        end

        if batch_size_int > 10000  # Reasonable upper limit
          raise ParameterError, "Batch size cannot exceed 10000, got: #{batch_size_int}"
        end

        batch_size_int
      end
    end
  end
end