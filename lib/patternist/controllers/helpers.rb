# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module Patternist
  module Controllers
    # Provides helper methods for controller resource handling and naming conventions.
    # This module is designed to be included in controllers to provide standard
    # resource naming and parameter handling functionality.
    #
    # @example
    #   class PostsController
    #     include Patternist::Controllers::Helpers
    #
    #     def index
    #       @posts = collection
    #     end
    #   end
    module Helpers
      def self.included(base)
        base.extend ClassMethods
      end

      # @return [Class] The resource class inferred from the controller name
      def resource_class
        @resource_class ||= self.class.resource_class
      end

      # @return [String] The underscored name of the resource
      def resource_name
        @resource_name ||= self.class.resource_name
      end

      # @return [String] The human-readable name of the resource class
      def resource_class_name
        resource_class.model_name.human
      end

      # @return [String] The pluralized name of the resource
      def collection_name
        resource_name.pluralize
      end

      # Returns the instance variable name for a given resource name
      # @param name [String] The resource name
      # @return [String] The instance variable name (e.g., "@post")
      def instance_variable_name(name)
        "@#{name}"
      end

      # @return [Object] The current resource instance
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

      # Class methods automatically added to the including class
      module ClassMethods
        # Infers the resource class from the controller name
        # @return [Class] The inferred resource class
        # @raise [NameError] If the resource class cannot be inferred
        def resource_class
          controller_name = name.gsub(/Controller$/, "").split("::").last
          begin
            Object.const_get(controller_name.singularize)
          rescue StandardError
            raise NameError, "Could not infer resource class for #{name}"
          end
        end

        # @return [String] The underscored name of the resource class
        def resource_name
          resource_class.name.underscore
        end
      end
    end
  end
end
