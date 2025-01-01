# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module Patternist
  module Controllers
    module Helpers
      def self.included(base)
        base.extend ClassMethods
      end

      def resource_class
        @resource_class ||= self.class.resource_class
      end

      def resource_name
        @resource_name ||= self.class.resource_name
      end

      def resource_class_name
        resource_class.model_name.human
      end

      def collection_name
        resource_name.pluralize
      end

      def instance_variable_name(name)
        "@#{name}"
      end

      def resource
        instance_variable_get(instance_variable_name(resource_name))
      end

      def id_param
        params.fetch(params_id_key)
      rescue KeyError
        nil
      end

      def params_id_key
        :id
      end

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

      module ClassMethods
        def resource_class
          controller_name = name.gsub(/Controller$/, "").split("::").last
          begin
            Object.const_get(controller_name.singularize)
          rescue StandardError
            raise NameError, "Could not infer resource class for #{name}"
          end
        end

        def resource_name
          resource_class.name.underscore
        end
      end
    end
  end
end
