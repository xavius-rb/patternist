# frozen_string_literal: true

require "patternist/controllers/helpers"
require "patternist/controllers/response_handling"
require "patternist/controllers/pagination"
require "patternist"

module Patternist
  module Controllers
    # Provides RESTful actions for controllers.
    #
    # This module implements standard CRUD operations following REST conventions.
    # It provides a complete set of RESTful actions (index, show, new, create, edit,
    # update, destroy) with consistent error handling, pagination support, and
    # response formatting.
    #
    # The module requires the including class to implement `resource_params` for
    # strong parameter handling, following Rails conventions.
    #
    # @example Basic usage
    #   class PostsController < ApplicationController
    #     include Patternist::Controllers::Restful
    #
    #     private
    #
    #     def resource_params
    #       params.require(:post).permit(:title, :body, :published)
    #     end
    #   end
    #
    # @example Custom collection handling
    #   class PostsController < ApplicationController
    #     include Patternist::Controllers::Restful
    #
    #     private
    #
    #     def collection
    #       Post.published.includes(:author)
    #     end
    #
    #     def resource_params
    #       params.require(:post).permit(:title, :body)
    #     end
    #   end
    #
    # @example Custom response formats
    #   class API::PostsController < ApplicationController
    #     include Patternist::Controllers::Restful
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
        base.include Pagination
        base.include InstanceMethods
      end

      # Instance methods implementing RESTful actions
      module InstanceMethods
        # Lists all resources with optional pagination
        #
        # Sets the pluralized instance variable (e.g., @posts) with the
        # paginated collection. The collection is obtained from the `collection`
        # method which can be overridden for custom filtering or scoping.
        #
        # @return [void]
        # @raise [StandardError] If collection cannot be retrieved
        #
        # @example Default behavior
        #   # GET /posts
        #   def index
        #     # Automatically sets @posts = paginate(Post.all)
        #   end
        #
        # @example Custom collection
        #   def collection
        #     Post.published.includes(:author, :tags)
        #   end
        def index
          resources = paginate(collection)
          set_collection_instance(resources)
        rescue StandardError => e
          handle_index_error(e)
        end

        # Shows a single resource
        #
        # Sets the singular instance variable (e.g., @post) with the
        # resource found by ID. Uses the `find_resource` method which
        # can be overridden for custom finding logic.
        #
        # @return [void]
        # @raise [ResourceNotFoundError] If resource cannot be found
        #
        # @example Default behavior
        #   # GET /posts/1
        #   def show
        #     # Automatically sets @post = Post.find(params[:id])
        #   end
        def show
          set_resource_from_id
        rescue StandardError => e
          handle_show_error(e)
        end

        # Prepares a resource for editing
        #
        # Sets the singular instance variable (e.g., @post) with the
        # resource found by ID, ready for the edit form.
        #
        # @return [void]
        # @raise [ResourceNotFoundError] If resource cannot be found
        #
        # @example Default behavior
        #   # GET /posts/1/edit
        #   def edit
        #     # Automatically sets @post = Post.find(params[:id])
        #   end
        def edit
          set_resource_from_id
        rescue StandardError => e
          handle_edit_error(e)
        end

        # Initializes a new resource
        #
        # Sets the singular instance variable (e.g., @post) with a new
        # instance of the resource class, ready for the new form.
        #
        # @return [void]
        # @raise [StandardError] If resource cannot be instantiated
        #
        # @example Default behavior
        #   # GET /posts/new
        #   def new
        #     # Automatically sets @post = Post.new
        #   end
        #
        # @example Custom initialization
        #   def new
        #     super
        #     resource.author = current_user
        #   end
        def new
          set_resource_instance(resource_class.new)
        rescue StandardError => e
          handle_new_error(e)
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
        #     set_resource_instance(resource_class.new(resource_params))
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
          validate_resource_params_defined!

          set_resource_instance(resource_class.new(resource_params))

          format_response(resource,
                          notice: "#{resource_class_name} was successfully created.",
                          status: :created,
                          on_error_render: :new) do
            resource.save
          end
        rescue StandardError => e
          handle_create_error(e)
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
          validate_resource_params_defined!

          set_resource_from_id

          format_response(resource,
                          notice: "#{resource_class_name} was successfully updated.",
                          status: :ok,
                          on_error_render: :edit) do
            resource.update(resource_params)
          end
        rescue StandardError => e
          handle_update_error(e)
        end

        # Destroys an existing resource
        #
        # Finds the resource by ID and attempts to destroy it.
        # Provides custom response formats for HTML (redirect to index)
        # and JSON (no content response).
        #
        # @return [void]
        # @raise [ResourceNotFoundError] If resource cannot be found
        #
        # @example Default behavior
        #   # DELETE /posts/1
        #   def destroy
        #     # Automatically finds and destroys post, redirects to index
        #   end
        #
        # @example Custom redirect
        #   def destroy
        #     set_resource_from_id
        #     resource.destroy
        #
        #     format_response(resource,
        #                     notice: "Post deleted",
        #                     status: :see_other,
        #                     on_error_render: :show,
        #                     formats: {
        #                       html: -> { redirect_to custom_posts_path }
        #                     }) { true }
        #   end
        def destroy
          set_resource_from_id
          resource.destroy

          format_response(resource,
                          notice: "#{resource_class_name} was successfully destroyed.",
                          status: :see_other,
                          on_error_render: :show,
                          formats: {
                            html: -> { redirect_to resource_class },
                            json: -> { head :no_content }
                          }) { true }
        rescue StandardError => e
          handle_destroy_error(e)
        end

        protected

        # Override this method to define allowed parameters for the resource
        #
        # This method must be implemented by the including controller to specify
        # which parameters are permitted for create and update operations.
        #
        # @return [ActionController::Parameters, Hash] Permitted parameters for the resource
        # @raise [NotImplementedError] If not implemented in the including class
        #
        # @example Basic implementation
        #   def resource_params
        #     params.require(:post).permit(:title, :body, :published)
        #   end
        #
        # @example With nested attributes
        #   def resource_params
        #     params.require(:post).permit(:title, :body, tag_ids: [],
        #                                  author_attributes: [:name, :email])
        #   end
        def resource_params
          raise NotImplementedError,
                "Controller must define `resource_params`. " \
                "Example: `params.require(:post).permit(:title, :body)`"
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

        # Sets the resource instance variable based on the ID parameter
        #
        # Finds the resource using the `find_resource` method and sets the
        # appropriate instance variable (e.g., @post).
        #
        # @return [void]
        # @raise [ResourceNotFoundError] If resource cannot be found
        def set_resource_from_id
          set_resource_instance(find_resource)
        end

        # Finds a resource by ID
        #
        # Override this method to customize how resources are found.
        # Useful for custom finding logic, soft deletes, or authorization.
        #
        # @return [Object] The found resource
        # @raise [ResourceNotFoundError] If resource cannot be found
        #
        # @example Custom finding with soft deletes
        #   def find_resource
        #     resource_class.with_deleted.find(id_param)
        #   end
        #
        # @example Finding with authorization
        #   def find_resource
        #     current_user.posts.find(id_param)
        #   end
        def find_resource
          resource_class.find(id_param)
        rescue StandardError => e
          raise ResourceNotFoundError, "#{resource_class_name} not found: #{e.message}"
        end

        private

        # Validates that resource_params method is defined
        # @raise [NotImplementedError] If resource_params is not defined
        def validate_resource_params_defined!
          resource_params
        rescue NotImplementedError
          raise
        rescue StandardError => e
          raise NotImplementedError,
                "resource_params method is not properly defined: #{e.message}"
        end

        # Error handlers for each action

        def handle_index_error(error)
          raise error # For now, re-raise. Could be customized for specific error handling
        end

        def handle_show_error(error)
          if error.is_a?(StandardError) && error.message.match?(/not found/i)
            raise ResourceNotFoundError, "#{resource_class_name} not found"
          else
            raise error
          end
        end

        def handle_edit_error(error)
          handle_show_error(error) # Same logic as show
        end

        def handle_new_error(error)
          raise error
        end

        def handle_create_error(error)
          raise error
        end

        def handle_update_error(error)
          handle_show_error(error) if error.message.match?(/not found/i)
          raise error
        end

        def handle_destroy_error(error)
          handle_show_error(error) if error.message.match?(/not found/i)
          raise error
        end
      end
    end
  end
end
