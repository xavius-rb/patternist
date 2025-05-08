# frozen_string_literal: true

require "patternist/controllers/helpers"
require "patternist/controllers/response_handling"
require "patternist/controllers/pagination"
require "patternist"

module Patternist
  module Controllers
    # Provides RESTful actions for controllers.
    # This module implements standard CRUD operations following REST conventions.
    # It requires the including class to implement `resource_params` for
    # strong parameter handling.
    #
    # @example
    #   class PostsController
    #     include Patternist::Controllers::Restful
    #
    #     private
    #
    #     def resource_params
    #       params.require(:post).permit(:title, :body)
    #     end
    #   end
    module Restful
      def self.included(base)
        base.include Helpers
        base.include ResponseHandling
        base.include Pagination
        base.include InstanceMethods
      end

      # Instance methods implementing RESTful actions
      module InstanceMethods
        # Lists all resources with optional pagination
        # Sets the pluralized instance variable (e.g., @posts)
        # @return [void]
        def index
          resources = paginate(collection)
          instance_variable_set(instance_variable_name(collection_name), resources)
        end

        # Shows a single resource
        # Sets the singular instance variable (e.g., @post)
        # @return [void]
        def show
          set_resource
        end

        # Prepares a resource for editing
        # Sets the singular instance variable (e.g., @post)
        # @return [void]
        def edit
          set_resource
        end

        # Initializes a new resource
        # Sets the singular instance variable (e.g., @post)
        # @return [void]
        def new
          instance_variable_set(instance_variable_name(resource_name), resource_class.new)
        end

        # Creates a new resource
        # @return [void]
        # @raise [NotImplementedError] If resource_params is not defined
        def create
          instance_variable_set(instance_variable_name(resource_name), resource_class.new(resource_params))

          format_response(resource,
                          notice: "#{resource_class_name} was successfully created.",
                          status: :created,
                          on_error_render: :new) do
            resource.save
          end
        end

        # Updates an existing resource
        # @return [void]
        # @raise [NotImplementedError] If resource_params is not defined
        def update
          set_resource

          format_response(resource,
                          notice: "#{resource_class_name} was successfully updated.",
                          status: :ok,
                          on_error_render: :edit) do
            resource.update(resource_params)
          end
        end

        # Destroys an existing resource
        # @return [void]
        def destroy
          set_resource
          resource.destroy

          format_response(resource,
                          notice: "#{resource_class_name} was successfully destroyed.",
                          status: :see_other,
                          on_error_render: :show,
                          formats: {
                            html: -> { redirect_to resource_class },
                            json: -> { head :no_content }
                          }) { true }
        end

        protected

        # Override this method to define allowed parameters
        # @return [ActionController::Parameters] Permitted parameters for the resource
        # @raise [NotImplementedError] If not implemented in the including class
        def resource_params
          raise NotImplementedError,
                "Controller must define `resource_params`. Example: `params.require(:post).permit(:title, :body)`"
        end

        # Returns the collection of all resources
        # Override this method to customize the collection
        # @return [ActiveRecord::Relation] Collection of resources
        def collection
          resource_class.all
        end

        # Sets the resource instance variable based on the ID parameter
        # @return [void]
        def set_resource
          instance_variable_set(instance_variable_name(resource_name), find_resource)
        end

        def find_resource
          resource_class.find(id_param)
        end
      end
    end
  end
end
