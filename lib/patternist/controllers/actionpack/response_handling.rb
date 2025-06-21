# frozen_string_literal: true

module Patternist
  module Controllers
    module ActionPack
      # Handles HTTP and JSON response formatting for controllers
      #
      # This module provides consistent response patterns across controllers,
      # supporting both HTML and JSON formats with customizable handlers.
      # It follows Rails conventions for response handling while providing
      # flexibility for custom formatting.
      #
      # @example Basic usage
      #   class PostsController
      #     include Patternist::Controllers::ActionPack::ResponseHandling
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
          respond_to do |format|
            if block.call
              handle_success(format, resource, notice, status, formats)
            else
              handle_error(format, resource, on_error_render, formats)
            end
          end
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
          handle_format(format, custom_formats, :html, -> { redirect_to resource, notice: notice })
          handle_format(format, custom_formats, :json, -> { render :show, status: status, location: resource })
        end

        # Handles error responses for different formats
        # @param format [Object] The format object from respond_to
        # @param resource [Object] The resource being operated on
        # @param on_error_render [Symbol] Template to render for HTML errors
        # @param custom_formats [Hash] Custom format handlers
        # @return [void]
        def handle_error(format, resource, on_error_render, custom_formats)
          handle_format(format, custom_formats, :error_html, lambda {
            render on_error_render, status: :unprocessable_entity
          }, :html)
          handle_format(format, custom_formats, :error_json, lambda {
            render json: resource.errors, status: :unprocessable_entity
          }, :json)
        end

        def handle_format(format, custom_formats, key, default_proc, format_key = key)
          format.public_send(format_key) do
            (custom_formats[key] || default_proc).call
          end
        end
      end
    end
  end
end
