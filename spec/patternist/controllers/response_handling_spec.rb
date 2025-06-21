# frozen_string_literal: true

require 'patternist/controllers/actionpack/response_handling'

RSpec.describe Patternist::Controllers::ActionPack::ResponseHandling do
  let(:dummy_controller_class) do
    Class.new do
      include Patternist::Controllers::ActionPack::ResponseHandling

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

  before do
    stub_const('Post', Class.new do
      def self.name
        'Post'
      end

      def self.model_name
        OpenStruct.new(human: 'Post')
      end
    end)
  end

  describe '#format_response' do
    let(:dummy_controller) { dummy_controller_class.new }
    let(:resource) { instance_double(Post, errors: { error: 'Invalid' }) }

    context 'when operation succeeds' do
      before do
        allow(dummy_controller).to receive_messages(redirect_to: true, render: true)
      end

      it 'handles successful HTML response' do
        dummy_controller.format_response(resource,
                                         notice: 'Success',
                                         status: :ok,
                                         on_error_render: :new) { true }

        expect(dummy_controller).to have_received(:redirect_to).with(resource, notice: 'Success')
      end

      it 'handles successful JSON response' do
        dummy_controller.format_response(resource,
                                         notice: 'Success',
                                         status: :ok,
                                         on_error_render: :new) { true }

        expect(dummy_controller).to have_received(:render).with(:show, status: :ok, location: resource)
      end
    end

    context 'when operation fails' do
      before do
        allow(dummy_controller).to receive(:render).and_return(true)
      end

      it 'handles error HTML response' do
        dummy_controller.format_response(resource,
                                         notice: 'Success',
                                         status: :ok,
                                         on_error_render: :new) { false }

        expect(dummy_controller).to have_received(:render).with(:new, status: :unprocessable_entity)
      end

      it 'handles error JSON response' do
        dummy_controller.format_response(resource,
                                         notice: 'Success',
                                         status: :ok,
                                         on_error_render: :new) { false }

        expect(dummy_controller).to have_received(:render).with(
          json: resource.errors,
          status: :unprocessable_entity
        )
      end

      it 'handles custom error HTML format' do
        custom_error_html = -> { 'custom error html' }

        allow(custom_error_html).to receive(:call)

        dummy_controller.format_response(resource,
                                         notice: 'Success',
                                         status: :ok,
                                         on_error_render: :new,
                                         formats: {
                                           error_html: custom_error_html
                                         }) { false }

        expect(custom_error_html).to have_received(:call)
      end

      it 'handles custom error JSON format' do
        custom_error_json = -> { 'custom error json' }

        allow(custom_error_json).to receive(:call)

        dummy_controller.format_response(resource,
                                         notice: 'Success',
                                         status: :ok,
                                         on_error_render: :new,
                                         formats: {
                                           error_json: custom_error_json
                                         }) { false }

        expect(custom_error_json).to have_received(:call)
      end
    end
  end
end
