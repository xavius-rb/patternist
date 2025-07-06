# frozen_string_literal: true

require 'active_support/core_ext/string/inflections'

module Patternist
  module Controllers
    module ActionPack
      # Provides helper methods for controller resource handling and naming conventions.
      # Automatically infers resource classes and names based on controller naming.
      module Helpers
        CONTROLLER_SUFFIX = 'Controller'
        NAMESPACE_SEPARATOR = '::'

        def self.included(base)
          base.extend ClassMethods
        end

        def collection = resource_class.all
        def find_resource = resource_class.find(id_param)
        def create_resource = resource.save
        def update_resource = resource.update(resource_params)
        def destroy_resource = resource.destroy
        def resource_class = @resource_class ||= self.class.resource_class
        def resource_name = @resource_name ||= self.class.resource_name
        def resource_class_name = @resource_class_name ||= model_name_human || resource_class.name
        def collection_name = @collection_name ||= resource_name.pluralize
        def resource = instance_variable_get(instance_variable_name(resource_name))
        def id_param = params.fetch(params_id_key, nil)
        def params_id_key = :id

        private

        def model_name_human
          resource_class.respond_to?(:model_name) && resource_class.model_name.human
        end

        def collection_instance=(value)
          instance_variable_set(instance_variable_name(collection_name), value)
        end

        def resource_instance=(value)
          instance_variable_set(instance_variable_name(resource_name), value)
        end

        def instance_variable_name(name)
          :"@#{name}"
        end

        # Class methods automatically added to the including class
        module ClassMethods
          # Infers the resource class from the controller name
          def resource_class
            @resource_class ||= infer_resource_class
          end

          # Returns the underscored name of the resource class
          def resource_name
            @resource_name ||= resource_class.name.underscore
          end

          private

          # Infers the resource class based on the controller name
          def infer_resource_class
            base_name = if name.end_with?(CONTROLLER_SUFFIX)
                          name[0...-CONTROLLER_SUFFIX.length]
                        else
                          name
                        end

            last_separator = base_name.rindex(NAMESPACE_SEPARATOR)
            controller_name = if last_separator
                                base_name[(last_separator + 2)..]
                              else
                                base_name
                              end

            Object.const_get(controller_name.singularize) if controller_name
          rescue NameError => e
            raise NameError, "Could not infer resource class for #{name}: #{e.message}. " \
                             'Please define `self.resource_class` in your controller.'
          rescue StandardError => e
            raise NameError, "An error occurred while inferring resource class for #{name}: #{e.message}."
          end
        end
      end
    end
  end
end
