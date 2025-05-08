# frozen_string_literal: true

module Patternist
  module Controllers
    # Handles HTTP and JSON response formatting for controllers
    # This module provides consistent response patterns across controllers
    module ResponseHandling
      # Formats response based on success/failure and request format
      # @param resource [Object] The resource being operated on
      # @param options [Hash] Response options
      # @option options [String] :notice Success message
      # @option options [Symbol] :status HTTP status for success
      # @option options [Symbol] :on_error_render Template to render on error
      # @option options [Hash] :formats Custom format handlers
      # @yield The operation to determine success/failure
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
      end

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
            render json: resource.errors, status: :unprocessable_entity
          end
        end
      end
    end
  end
end