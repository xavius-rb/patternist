# frozen_string_literal: true

require "active_support/core_ext/string/inflections"
require_relative "parameter_handling"

module Patternist
  module Controllers
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
    #     include Patternist::Controllers::Helpers
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
    #     include Patternist::Controllers::Helpers
    #
    #     def self.resource_class
    #       Post # Override automatic inference
    #     end
    #   end
    module Helpers
      def self.included(base)
        base.extend ClassMethods
        base.include ParameterHandling
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
        @resource_class_name ||= begin
          if resource_class.respond_to?(:model_name) && resource_class.model_name.respond_to?(:human)
            resource_class.model_name.human
          else
            resource_class.name
          end
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

      # Returns the instance variable name for a given resource name
      # @param name [String] The resource name
      # @return [String] The instance variable name (e.g., "@post")
      # @example
      #   instance_variable_name("post") #=> "@post"
      #   instance_variable_name("posts") #=> "@posts"
      def instance_variable_name(name)
        "@#{name}"
      end

      # Returns the current resource instance from the instance variable
      # @return [Object, nil] The current resource instance
      # @example
      #   # After calling show action
      #   resource #=> #<Post:0x123456789>
      def resource
        instance_variable_get(instance_variable_name(resource_name))
      end

      # Sets the resource instance variable
      # @param value [Object] The resource instance to set
      # @return [Object] The set value
      # @example
      #   set_resource(Post.find(1))
      def set_resource_instance(value)
        instance_variable_set(instance_variable_name(resource_name), value)
      end

      # Sets the collection instance variable
      # @param value [Object] The collection to set
      # @return [Object] The set value
      # @example
      #   set_collection(Post.all)
      def set_collection_instance(value)
        instance_variable_set(instance_variable_name(collection_name), value)
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
          @resource_name ||= resource_class.name.underscore.split("/").last
        end

        private

        # Infers the resource class from the controller name
        # @return [Class] The inferred resource class
        # @raise [NameError] If the resource class cannot be inferred
        def infer_resource_class
          controller_name = name.gsub(/Controller$/, "").split("::").last

          return Object.const_get(controller_name.singularize) if controller_name

          raise NameError,
                "Could not infer resource class for #{name}. " \
                "Please define `self.resource_class` in your controller."
        rescue ::NameError => e
          raise NameError,
                "Could not infer resource class for #{name}: #{e.message}. " \
                "Please define `self.resource_class` in your controller."
        end
      end
    end
  end
end
