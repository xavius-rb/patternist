# frozen_string_literal: true

require 'active_support/core_ext/string/inflections'

module Patternist
  module Controllers
    module ActionPack
      # Provides helper methods for controller resource handling and naming conventions.
      # This module is designed to be included in controllers to provide standard
      # resource naming and parameter handling functionality.
      #
      # The module automatically infers resource classes and names based on controller
      # naming conventions, following Rails patterns. It provides caching for expensive
      # operations and comprehensive error handling.
      #
      # @example Basic usage
      #   class PostsController
      #     include Patternist::Controllers::ActionPack::Helpers
      #
      #     def index
      #       @posts = collection
      #     end
      #
      #     def show
      #       @post = resource
      #     end
      #   end
      #
      # @example Custom resource class
      #   class AdminPostsController
      #     include Patternist::Controllers::ActionPack::Helpers
      #
      #     def self.resource_class
      #       Post # Override automatic inference
      #     end
      #   end
      module Helpers
        def self.included(base)
          base.extend ClassMethods
        end

        # Returns the resource class inferred from the controller name
        # Results are cached for performance
        # @return [Class] The resource class
        # @raise [NameError] If the resource class cannot be inferred
        # @example
        #   # In PostsController
        #   resource_class #=> Post
        def resource_class
          @resource_class ||= self.class.resource_class
        end

        # Returns the underscored name of the resource
        # Results are cached for performance
        # @return [String] The underscored resource name
        # @example
        #   # In PostsController
        #   resource_name #=> "post"
        def resource_name
          @resource_name ||= self.class.resource_name
        end

        # Returns the human-readable name of the resource class
        # Uses the model's human name if available, falls back to class name
        # @return [String] The human-readable resource name
        # @example
        #   resource_class_name #=> "Post"
        def resource_class_name
          @resource_class_name ||= if model_name_human?
                                     resource_class.model_name.human
                                   else
                                     resource_class.name
                                   end
        end

        # Returns the pluralized name of the resource
        # Results are cached for performance
        # @return [String] The pluralized resource name
        # @example
        #   # In PostsController
        #   collection_name #=> "posts"
        def collection_name
          @collection_name ||= resource_name.pluralize
        end

        # Returns the current resource instance from the instance variable
        # @return [Object, nil] The current resource instance
        # @example
        #   # After calling show action
        #   resource #=> #<Post:0x123456789>
        def resource
          instance_variable_get(instance_variable_name(resource_name))
        end

        # @return [Object, nil] The ID parameter from the request
        def id_param
          params.fetch(params_id_key)
        rescue KeyError
          nil
        end

        # @return [Symbol] The key used for ID parameters in requests
        def params_id_key
          :id
        end

        # Handles response formatting based on the success of the given block
        # @param resource [Object] The resource being operated on
        # @param notice [String] The success message
        # @param status [Symbol] The HTTP status code for success
        # @param on_error_render [Symbol] The template to render on error
        # @yield The block that determines success/failure
        def respond_when(resource, notice:, status:, on_error_render:, &block)
          respond_to do |format|
            if block.call
              format.html { redirect_to resource, notice: notice }
              format.json { render :show, status: status, location: resource }
            else
              format.html { render on_error_render, status: :unprocessable_entity }
              format.json { render json: resource.errors, status: :unprocessable_entity }
            end
          end
        end

        # Sets the collection instance variable
        # @param value [Object] The collection to set
        # @return [Object] The set value
        # @example
        #   collection_instance = Post.all
        def collection_instance=(value)
          instance_variable_set(instance_variable_name(collection_name), value)
        end

        # Sets the resource instance variable
        # @param value [Object] The resource instance to set
        # @return [Object] The set value
        # @example
        #   resource_instance = Post.find(1)
        def resource_instance=(value)
          instance_variable_set(instance_variable_name(resource_name), value)
        end

        private

        def model_name_human?
          resource_class.respond_to?(:model_name) && resource_class.model_name.respond_to?(:human)
        end

        def instance_variable_name(name)
          "@#{name}"
        end

        # Class methods automatically added to the including class
        module ClassMethods
          # Infers the resource class from the controller name
          # Results are cached for performance
          # @return [Class] The inferred resource class
          # @raise [NameError] If the resource class cannot be inferred
          # @example
          #   # For PostsController
          #   PostsController.resource_class #=> Post
          #
          # @example Custom namespace handling
          #   # For Admin::PostsController
          #   Admin::PostsController.resource_class #=> Post
          def resource_class
            @resource_class ||= infer_resource_class
          end

          # Returns the underscored name of the resource class
          # Results are cached for performance
          # @return [String] The underscored resource name
          # @example
          #   PostsController.resource_name #=> "post"
          def resource_name
            @resource_name ||= resource_class.name.underscore
          end

          private

          # Infers the resource class from the controller name
          # @return [Class] The inferred resource class
          # @raise [NameError] If the resource class cannot be inferred
          def infer_resource_class
            controller_name = name.gsub(/Controller$/, '').split('::').last

            return Object.const_get(controller_name.singularize) if controller_name

            raise NameError,
                  "Could not infer resource class for #{name}. " \
                  'Please define `self.resource_class` in your controller.'
          rescue ::NameError => e
            raise NameError,
                  "Could not infer resource class for #{name}: #{e.message}. " \
                  'Please define `self.resource_class` in your controller.'
          end
        end
      end
    end
  end
end
