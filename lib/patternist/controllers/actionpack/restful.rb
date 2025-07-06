# frozen_string_literal: true

require_relative 'helpers'
require_relative 'response_handling'

module Patternist
  module Controllers
    module ActionPack
      # Provides RESTful actions for controllers.
      # This module implements standard CRUD operations following REST conventions.
      # It requires the including class to implement `resource_params` for
      # strong parameter handling.
      #
      # @example
      #   class PostsController
      #     include Patternist::Controllers::ActionPack::Restful
      #
      #     private
      #
      #     def resource_params
      #       params.require(:post).permit(:title, :body)
      #     end
      #   end
      #
      # @example Custom response formats
      #   class API::PostsController < ApplicationController
      #     include Patternist::Controllers::ActionPack::Restful
      #
      #     def create
      #       set_resource_instance(resource_class.new(resource_params))
      #
      #       format_response(resource,
      #                       notice: "Post created",
      #                       status: :created,
      #                       on_error_render: :new,
      #                       formats: {
      #                         json: -> { render json: resource, serializer: PostSerializer }
      #                       }) do
      #         resource.save
      #       end
      #     end
      #   end
      module Restful
        def self.included(base)
          base.include Helpers
          base.include ResponseHandling
          base.include InstanceMethods
        end

        # Instance methods implementing RESTful actions
        module InstanceMethods
          # Lists all resources with optional pagination
          # Sets the pluralized instance variable (e.g., @posts)
          # @return [void]
          def index
            self.collection_instance = collection
          end

          # Shows a single resource
          # Sets the singular instance variable (e.g., @post)
          # @return [void]
          # @yield Optional block for additional logic after resource is found
          # @example With additional logic
          #   def show
          #     super do
          #       @related_items = resource.related_items
          #       @statistics = resource.calculate_stats
          #     end
          #   end
          def show
            self.resource_instance = find_resource
            yield if block_given?
          end

          # Prepares a resource for editing
          # Sets the singular instance variable (e.g., @post)
          # @return [void]
          def edit
            self.resource_instance = find_resource
            yield if block_given?
          end

          # Initializes a new resource
          # Sets the singular instance variable (e.g., @post)
          # @return [void]
          def new
            self.resource_instance = resource_class.new
            yield if block_given?
          end

          # Creates a new resource
          #
          # Creates a new instance with the permitted parameters and attempts
          # to save it. Responds with appropriate success or error handling
          # based on the save result.
          #
          # @return [void]
          # @raise [NotImplementedError] If resource_params is not defined
          # @raise [ValidationError] If resource validation fails
          #
          # @example Default behavior
          #   # POST /posts
          #   def create
          #     # Automatically creates post with params and handles response
          #   end
          #
          # @example Custom success handling
          #   def create
          #     self.resource_instance = resource_class.new(resource_params)
          #
          #     format_response(resource,
          #                     notice: "#{resource_class_name} created successfully!",
          #                     status: :created,
          #                     on_error_render: :new,
          #                     formats: {
          #                       html: -> { redirect_to custom_path(resource) }
          #                     }) do
          #       resource.save
          #     end
          #   end
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
          #
          # Finds the resource by ID and attempts to update it with the
          # permitted parameters. Responds with appropriate success or
          # error handling based on the update result.
          #
          # @return [void]
          # @raise [NotImplementedError] If resource_params is not defined
          # @raise [ResourceNotFoundError] If resource cannot be found
          # @raise [ValidationError] If resource validation fails
          #
          # @example Default behavior
          #   # PATCH /posts/1
          #   def update
          #     # Automatically finds post, updates with params, and handles response
          #   end
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
          # @return [void]
          def destroy
            self.resource_instance = find_resource

            format_response(resource,
                            notice: "#{resource_class_name} was successfully destroyed.",
                            status: :see_other,
                            on_error_render: :show,
                            formats: {
                              html: lambda {
                                redirect_to resource_class, notice: "#{resource_class_name} was successfully destroyed."
                              },
                              json: -> { head :no_content }
                            }) do
              destroy_resource
            end
          end

          protected

          # Override this method to define allowed parameters
          # @return [ActionController::Parameters] Permitted parameters for the resource
          # @raise [NotImplementedError] If not implemented in the including class
          def resource_params
            raise NotImplementedError,
                  'Controller must define `resource_params`. Example: `params.require(:post).permit(:title, :body)`'
          end

          # Returns the collection of all resources
          #
          # Override this method to customize the collection used in the index action.
          # This is useful for applying default scopes, includes, or filtering.
          #
          # @return [ActiveRecord::Relation, Array] Collection of resources
          #
          # @example Custom collection with scoping
          #   def collection
          #     resource_class.published.includes(:author).order(:created_at)
          #   end
          #
          # @example Collection with user-specific filtering
          #   def collection
          #     current_user.posts.includes(:tags)
          #   end
          def collection
            resource_class.all
          end

          def find_resource
            resource_class.find(id_param)
          end

          # Creates the resource instance
          def create_resource
            resource.save
          end

          # Updates the resource instance with the permitted parameters
          def update_resource
            resource.update(resource_params)
          end

          def destroy_resource
            resource.destroy
          end
        end
      end
    end
  end
end
