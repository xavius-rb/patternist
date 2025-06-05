# frozen_string_literal: true

require "patternist/controllers/serialization"

RSpec.describe Patternist::Controllers::Serialization do
  let(:dummy_controller_class) do
    Class.new do
      include Patternist::Controllers::Serialization

      def pagination_meta(collection)
        if collection.respond_to?(:current_page)
          { current_page: 1, total_pages: 5, total_count: 100 }
        else
          {}
        end
      end
    end
  end

  let(:dummy_controller) { dummy_controller_class.new }
  let(:resource) { double("post", title: "Test Post", body: "Test Body") }
  let(:collection) { [resource, double("post", title: "Post 2")] }

  describe "#serialize_resource" do
    context "when resource_serializer is defined" do
      let(:serializer_class) do
        Class.new do
          def initialize(resource, **options)
            @resource = resource
            @options = options
          end

          def serializable_hash
            { data: @resource.title, options: @options }
          end
        end
      end

      before do
        allow(dummy_controller).to receive(:resource_serializer).and_return(serializer_class)
      end

      it "uses the resource serializer" do
        result = dummy_controller.serialize_resource(resource, include: [:author])
        expect(result).to eq({ data: "Test Post", options: { include: [:author] } })
      end
    end

    context "when resource_serializer is a callable" do
      let(:serializer_proc) do
        ->(resource, **options) { { title: resource.title, **options } }
      end

      before do
        allow(dummy_controller).to receive(:resource_serializer).and_return(serializer_proc)
      end

      it "calls the serializer proc" do
        result = dummy_controller.serialize_resource(resource, meta: "test")
        expect(result).to eq({ title: "Test Post", meta: "test" })
      end
    end

    context "when no serializer is defined" do
      before do
        allow(dummy_controller).to receive(:resource_serializer).and_return(nil)
        allow(resource).to receive(:as_json).and_return({ title: "Test Post" })
      end

      it "falls back to as_json" do
        result = dummy_controller.serialize_resource(resource)
        expect(result).to eq({ title: "Test Post" })
      end
    end

    context "when serializer raises an error" do
      let(:failing_serializer) do
        Class.new do
          def initialize(resource, **options)
            raise StandardError, "Serialization failed"
          end
        end
      end

      before do
        allow(dummy_controller).to receive(:resource_serializer).and_return(failing_serializer)
        allow(resource).to receive(:as_json).and_return({ title: "Fallback" })
      end

      it "falls back to default serialization" do
        result = dummy_controller.serialize_resource(resource)
        expect(result).to eq({ title: "Fallback" })
      end
    end
  end

  describe "#serialize_collection" do
    context "when collection_serializer is defined" do
      let(:collection_serializer) do
        Class.new do
          def initialize(collection, **options)
            @collection = collection
          end

          def serializable_hash
            { data: @collection.map(&:title) }
          end
        end
      end

      before do
        allow(dummy_controller).to receive(:collection_serializer).and_return(collection_serializer)
      end

      it "uses the collection serializer" do
        result = dummy_controller.serialize_collection(collection)
        expect(result).to eq({ data: ["Test Post", "Post 2"] })
      end
    end

    context "when only resource_serializer is defined" do
      let(:resource_serializer) do
        Class.new do
          def initialize(collection, **options)
            @collection = collection
          end

          def serializable_hash
            @collection.map { |item| { title: item.title } }
          end
        end
      end

      before do
        allow(dummy_controller).to receive(:collection_serializer).and_return(nil)
        allow(dummy_controller).to receive(:resource_serializer).and_return(resource_serializer)
      end

      it "uses the resource serializer for collections" do
        result = dummy_controller.serialize_collection(collection)
        expect(result).to eq([{ title: "Test Post" }, { title: "Post 2" }])
      end
    end
  end

  describe "#serialize_errors" do
    let(:errors) { double("errors", full_messages: ["Title can't be blank", "Body is too short"]) }

    context "when error_serializer is defined" do
      let(:error_serializer) do
        Class.new do
          def initialize(errors, **options)
            @errors = errors
          end

          def serializable_hash
            { errors: @errors.full_messages.map { |msg| { message: msg } } }
          end
        end
      end

      before do
        allow(dummy_controller).to receive(:error_serializer).and_return(error_serializer)
      end

      it "uses the error serializer" do
        result = dummy_controller.serialize_errors(errors)
        expected = { errors: [{ message: "Title can't be blank" }, { message: "Body is too short" }] }
        expect(result).to eq(expected)
      end
    end

    context "when no error serializer is defined" do
      before do
        allow(dummy_controller).to receive(:error_serializer).and_return(nil)
      end

      it "falls back to full_messages" do
        result = dummy_controller.serialize_errors(errors)
        expect(result).to eq({ errors: ["Title can't be blank", "Body is too short"] })
      end

      it "handles errors with messages method" do
        errors_with_messages = double("errors", messages: { title: ["can't be blank"] })
        allow(errors_with_messages).to receive(:respond_to?).with(:full_messages).and_return(false)
        allow(errors_with_messages).to receive(:respond_to?).with(:messages).and_return(true)

        result = dummy_controller.serialize_errors(errors_with_messages)
        expect(result).to eq({ errors: { title: ["can't be blank"] } })
      end
    end
  end

  describe "#add_pagination_meta" do
    let(:paginated_collection) { double("collection", current_page: 1) }

    before do
      allow(dummy_controller).to receive(:pagination_meta).with(paginated_collection)
                                   .and_return({ current_page: 1, total_pages: 5 })
    end

    it "adds pagination metadata to hash data" do
      data = { posts: collection }
      result = dummy_controller.add_pagination_meta(paginated_collection, data)
      expected = {
        posts: collection,
        meta: { pagination: { current_page: 1, total_pages: 5 } }
      }
      expect(result).to eq(expected)
    end

    it "wraps array data with pagination metadata" do
      result = dummy_controller.add_pagination_meta(paginated_collection, collection)
      expected = {
        data: collection,
        meta: { pagination: { current_page: 1, total_pages: 5 } }
      }
      expect(result).to eq(expected)
    end

    it "returns original data when no pagination metadata" do
      allow(dummy_controller).to receive(:pagination_meta).and_return({})

      result = dummy_controller.add_pagination_meta(collection, collection)
      expect(result).to eq(collection)
    end
  end

  describe "serializer configuration methods" do
    describe "#resource_serializer" do
      it "returns nil by default" do
        expect(dummy_controller.send(:resource_serializer)).to be_nil
      end
    end

    describe "#collection_serializer" do
      it "returns nil by default" do
        expect(dummy_controller.send(:collection_serializer)).to be_nil
      end
    end

    describe "#error_serializer" do
      it "returns nil by default" do
        expect(dummy_controller.send(:error_serializer)).to be_nil
      end
    end
  end

  describe "fallback serialization" do
    describe "#serialize_fallback" do
      it "uses as_json when available" do
        object = double("object", as_json: { test: "data" })
        result = dummy_controller.send(:serialize_fallback, object)
        expect(result).to eq({ test: "data" })
      end

      it "uses to_h when as_json is not available" do
        object = double("object", to_h: { test: "data" })
        allow(object).to receive(:respond_to?).with(:as_json).and_return(false)
        allow(object).to receive(:respond_to?).with(:to_h).and_return(true)

        result = dummy_controller.send(:serialize_fallback, object)
        expect(result).to eq({ test: "data" })
      end

      it "returns object as-is when neither method is available" do
        object = "simple string"
        result = dummy_controller.send(:serialize_fallback, object)
        expect(result).to eq("simple string")
      end
    end
  end
end
