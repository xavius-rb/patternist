# frozen_string_literal: true

require "patternist/controllers/response_handling"

RSpec.describe Patternist::Controllers::ResponseHandling do
  let(:dummy_controller_class) do
    Class.new do
      include Patternist::Controllers::ResponseHandling

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

          def xml
            yield
          end
        end.new
      end
    end
  end

  let(:dummy_controller) { dummy_controller_class.new }
  let(:resource) { double("resource", errors: { error: "Invalid" }) }

  describe "#format_response" do
    context "when operation succeeds" do
      before do
        allow(dummy_controller).to receive(:redirect_to).and_return(true)
        allow(dummy_controller).to receive(:render).and_return(true)
      end

      it "handles successful HTML response" do
        expect(dummy_controller).to receive(:redirect_to).with(resource, notice: "Success")

        dummy_controller.format_response(resource,
                                      notice: "Success",
                                      status: :ok,
                                      on_error_render: :new) { true }
      end

      it "handles successful JSON response" do
        expect(dummy_controller).to receive(:render).with(:show, status: :ok, location: resource)

        dummy_controller.format_response(resource,
                                      notice: "Success",
                                      status: :ok,
                                      on_error_render: :new) { true }
      end

      it "handles custom format handlers" do
        custom_html = -> { "custom html" }
        custom_json = -> { "custom json" }

        expect(custom_html).to receive(:call)
        expect(custom_json).to receive(:call)

        dummy_controller.format_response(resource,
                                      notice: "Success",
                                      status: :ok,
                                      on_error_render: :new,
                                      formats: {
                                        html: custom_html,
                                        json: custom_json
                                      }) { true }
      end

      it "handles custom success formats" do
        custom_xml = -> { "custom xml" }

        expect(custom_xml).to receive(:call)

        dummy_controller.format_response(resource,
                                      notice: "Success",
                                      status: :ok,
                                      on_error_render: :new,
                                      formats: {
                                        xml: custom_xml
                                      }) { true }
      end
    end

    context "when operation fails" do
      before do
        allow(dummy_controller).to receive(:render).and_return(true)
      end

      it "handles error HTML response" do
        expect(dummy_controller).to receive(:render).with(:new, status: :unprocessable_entity)

        dummy_controller.format_response(resource,
                                      notice: "Success",
                                      status: :ok,
                                      on_error_render: :new) { false }
      end

      it "handles error JSON response" do
        expect(dummy_controller).to receive(:render).with(
          json: resource.errors,
          status: :unprocessable_entity
        )

        dummy_controller.format_response(resource,
                                      notice: "Success",
                                      status: :ok,
                                      on_error_render: :new) { false }
      end

      it "handles custom error format handlers" do
        custom_error_html = -> { "custom error html" }
        custom_error_json = -> { "custom error json" }

        expect(custom_error_html).to receive(:call)
        expect(custom_error_json).to receive(:call)

        dummy_controller.format_response(resource,
                                      notice: "Success",
                                      status: :ok,
                                      on_error_render: :new,
                                      formats: {
                                        error_html: custom_error_html,
                                        error_json: custom_error_json
                                      }) { false }
      end

      it "handles custom error formats for additional formats" do
        custom_error_xml = -> { "custom error xml" }

        expect(custom_error_xml).to receive(:call)

        dummy_controller.format_response(resource,
                                      notice: "Success",
                                      status: :ok,
                                      on_error_render: :new,
                                      formats: {
                                        error_xml: custom_error_xml
                                      }) { false }
      end

      it "extracts errors from resource with errors method" do
        expect(dummy_controller.send(:extract_errors, resource)).to eq(resource.errors)
      end

      it "provides fallback error for resources without errors method" do
        simple_resource = double("simple_resource")
        allow(simple_resource).to receive(:respond_to?).with(:errors).and_return(false)

        result = dummy_controller.send(:extract_errors, simple_resource)
        expect(result).to eq({ error: "An error occurred" })
      end
    end

    context "parameter validation" do
      it "validates that resource is not nil" do
        expect {
          dummy_controller.format_response(nil,
                                        notice: "Success",
                                        status: :ok,
                                        on_error_render: :new) { true }
        }.to raise_error(Patternist::ParameterError, "Resource cannot be nil")
      end

      it "validates that notice is a string" do
        expect {
          dummy_controller.format_response(resource,
                                        notice: 123,
                                        status: :ok,
                                        on_error_render: :new) { true }
        }.to raise_error(Patternist::ParameterError, /Notice must be a string/)
      end

      it "validates that status is a symbol" do
        expect {
          dummy_controller.format_response(resource,
                                        notice: "Success",
                                        status: "ok",
                                        on_error_render: :new) { true }
        }.to raise_error(Patternist::ParameterError, /Status must be a symbol/)
      end

      it "validates that on_error_render is a symbol" do
        expect {
          dummy_controller.format_response(resource,
                                        notice: "Success",
                                        status: :ok,
                                        on_error_render: "new") { true }
        }.to raise_error(Patternist::ParameterError, /on_error_render must be a symbol/)
      end

      it "validates that a block is provided" do
        expect {
          dummy_controller.format_response(resource,
                                        notice: "Success",
                                        status: :ok,
                                        on_error_render: :new)
        }.to raise_error(Patternist::ParameterError, "Block is required for format_response")
      end
    end

    context "error handling" do
      it "re-raises errors that occur during response formatting" do
        allow(dummy_controller).to receive(:respond_to).and_raise(StandardError, "Something went wrong")

        expect {
          dummy_controller.format_response(resource,
                                        notice: "Success",
                                        status: :ok,
                                        on_error_render: :new) { true }
        }.to raise_error(StandardError, "Something went wrong")
      end
    end
  end

  describe "private methods" do
    describe "#handle_success" do
      let(:format) { dummy_controller.send(:format_stub) }

      before do
        allow(dummy_controller).to receive(:redirect_to)
        allow(dummy_controller).to receive(:render)
      end

      it "calls custom success formats" do
        custom_xml = -> { "xml response" }
        expect(custom_xml).to receive(:call)

        dummy_controller.send(:handle_success, format, resource, "Success", :ok, { xml: custom_xml })
      end
    end

    describe "#handle_error" do
      let(:format) { dummy_controller.send(:format_stub) }

      before do
        allow(dummy_controller).to receive(:render)
      end

      it "calls custom error formats" do
        custom_error_xml = -> { "xml error" }
        expect(custom_error_xml).to receive(:call)

        dummy_controller.send(:handle_error, format, resource, :new, { error_xml: custom_error_xml })
      end
    end
  end
end