# frozen_string_literal: true

module Patternist
  module Controllers
    # Provides serialization support for API responses
    #
    # This module adds support for custom serializers in controller responses,
    # allowing for consistent API output formatting across different response
    # formats and actions.
    #
    # @example Basic usage
    #   class API::PostsController
    #     include Patternist::Controllers::Serialization
    #
    #     def index
    #       @posts = paginate(Post.all)
    #       render json: serialize_collection(@posts)
    #     end
    #
    #     def show
    #       @post = Post.find(params[:id])
    #       render json: serialize_resource(@post)
    #     end
    #
    #     private
    #
    #     def resource_serializer
    #       PostSerializer
    #     end
    #   end
    #
    # @example Custom serialization options
    #   def show
    #     @post = Post.find(params[:id])
    #     render json: serialize_resource(@post, include: [:author, :tags])
    #   end
    module Serialization
      # Serializes a single resource using the configured serializer
      #
      # @param resource [Object] The resource to serialize
      # @param options [Hash] Additional serialization options
      # @return [Hash, Object] Serialized resource data
      #
      # @example Basic serialization
      #   serialize_resource(@post)
      #
      # @example With custom options
      #   serialize_resource(@post, include: [:author], meta: { version: '1.0' })
      def serialize_resource(resource, **options)
        if resource_serializer
          serialize_with_serializer(resource, resource_serializer, **options)
        else
          serialize_fallback(resource, **options)
        end
      end

      # Serializes a collection of resources using the configured serializer
      #
      # @param collection [Enumerable] The collection to serialize
      # @param options [Hash] Additional serialization options
      # @return [Hash, Array] Serialized collection data
      #
      # @example Basic collection serialization
      #   serialize_collection(@posts)
      #
      # @example With pagination metadata
      #   serialize_collection(@posts, meta: pagination_meta(@posts))
      def serialize_collection(collection, **options)
        if collection_serializer
          serialize_with_serializer(collection, collection_serializer, **options)
        elsif resource_serializer
          serialize_with_serializer(collection, resource_serializer, **options)
        else
          serialize_fallback(collection, **options)
        end
      end

      # Serializes errors for API responses
      #
      # @param errors [Object] Error object (e.g., ActiveModel::Errors)
      # @param options [Hash] Additional serialization options
      # @return [Hash] Serialized error data
      #
      # @example
      #   serialize_errors(@post.errors)
      #   #=> { errors: { title: ["can't be blank"], body: ["is too short"] } }
      def serialize_errors(errors, **options)
        if error_serializer
          serialize_with_serializer(errors, error_serializer, **options)
        else
          serialize_errors_fallback(errors, **options)
        end
      end

      # Adds pagination metadata to serialized response
      #
      # @param collection [Object] Paginated collection
      # @param serialized_data [Hash, Array] Already serialized data
      # @return [Hash] Data with pagination metadata
      #
      # @example
      #   data = serialize_collection(@posts)
      #   add_pagination_meta(@posts, data)
      #   #=> {
      #   #     data: [...],
      #   #     meta: {
      #   #       pagination: { current_page: 1, total_pages: 5, ... }
      #   #     }
      #   #   }
      def add_pagination_meta(collection, serialized_data)
        meta = pagination_meta(collection)
        return serialized_data if meta.empty?

        if serialized_data.is_a?(Hash)
          serialized_data.merge(meta: { pagination: meta })
        else
          { data: serialized_data, meta: { pagination: meta } }
        end
      end

      protected

      # Override this method to specify the serializer for individual resources
      #
      # @return [Class, nil] Serializer class for resources
      # @example
      #   def resource_serializer
      #     PostSerializer
      #   end
      def resource_serializer
        nil
      end

      # Override this method to specify the serializer for collections
      #
      # Falls back to resource_serializer if not specified
      # @return [Class, nil] Serializer class for collections
      # @example
      #   def collection_serializer
      #     PostCollectionSerializer
      #   end
      def collection_serializer
        nil
      end

      # Override this method to specify the serializer for errors
      #
      # @return [Class, nil] Serializer class for errors
      # @example
      #   def error_serializer
      #     ErrorSerializer
      #   end
      def error_serializer
        nil
      end

      private

      # Serializes object using the specified serializer
      # @param object [Object] Object to serialize
      # @param serializer_class [Class] Serializer class to use
      # @param options [Hash] Serialization options
      # @return [Hash, Object] Serialized data
      def serialize_with_serializer(object, serializer_class, **options)
        if serializer_class.respond_to?(:new)
          serializer_class.new(object, **options).serializable_hash
        elsif serializer_class.respond_to?(:call)
          serializer_class.call(object, **options)
        else
          raise ParameterError, "Invalid serializer: #{serializer_class}"
        end
      rescue StandardError => e
        # Log error and fall back to default serialization
        if defined?(Rails) && Rails.logger
          Rails.logger.warn "Serialization failed: #{e.message}, falling back to default"
        end

        serialize_fallback(object, **options)
      end

      # Fallback serialization when no custom serializer is available
      # @param object [Object] Object to serialize
      # @param options [Hash] Serialization options
      # @return [Hash, Object] Serialized data
      def serialize_fallback(object, **options)
        if object.respond_to?(:as_json)
          object.as_json(**options)
        elsif object.respond_to?(:to_h)
          object.to_h
        else
          object
        end
      end

      # Fallback error serialization
      # @param errors [Object] Error object
      # @param options [Hash] Serialization options
      # @return [Hash] Serialized error data
      def serialize_errors_fallback(errors, **options)
        if errors.respond_to?(:full_messages)
          { errors: errors.full_messages }
        elsif errors.respond_to?(:messages)
          { errors: errors.messages }
        elsif errors.respond_to?(:to_h)
          { errors: errors.to_h }
        else
          { errors: [errors.to_s] }
        end
      end
    end
  end
end
