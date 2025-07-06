# frozen_string_literal: true

module Patternist
  module Controllers
    module ActionPack
      # Handles HTTP and JSON response formatting for controllers.
      # Provides consistent response patterns across controllers with customizable handlers.
      module ResponseHandling
        HTML_FORMAT   = :html
        JSON_FORMAT   = :json

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
        def handle_success(format, resource, notice, status, custom_formats)
          # TODO: DEPRECATE custom_formats?
          dispatch_response(format, HTML_FORMAT, html_success(resource, notice: notice), custom_formats)
          dispatch_response(format, JSON_FORMAT, json_success(resource, status: status), custom_formats)
        end

        # Handles error responses for different formats
        def handle_error(format, resource, on_error_render, custom_formats)
          dispatch_response(format, HTML_FORMAT, html_error(on_error_render), custom_formats, :on_error_html)
          dispatch_response(format, JSON_FORMAT, json_error(resource), custom_formats, :on_error_json)
        end

        def html_success(location, notice:)
          proc { redirect_to location, notice: notice }
        end

        def json_success(location, status:)
          proc { render :show, status: status, location: location }
        end

        def html_error(on_error_render, status: :unprocessable_entity)
          proc { render on_error_render, status: status }
        end

        def json_error(resource, status: :unprocessable_entity)
          proc { render json: resource.errors, status: status }
        end

        def dispatch_response(format, format_method, default_proc, custom_procs, format_key = format_method)
          format.public_send(format_method) do
            (custom_procs[format_key] || default_proc).call
          end
        end
      end
    end
  end
end
