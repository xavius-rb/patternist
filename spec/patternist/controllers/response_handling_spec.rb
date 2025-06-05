# frozen_string_literal: true

require "patternist/rails/controllers/response_handling"

RSpec.describe Patternist::Rails::Controllers::ResponseHandling do
  let(:dummy_controller_class) do
    Class.new do
      include Patternist::Rails::Controllers::ResponseHandling

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
  let(:resource) { double("resource", errors: { error: "Invalid" }) }

  describe "#format_response" do
    context "when operation succeeds" do
      before do
        allow(dummy_controller).to receive_messages(redirect_to: true, render: true)
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
        expect(custom_error_html).to receive(:call)
        dummy_controller.format_response(resource,
                                      notice: "Success",
                                      status: :ok,
                                      on_error_render: :new,
                                      formats: {
                                        error_html: custom_error_html,
                                      }) { false }
      end

      it "handles custom error format handlers" do
        custom_error_json = -> { "custom error json" }
        expect(custom_error_json).to receive(:call)
        dummy_controller.format_response(resource,
                                      notice: "Success",
                                      status: :ok,
                                      on_error_render: :new,
                                      formats: {
                                        error_json: custom_error_json
                                      }) { false }
      end
    end

  end
end