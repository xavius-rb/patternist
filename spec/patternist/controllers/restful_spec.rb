# frozen_string_literal: true

require "patternist/controllers/restful"
require "ostruct"

RSpec.describe Patternist::Controllers::Restful do
  let(:dummy_controller_class) do
    Class.new do
      include Patternist::Controllers::Restful

      attr_accessor :params

      def initialize
        @params = {}
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
      attr_accessor :title, :body

      def self.all
        %w[post1 post2 post3]
      end

      def self.find(id)
        id == 1 ? new : nil
      end

      def initialize(attrs = {})
        @title = attrs[:title]
        @body = attrs[:body]
      end

      def self.name
        "Post"
      end

      def self.model_name
        OpenStruct.new(human: "Post")
      end

      def save
        true
      end

      def update(attrs)
        @title = attrs[:title]
        @body = attrs[:body]
        true
      end

      def destroy
        true
      end

      def errors
        { error: "Invalid" }
      end
    end)
  end

  before do
    allow(dummy_controller_class).to receive(:resource_class).and_return(Post)
    # allow(dummy_controller_class).to receive(:resource_name).and_return("post")
  end

  describe "#index" do
    it "sets the instance variable for the collection" do
      aggregate_failures do
        expect(dummy_controller.instance_variable_get(:@posts)).to be_nil
        dummy_controller.index
        expect(dummy_controller.instance_variable_get(:@posts)).to eq(%w[post1 post2 post3])
        expect(dummy_controller.instance_variable_get("@posts")).to eq(Post.all)
      end
    end
  end

  describe "#show" do
    before do
      allow(Post).to receive(:find).and_call_original
      dummy_controller.params = { id: 1 }
    end

    it "sets the instance variable for the resource" do
      aggregate_failures do
        expect(dummy_controller.instance_variable_get("@post")).to be_nil
        dummy_controller.show
        expect(Post).to have_received(:find).with(1)
        expect(dummy_controller.instance_variable_get("@post")).to be_a(Post)
      end
    end
  end

  describe "#edit" do
    before do
      allow(Post).to receive(:find).and_call_original
      dummy_controller.params = { id: 1 }
    end

    it "sets the instance variable for the resource" do
      aggregate_failures do
        expect(dummy_controller.instance_variable_get("@post")).to be_nil
        dummy_controller.edit
        expect(Post).to have_received(:find).with(1)
        expect(dummy_controller.instance_variable_get("@post")).to be_a(Post)
      end
    end
  end

  describe "#new" do
    before do
      allow(Post).to receive(:new).and_call_original
    end

    it "sets a new instance of the resource" do
      aggregate_failures do
        expect(dummy_controller.instance_variable_get("@post")).to be_nil
        dummy_controller.new
        expect(Post).to have_received(:new).with(no_args)
        expect(dummy_controller.instance_variable_get("@post")).to be_a(Post)
      end
    end
  end

  describe "#create" do
    context "when controller defines resource_params" do
      before do
        dummy_controller.define_singleton_method(:resource_params) do
          { title: "New Post", body: "Body" }
        end

        allow(dummy_controller).to receive(:redirect_to).and_return(true)
        allow(dummy_controller).to receive(:render).and_return(true)
        allow_any_instance_of(Post).to receive(:save).and_return(true)
        allow(Post).to receive(:new).and_call_original
      end

      it "creates a new resource and responds with success" do
        aggregate_failures do
          expect(dummy_controller).to receive(:respond_to).and_call_original
          expect(dummy_controller.instance_variable_get("@post")).to be_nil
          dummy_controller.create
          expect(dummy_controller.instance_variable_get("@post")).to be_a(Post)
          expect(Post).to have_received(:new).with(title: "New Post", body: "Body")
          expect(dummy_controller).to have_received(:render).with(:show, status: :created,
                                                                         location: an_instance_of(Post))
        end
      end

      it "renders error response when save fails" do
        aggregate_failures do
          allow_any_instance_of(Post).to receive(:save).and_return(false)
          expect(dummy_controller).to receive(:respond_to).and_call_original
          dummy_controller.create
          expect(dummy_controller).to have_received(:render).with(:new, status: :unprocessable_entity)
        end
      end
    end

    context "when controller does not define resource_params" do
      it "raises NotImplementedError" do
        expect { dummy_controller.create }.to raise_error(Patternist::NotImplementedError)
      end
    end
  end

  describe "#update" do
    context "when controller defines resource_params" do
      before do
        dummy_controller.define_singleton_method(:resource_params) do
          { title: "New Post", body: "Body" }
        end

        allow(dummy_controller).to receive(:redirect_to).and_return(true)
        allow(dummy_controller).to receive(:render).and_return(true)
        allow_any_instance_of(Post).to receive(:update).and_return(true)
        allow(Post).to receive(:find).and_call_original
      end

      it "updates the resource and responds with success" do
        aggregate_failures do
          dummy_controller.params = { id: 1, title: "Updated" }
          expect(dummy_controller).to receive(:respond_to).and_call_original
          dummy_controller.update
          expect(Post).to have_received(:find).with(1)
          expect(dummy_controller).to have_received(:render).with(:show, status: :ok, location: an_instance_of(Post))
        end
      end

      it "renders error response when update fails" do
        aggregate_failures do
          allow_any_instance_of(Post).to receive(:update).and_return(false)
          expect(dummy_controller).to receive(:respond_to).and_call_original
          dummy_controller.update
          expect(dummy_controller).to have_received(:render).with(:edit, status: :unprocessable_entity)
        end
      end
    end

    context "when controller does not define resource_params" do
      it "raises NotImplementedError" do
        expect { dummy_controller.update }.to raise_error(Patternist::NotImplementedError)
      end
    end
  end

  describe "#destroy" do
    before do
      allow(dummy_controller).to receive(:redirect_to).and_return(true)
      allow(dummy_controller).to receive(:render).and_return(true)
      allow(dummy_controller).to receive(:head).and_return(true)
    end

    it "destroys the resource and responds with success" do
      dummy_controller.params = { id: 1 }
      expect(dummy_controller).to receive(:respond_to).and_call_original
      dummy_controller.destroy
    end
  end

  describe "#resource_params" do
    it "raises NotImplementedError when not defined" do
      expect { dummy_controller.send(:resource_params) }.to raise_error(Patternist::NotImplementedError)
    end
  end

  describe "#collection" do
    it "returns all resources" do
      expect(dummy_controller.send(:collection)).to eq(%w[post1 post2 post3])
    end
  end
end
