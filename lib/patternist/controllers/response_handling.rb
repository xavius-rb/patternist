# frozen_string_literal: true

module Patternist
  module Controllers
    # Handles HTTP and JSON response formatting for controllers
    #
    # This module provides consistent response patterns across controllers,
    # supporting both HTML and JSON formats with customizable handlers.
    # It follows Rails conventions for response handling while providing
    # flexibility for custom formatting.
    #
    # @example Basic usage
    #   class PostsController
    #     include Patternist::Controllers::ResponseHandling
    #
    #     def create
    #       @post = Post.new(post_params)
    #
    #       format_response(@post,
    #                       notice: "Post created successfully",
    #                       status: :created,
    #                       on_error_render: :new) do
    #         @post.save
    #       end
    #     end
    #   end
    #
    # @example Custom format handlers
    #   format_response(@post,
    #                   notice: "Success",
    #                   status: :ok,
    #                   on_error_render: :edit,
    #                   formats: {
    #                     html: -> { redirect_to custom_path },
    #                     json: -> { render json: custom_serializer(@post) },
    #                     error_html: -> { render :custom_error },
    #                     error_json: -> { render json: { error: "Custom error" } }
    #                   }) do
    #     @post.update(post_params)
    #   end
    module ResponseHandling
      # Formats response based on success/failure and request format
      #
      # This method provides a unified interface for handling both successful
      # and error responses across different formats (HTML, JSON, etc.).
      #
      # @param resource [Object] The resource being operated on
      # @param notice [String] Success message for HTML responses
      # @param status [Symbol] HTTP status code for successful responses
      # @param on_error_render [Symbol] Template to render on HTML error responses
      # @param formats [Hash] Custom format handlers
      # @option formats [Proc] :html Custom HTML success handler
      # @option formats [Proc] :json Custom JSON success handler
      # @option formats [Proc] :error_html Custom HTML error handler
      # @option formats [Proc] :error_json Custom JSON error handler
      # @yield [Object] Block that determines success/failure by its return value
      # @yieldreturn [Boolean] true for success, false for failure
      # @return [void]
      #
      # @example Basic usage
      #   format_response(@post, notice: "Created", status: :created, on_error_render: :new) do
      #     @post.save
      #   end
      #
      # @example With custom handlers
      #   format_response(@post,
      #                   notice: "Updated",
      #                   status: :ok,
      #                   on_error_render: :edit,
      #                   formats: {
      #                     json: -> { render json: @post, serializer: CustomSerializer }
      #                   }) do
      #     @post.update(params)
      #   end
      def format_response(resource, notice:, status:, on_error_render:, formats: {}, &block)
        validate_format_response_params!(resource, notice, status, on_error_render, block)

        respond_to do |format|
          if block.call
            handle_success(format, resource, notice, status, formats)
          else
            handle_error(format, resource, on_error_render, formats)
          end
        end
      rescue StandardError => e
        handle_format_response_error(e, resource)
      end

      private

      # Handles successful responses for different formats
      # @param format [Object] The format object from respond_to
      # @param resource [Object] The resource being operated on
      # @param notice [String] Success message
      # @param status [Symbol] HTTP status code
      # @param custom_formats [Hash] Custom format handlers
      # @return [void]
      def handle_success(format, resource, notice, status, custom_formats)
        format.html do
          if custom_formats[:html]
            custom_formats[:html].call
          else
            redirect_to resource, notice: notice
          end
        end

        format.json do
          if custom_formats[:json]
            custom_formats[:json].call
          else
            render :show, status: status, location: resource
          end
        end

        # Handle any additional custom formats
        handle_custom_success_formats(format, custom_formats, resource, notice, status)
      end

      # Handles error responses for different formats
      # @param format [Object] The format object from respond_to
      # @param resource [Object] The resource being operated on
      # @param on_error_render [Symbol] Template to render for HTML errors
      # @param custom_formats [Hash] Custom format handlers
      # @return [void]
      def handle_error(format, resource, on_error_render, custom_formats)
        format.html do
          if custom_formats[:error_html]
            custom_formats[:error_html].call
          else
            render on_error_render, status: :unprocessable_entity
          end
        end

        format.json do
          if custom_formats[:error_json]
            custom_formats[:error_json].call
          else
            render json: extract_errors(resource), status: :unprocessable_entity
          end
        end

        # Handle any additional custom error formats
        handle_custom_error_formats(format, custom_formats, resource, on_error_render)
      end

      # Handles custom success formats beyond HTML and JSON
      # @param format [Object] The format object from respond_to
      # @param custom_formats [Hash] Custom format handlers
      # @param resource [Object] The resource being operated on
      # @param notice [String] Success message
      # @param status [Symbol] HTTP status code
      # @return [void]
      def handle_custom_success_formats(format, custom_formats, resource, notice, status)
        custom_formats.each do |format_name, handler|
          next if [:html, :json, :error_html, :error_json].include?(format_name)

          if format.respond_to?(format_name)
            format.public_send(format_name) { handler.call }
          end
        end
      end

      # Handles custom error formats beyond HTML and JSON
      # @param format [Object] The format object from respond_to
      # @param custom_formats [Hash] Custom format handlers
      # @param resource [Object] The resource being operated on
      # @param on_error_render [Symbol] Template to render for errors
      # @return [void]
      def handle_custom_error_formats(format, custom_formats, resource, on_error_render)
        custom_formats.each do |format_name, handler|
          next unless format_name.to_s.start_with?("error_")
          next if [:error_html, :error_json].include?(format_name)

          base_format = format_name.to_s.gsub(/^error_/, "").to_sym
          if format.respond_to?(base_format)
            format.public_send(base_format) { handler.call }
          end
        end
      end

      # Extracts errors from a resource object
      # @param resource [Object] The resource to extract errors from
      # @return [Hash, Object] Error information suitable for JSON response
      def extract_errors(resource)
        if resource.respond_to?(:errors)
          resource.errors
        else
          { error: "An error occurred" }
        end
      end

      # Validates parameters passed to format_response
      # @param resource [Object] The resource being operated on
      # @param notice [String] Success message
      # @param status [Symbol] HTTP status code
      # @param on_error_render [Symbol] Template to render on error
      # @param block [Proc] The block to execute
      # @raise [ParameterError] If parameters are invalid
      # @return [void]
      def validate_format_response_params!(resource, notice, status, on_error_render, block)
        unless resource
          raise ParameterError, "Resource cannot be nil"
        end

        unless notice.is_a?(String)
          raise ParameterError, "Notice must be a string, got #{notice.class}"
        end

        unless status.is_a?(Symbol)
          raise ParameterError, "Status must be a symbol, got #{status.class}"
        end

        unless on_error_render.is_a?(Symbol)
          raise ParameterError, "on_error_render must be a symbol, got #{on_error_render.class}"
        end

        unless block_given?
          raise ParameterError, "Block is required for format_response"
        end
      end

      # Handles errors that occur during response formatting
      # @param error [StandardError] The error that occurred
      # @param resource [Object] The resource being operated on
      # @return [void]
      def handle_format_response_error(error, resource)
        if defined?(Rails) && Rails.logger
          Rails.logger.error "Error in format_response: #{error.message}"
          Rails.logger.error error.backtrace.join("\n")
        end

        # Re-raise the error for now, but this could be customized
        # to provide fallback responses
        raise error
      end
    end
  end
end