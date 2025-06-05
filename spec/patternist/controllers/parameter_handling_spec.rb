# frozen_string_literal: true

require "patternist/controllers/parameter_handling"

RSpec.describe Patternist::Controllers::ParameterHandling do
  let(:dummy_controller_class) do
    Class.new do
      include Patternist::Controllers::ParameterHandling

      attr_accessor :params

      def initialize
        @params = {}
      end

      def collection_name
        "posts"
      end
    end
  end

  let(:dummy_controller) { dummy_controller_class.new }

  describe "#id_param" do
    it "fetches the ID param from params" do
      dummy_controller.params[:id] = 123
      expect(dummy_controller.id_param).to eq(123)
    end

    it "returns nil if the ID param is not found" do
      expect(dummy_controller.id_param).to be_nil
    end

    it "validates numeric IDs" do
      dummy_controller.params[:id] = "123"
      expect { dummy_controller.id_param }.not_to raise_error
      expect(dummy_controller.id_param).to eq("123")
    end

    it "raises ParameterError for invalid IDs" do
      dummy_controller.params[:id] = "invalid-id"
      expect { dummy_controller.id_param }.to raise_error(Patternist::ParameterError, /Invalid ID parameter/)
    end

    it "allows nil IDs without validation" do
      dummy_controller.params[:id] = nil
      expect(dummy_controller.id_param).to be_nil
    end
  end

  describe "#params_id_key" do
    it "returns :id by default" do
      expect(dummy_controller.params_id_key).to eq(:id)
    end
  end

  describe "#validate_id_param" do
    it "accepts numeric strings" do
      expect { dummy_controller.send(:validate_id_param, "123") }.not_to raise_error
    end

    it "rejects non-numeric strings" do
      expect { dummy_controller.send(:validate_id_param, "abc") }.to raise_error(Patternist::ParameterError)
    end

    it "accepts integers" do
      expect { dummy_controller.send(:validate_id_param, 123) }.not_to raise_error
    end
  end

  describe "#resource_params" do
    it "raises NotImplementedError when not defined" do
      expect { dummy_controller.resource_params }.to raise_error(Patternist::NotImplementedError)
    end
  end

  describe "#bulk_params" do
    context "when bulk data is present" do
      before do
        dummy_controller.params[:posts] = [
          { title: "Post 1", body: "Body 1" },
          { title: "Post 2", body: "Body 2" }
        ]
      end

      it "returns array of parameter hashes" do
        allow(dummy_controller).to receive(:permit_bulk_item_params) { |params| params }
        result = dummy_controller.bulk_params
        expect(result).to be_an(Array)
        expect(result.size).to eq(2)
      end
    end

    context "when bulk data is not an array" do
      before do
        dummy_controller.params[:posts] = { title: "Single post" }
      end

      it "raises ParameterError" do
        expect { dummy_controller.bulk_params }.to raise_error(Patternist::ParameterError, /Expected array/)
      end
    end

    context "when bulk data is missing" do
      it "returns empty array" do
        result = dummy_controller.bulk_params
        expect(result).to eq([])
      end
    end

    context "with custom collection key" do
      before do
        dummy_controller.params[:articles] = [{ title: "Article 1" }]
      end

      it "uses the custom key" do
        allow(dummy_controller).to receive(:permit_bulk_item_params) { |params| params }
        result = dummy_controller.bulk_params(:articles)
        expect(result.size).to eq(1)
      end
    end
  end

  describe "#permit_bulk_item_params" do
    it "calls resource_params_from by default" do
      params = { title: "Test" }
      expect(dummy_controller).to receive(:resource_params_from).with(params)
      dummy_controller.send(:permit_bulk_item_params, params)
    end
  end

  describe "#resource_params_from" do
    it "converts parameters to hash" do
      params = double("params", to_h: { title: "Test", body: "Body" })
      result = dummy_controller.send(:resource_params_from, params)
      expect(result).to eq({ title: "Test", body: "Body" })
    end
  end
end
