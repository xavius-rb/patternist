# frozen_string_literal: true

require_relative 'helpers'
require_relative 'response_handling'

module Patternist
  module Controllers
    module ActionPack
      # Provides RESTful CRUD actions for controllers.
      # Requires implementing `resource_params` for strong parameter handling.
      module Restful
        def self.included(base)
          base.include Helpers
          base.include ResponseHandling
          base.include InstanceMethods
        end

        # Instance methods implementing RESTful actions
        module InstanceMethods
          # Lists all resources
          def index = self.collection_instance = collection

          # Shows a single resource
          def show
            self.resource_instance = find_resource
            yield if block_given?
          end

          # Prepares a resource for editing
          def edit
            self.resource_instance = find_resource
            yield if block_given?
          end

          # Initializes a new resource
          def new
            self.resource_instance = resource_class.new
            yield if block_given?
          end

          # Creates a new resource
          def create
            self.resource_instance = resource_class.new(resource_params)

            format_response(resource,
                            notice: "#{resource_class_name} was successfully created.",
                            status: :created,
                            on_error_render: :new) do
              create_resource
            end
          end

          # Updates an existing resource
          def update
            self.resource_instance = find_resource

            format_response(resource,
                            notice: "#{resource_class_name} was successfully updated.",
                            status: :ok,
                            on_error_render: :edit) do
              update_resource
            end
          end

          # Destroys an existing resource
          def destroy
            self.resource_instance = find_resource

            notice = "#{resource_class_name} was successfully destroyed."
            format_response(resource,
                            notice: notice,
                            status: :see_other,
                            on_error_render: :show,
                            formats: {
                              html: -> { redirect_to resource_class, notice: notice },
                              json: -> { head :no_content }
                            }) do
              destroy_resource
            end
          end

          protected

          # Override this method to define allowed parameters
          def resource_params
            raise NotImplementedError,
                  'Controller must define `resource_params`. Example: `params.require(:post).permit(:title, :body)`'
          end
        end
      end
    end
  end
end
