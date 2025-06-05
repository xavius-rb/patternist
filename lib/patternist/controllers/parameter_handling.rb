# frozen_string_literal: true

module Patternist
  module Controllers
    # Handles parameter validation and processing for controllers
    # This module provides consistent parameter handling patterns across controllers
    #
    # @example Including in a controller
    #   class PostsController
    #     include Patternist::Controllers::ParameterHandling
    #
    #     private
    #
    #     def resource_params
    #       params.require(:post).permit(:title, :body)
    #     end
    #   end
    module ParameterHandling
      # @return [Object, nil] The ID parameter from the request
      # @raise [ParameterError] If the ID parameter is invalid
      def id_param
        param_value = params.fetch(params_id_key)
        validate_id_param(param_value) if param_value
        param_value
      rescue KeyError
        nil
      end

      # @return [Symbol] The key used for ID parameters in requests
      # This method can be overridden to customize the ID parameter key
      # @example Using a custom ID key
      #   def params_id_key
      #     :uuid
      #   end
      def params_id_key
        :id
      end

      # Validates the ID parameter
      # @param param_value [Object] The parameter value to validate
      # @raise [ParameterError] If the parameter is invalid
      # @return [void]
      def validate_id_param(param_value)
        return if param_value.to_s.match?(/\A\d+\z/) # Basic numeric validation

        raise ParameterError, "Invalid ID parameter: #{param_value.inspect}"
      end

      # Override this method to define allowed parameters for the resource
      # @return [ActionController::Parameters] Permitted parameters for the resource
      # @raise [NotImplementedError] If not implemented in the including class
      # @example Implementation
      #   def resource_params
      #     params.require(:post).permit(:title, :body, :published)
      #   end
      def resource_params
        raise NotImplementedError,
              "Controller must define `resource_params`. Example: `params.require(:post).permit(:title, :body)`"
      end

      # Extracts and validates parameters for bulk operations
      # @param collection_key [Symbol] The key for the collection in params
      # @return [Array<Hash>] Array of parameter hashes
      # @raise [ParameterError] If bulk parameters are invalid
      def bulk_params(collection_key = nil)
        key = collection_key || collection_name.to_sym
        bulk_data = params.fetch(key, [])

        unless bulk_data.is_a?(Array)
          raise ParameterError, "Expected array for #{key}, got #{bulk_data.class}"
        end

        bulk_data.map { |item_params| permit_bulk_item_params(item_params) }
      rescue KeyError
        []
      end

      private

      # Permits parameters for a single item in bulk operations
      # Override this method to customize bulk parameter handling
      # @param item_params [ActionController::Parameters] Parameters for a single item
      # @return [Hash] Permitted parameters
      def permit_bulk_item_params(item_params)
        # By default, use the same permissions as single resource
        # Controllers can override this for different bulk permissions
        resource_params_from(item_params)
      end

      # Extracts resource parameters from given parameters hash
      # @param source_params [ActionController::Parameters] Source parameters
      # @return [Hash] Permitted parameters
      def resource_params_from(source_params)
        # This is a simplified implementation
        # In a real Rails app, this would use strong parameters
        source_params.to_h
      end
    end
  end
end
