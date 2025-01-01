# frozen_string_literal: true

require "patternist/controllers/helpers"
require "patternist"

module Patternist
  module Controllers
    module Restful
      def self.included(base)
        base.include Helpers
        base.include InstanceMethods
      end

      module InstanceMethods
        def index
          instance_variable_set(instance_variable_name(collection_name), collection)
        end

        def show
          set_resource
        end

        def edit
          set_resource
        end

        def new
          # set_resource
          instance_variable_set(instance_variable_name(resource_name), resource_class.new)
        end

        def create
          instance_variable_set(instance_variable_name(resource_name), resource_class.new(resource_params))

          respond_when(resource,
                       notice: "#{resource_class_name} was successfully created.",
                       status: :created,
                       on_error_render: :new) do
            resource.save
          end
        end

        def update
          set_resource

          respond_when(resource,
                       notice: "#{resource_class_name} was successfully updated.",
                       status: :ok,
                       on_error_render: :edit) do
            resource.update(resource_params)
          end
        end

        def destroy
          set_resource
          resource.destroy

          respond_to do |format|
            format.html do
              redirect_to resource_class, status: :see_other,
                                          notice: "#{resource_class_name} was successfully destroyed."
            end
            format.json { head :no_content }
          end
        end

        protected

        def resource_params
          raise NotImplementedError,
                "Controller must define `resource_params`. Example: `params.require(:post).permit(:title, :body)`"
        end

        def collection
          resource_class.all
        end

        def set_resource
          instance_variable_set(instance_variable_name(resource_name),
                                resource_class.find(id_param) || resource_class.new)
        end
      end
    end
  end
end
