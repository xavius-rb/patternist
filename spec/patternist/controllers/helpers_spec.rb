# frozen_string_literal: true

require "patternist/controllers/helpers"
require "ostruct"

RSpec.describe Patternist::Controllers::Helpers do
  let(:dummy_controller_class) do
    Class.new do
      include Patternist::Controllers::Helpers

      def params
        @params ||= {}
      end

      def respond_to
        yield(format_stub)
      end

      private

      def format_stub
        @format_stub ||= Class.new do
          def html
            yield
          end

          def json
            yield
          end
        end.new
      end
    end
  end

  let(:dummy_controller) { dummy_controller_class.new }

  before do
    stub_const("Post", Class.new do
      def self.name
        "Post"
      end

      def self.model_name
        OpenStruct.new(human: "Post")
      end
    end)
  end

  describe "ClassMethods" do
    before do
      allow(dummy_controller_class).to receive(:name).and_return("PostsController")
    end

    describe ".resource_class" do
      it "infers the resource class from the controller name" do
        expect(dummy_controller_class.resource_class).to eq(Post)
      end

      it "raises a NameError if the resource class cannot be found" do
        allow(dummy_controller_class).to receive(:name).and_return("UnknownController")
        expect { dummy_controller_class.resource_class }.to raise_error(Patternist::NameError)
      end

      it "caches the result" do
        expect(Object).to receive(:const_get).with("Post").once.and_return(Post)
        2.times { dummy_controller_class.resource_class }
      end
    end

    describe ".resource_name" do
      it "returns the underscored name of the resource class" do
        expect(dummy_controller_class.resource_name).to eq("post")
      end

      it "caches the result" do
        allow(dummy_controller_class).to receive(:resource_class).and_return(Post)
        expect(Post).to receive(:name).once.and_return("Post")
        2.times { dummy_controller_class.resource_name }
      end
    end
  end

  describe "InstanceMethods" do
    before do
      allow(dummy_controller_class).to receive(:resource_class).and_return(Post)
      allow(dummy_controller_class).to receive(:resource_name).and_return("post")
    end

    describe "#resource_class" do
      it "returns the class resource_class inferred from the controller" do
        expect(dummy_controller.resource_class).to eq(Post)
      end

      it "caches the result" do
        allow(dummy_controller_class).to receive(:resource_class).and_return(Post)
        expect(dummy_controller_class).to receive(:resource_class).once
        2.times { dummy_controller.resource_class }
      end
    end

    describe "#resource_name" do
      it "returns the underscored name of the resource" do
        expect(dummy_controller.resource_name).to eq("post")
      end

      it "caches the result" do
        allow(dummy_controller_class).to receive(:resource_name).and_return("post")
        expect(dummy_controller_class).to receive(:resource_name).once
        2.times { dummy_controller.resource_name }
      end
    end

    describe "#resource_class_name" do
      it "returns the human-readable name of the resource class" do
        expect(dummy_controller.resource_class_name).to eq("Post")
      end

      it "falls back to class name if model_name is not available" do
        stub_const("SimplePost", Class.new do
          def self.name
            "SimplePost"
          end
        end)
        allow(dummy_controller_class).to receive(:resource_class).and_return(SimplePost)

        expect(dummy_controller.resource_class_name).to eq("SimplePost")
      end

      it "caches the result" do
        expect(Post).to receive(:model_name).once.and_return(OpenStruct.new(human: "Post"))
        2.times { dummy_controller.resource_class_name }
      end
    end

    describe "#collection_name" do
      it "returns the pluralized name of the resource" do
        expect(dummy_controller.collection_name).to eq("posts")
      end

      it "caches the result" do
        allow(dummy_controller).to receive(:resource_name).and_return("post")
        expect(String).to receive(:new).with("post").once.and_return("post")
        expect_any_instance_of(String).to receive(:pluralize).once.and_return("posts")
        2.times { dummy_controller.collection_name }
      end
    end

    describe "#instance_variable_name" do
      it "returns the instance variable name for a given resource" do
        expect(dummy_controller.instance_variable_name("post")).to eq("@post")
      end

      it "works with pluralized names" do
        expect(dummy_controller.instance_variable_name("posts")).to eq("@posts")
      end
    end

    describe "#resource" do
      it "returns the resource from the instance variable" do
        dummy_controller.instance_variable_set(:@post, "dummy resource")
        expect(dummy_controller.resource).to eq("dummy resource")
      end

      it "returns nil when instance variable is not set" do
        expect(dummy_controller.resource).to be_nil
      end
    end

    describe "#set_resource_instance" do
      it "sets the resource instance variable" do
        resource = double("post")
        dummy_controller.set_resource_instance(resource)
        expect(dummy_controller.instance_variable_get(:@post)).to eq(resource)
      end
    end

    describe "#set_collection_instance" do
      it "sets the collection instance variable" do
        collection = double("posts")
        dummy_controller.set_collection_instance(collection)
        expect(dummy_controller.instance_variable_get(:@posts)).to eq(collection)
      end
    end

    describe "#id_param" do
      it "fetches the ID param from params" do
        dummy_controller.params[:id] = 123
        expect(dummy_controller.id_param).to eq(123)
      end

      it "returns nil if the ID param is not found" do
        expect(dummy_controller.id_param).to be_nil
      end

      it "validates the ID parameter" do
        dummy_controller.params[:id] = "invalid"
        expect { dummy_controller.id_param }.to raise_error(Patternist::ParameterError)
      end

      it "allows valid numeric IDs" do
        dummy_controller.params[:id] = "123"
        expect { dummy_controller.id_param }.not_to raise_error
      end
    end

    describe "#params_id_key" do
      it "returns :id by default" do
        expect(dummy_controller.params_id_key).to eq(:id)
      end
    end

    describe "#resource_params" do
      it "raises NotImplementedError when not defined" do
        expect { dummy_controller.resource_params }.to raise_error(Patternist::NotImplementedError)
      end
    end
  end
end
