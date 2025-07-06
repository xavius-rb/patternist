# frozen_string_literal: true

require 'patternist/controller'
require 'ostruct'

RSpec.describe Patternist::Controller do
  let(:dummy_controller_class) do
    Class.new do
      include Patternist::Controller
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
    stub_const('Post', Class.new do
      attr_accessor :title, :body

      def self.all
        %w[post1 post2 post3]
      end

      def self.find(id)
        id == 1 ? new : raise('Record not found')
      end

      def initialize(attrs = {})
        @title = attrs[:title]
        @body = attrs[:body]
      end

      def self.name
        'Post'
      end

      def self.model_name
        OpenStruct.new(human: 'Post')
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
        { error: 'Invalid' }
      end
    end)
    allow(dummy_controller_class).to receive(:resource_class).and_return(Post)
  end

  describe '#index' do
    context 'with pagination', skip: 'Pagination not supported' do
      before do
        stub_const('Kaminari', Module.new)
        allow(Post).to receive(:all).and_return(Post.all)
        allow(Post.all).to receive_messages(page: Post.all, per: %w[post1 post2])
      end

      it 'paginates the collection' do
        dummy_controller.params = { page: 2, per_page: 2 }
        dummy_controller.index

        aggregate_failures do
          expect(Post.all).to have_received(:page).with(2)
          expect(Post.all).to have_received(:per).with(2)
        end
      end

      it 'sets the paginated collection as instance variable' do
        dummy_controller.index
        expect(dummy_controller.instance_variable_get('@posts')).to eq(%w[post1 post2])
      end
    end

    it 'sets the instance variable for the collection' do
      aggregate_failures do
        expect(dummy_controller.instance_variable_get(:@posts)).to be_nil
        dummy_controller.index
        expect(dummy_controller.instance_variable_get(:@posts)).to eq(%w[post1 post2 post3])
        expect(dummy_controller.instance_variable_get('@posts')).to eq(Post.all)
      end
    end
  end

  describe '#show' do
    before do
      allow(Post).to receive(:find).and_call_original
      dummy_controller.params = { id: 1 }
    end

    it 'sets the instance variable for the resource' do
      aggregate_failures do
        expect(dummy_controller.instance_variable_get('@post')).to be_nil
        dummy_controller.show
        expect(Post).to have_received(:find).with(1)
        expect(dummy_controller.instance_variable_get('@post')).to be_a(Post)
      end
    end

    it 'executes the block when provided' do
      block_executed = false

      dummy_controller.show do
        block_executed = true
      end

      aggregate_failures do
        expect(block_executed).to be true
        expect(dummy_controller.instance_variable_get('@post')).to be_a(Post)
      end
    end

    it 'allows access to the resource in the block' do
      resource_in_block = nil

      dummy_controller.show do
        resource_in_block = dummy_controller.resource
      end

      expect(resource_in_block).to be_a(Post)
    end

    it 'can set additional instance variables in the block' do
      dummy_controller.show do
        dummy_controller.instance_variable_set(:@additional_data, 'custom data')
      end

      expect(dummy_controller.instance_variable_get(:@additional_data)).to eq('custom data')
    end

    it 'works without a block' do
      aggregate_failures do
        expect { dummy_controller.show }.not_to raise_error
        expect(dummy_controller.instance_variable_get('@post')).to be_a(Post)
      end
    end
  end

  describe '#edit' do
    before do
      allow(Post).to receive(:find).and_call_original
      dummy_controller.params = { id: 1 }
    end

    it 'sets the instance variable for the resource' do
      aggregate_failures do
        expect(dummy_controller.instance_variable_get('@post')).to be_nil
        dummy_controller.edit
        expect(Post).to have_received(:find).with(1)
        expect(dummy_controller.instance_variable_get('@post')).to be_a(Post)
      end
    end
  end

  describe '#new' do
    before do
      allow(Post).to receive(:new).and_call_original
    end

    it 'sets a new instance of the resource' do
      aggregate_failures do
        expect(dummy_controller.instance_variable_get('@post')).to be_nil
        dummy_controller.new
        expect(Post).to have_received(:new).with(no_args)
        expect(dummy_controller.instance_variable_get('@post')).to be_a(Post)
      end
    end
  end

  describe '#create' do
    context 'when controller defines resource_params' do
      before do
        dummy_controller.define_singleton_method(:resource_params) do
          { title: 'New Post', body: 'Body' }
        end

        allow(dummy_controller).to receive_messages(redirect_to: true, render: true)
        allow_any_instance_of(Post).to receive(:save).and_return(true)
        allow(Post).to receive(:new).and_call_original
      end

      it 'creates a new resource and responds with success' do
        aggregate_failures do
          allow(dummy_controller).to receive(:respond_to).and_call_original
          expect(dummy_controller.instance_variable_get('@post')).to be_nil
          dummy_controller.create
          expect(dummy_controller.instance_variable_get('@post')).to be_a(Post)
          expect(Post).to have_received(:new).with(title: 'New Post', body: 'Body')
          expect(dummy_controller).to have_received(:render).with(:show, status: :created,
                                                                         location: an_instance_of(Post))
        end
      end

      it 'renders error response when save fails' do
        aggregate_failures do
          allow_any_instance_of(Post).to receive(:save).and_return(false)
          allow(dummy_controller).to receive(:respond_to).and_call_original
          dummy_controller.create
          expect(dummy_controller).to have_received(:render).with(:new, status: :unprocessable_entity)
        end
      end
    end

    context 'when controller does not define resource_params' do
      it 'raises NotImplementedError' do
        expect { dummy_controller.create }.to raise_error(Patternist::NotImplementedError)
      end
    end

    context 'with custom response format' do
      let(:custom_response) { -> { 'custom response' } }

      before do
        dummy_controller.define_singleton_method(:resource_params) do
          { title: 'New Post', body: 'Body' }
        end

        allow(dummy_controller).to receive(:format_response).and_call_original
        allow(dummy_controller).to receive_messages(redirect_to: true, render: true)
      end

      it 'uses format_response with custom format' do
        dummy_controller.create
        expect(dummy_controller).to have_received(:format_response).with(
          kind_of(Post),
          notice: 'Post was successfully created.',
          status: :created,
          on_error_render: :new
        )
      end
    end
  end

  describe '#update' do
    context 'when controller defines resource_params' do
      before do
        dummy_controller.define_singleton_method(:resource_params) do
          { title: 'New Post', body: 'Body' }
        end

        allow(dummy_controller).to receive_messages(redirect_to: true, render: true)
        allow_any_instance_of(Post).to receive(:update).and_return(true)
        allow(Post).to receive(:find).and_call_original
        dummy_controller.params = { id: 1, title: 'Updated' }
      end

      it 'updates the resource and responds with success' do
        aggregate_failures do
          allow(dummy_controller).to receive(:respond_to).and_call_original
          dummy_controller.update
          expect(Post).to have_received(:find).with(1)
          expect(dummy_controller).to have_received(:render).with(:show, status: :ok, location: an_instance_of(Post))
        end
      end

      it 'renders error response when update fails' do
        aggregate_failures do
          allow_any_instance_of(Post).to receive(:update).and_return(false)
          allow(dummy_controller).to receive(:respond_to).and_call_original
          dummy_controller.update
          expect(dummy_controller).to have_received(:render).with(:edit, status: :unprocessable_entity)
        end
      end
    end

    context 'when controller does not define resource_params' do
      before do
        dummy_controller.params = { id: 1, title: 'Updated' }
      end

      it 'raises NotImplementedError' do
        expect { dummy_controller.update }.to raise_error(Patternist::NotImplementedError)
      end
    end
  end

  describe '#destroy' do
    before do
      allow(dummy_controller).to receive_messages(redirect_to: true, render: true, head: true)
      dummy_controller.params = { id: 1 }
    end

    it 'destroys the resource' do
      post_instance = Post.new
      allow(Post).to receive(:find).and_return(post_instance)
      allow(post_instance).to receive(:destroy).and_return(true)

      dummy_controller.destroy

      expect(post_instance).to have_received(:destroy)
    end

    it 'calls format_response with correct parameters including notice' do
      allow(dummy_controller).to receive(:format_response).and_call_original

      dummy_controller.destroy

      expect(dummy_controller).to have_received(:format_response).with(
        kind_of(Post),
        notice: 'Post was successfully destroyed.',
        status: :see_other,
        on_error_render: :show,
        formats: {
          html: kind_of(Proc),
          json: kind_of(Proc)
        }
      )
    end

    it 'passes notice to redirect_to when using default HTML format' do
      # Remove custom formats to test default behavior
      allow(dummy_controller).to receive(:destroy).and_wrap_original do |_original_method|
        dummy_controller.instance_eval do
          self.resource_instance = find_resource
          format_response(resource,
                          notice: "#{resource_class_name} was successfully destroyed.",
                          status: :see_other,
                          on_error_render: :show) do
            destroy_resource
          end
        end
      end

      dummy_controller.destroy

      expect(dummy_controller).to have_received(:redirect_to).with(
        kind_of(Post), notice: 'Post was successfully destroyed.'
      )
    end

    it 'uses custom format when provided but notice should still be available' do
      custom_html_called = false
      custom_json_called = false

      # Test with custom formats
      allow(dummy_controller).to receive(:destroy).and_wrap_original do |_original_method|
        dummy_controller.instance_eval do
          self.resource_instance = find_resource
          format_response(resource,
                          notice: "#{resource_class_name} was successfully destroyed.",
                          status: :see_other,
                          on_error_render: :show,
                          formats: {
                            html: lambda {
                              custom_html_called = true
                              redirect_to resource_class, notice: "#{resource_class_name} was successfully destroyed."
                            },
                            json: lambda {
                              custom_json_called = true
                              head :no_content
                            }
                          }) do
            destroy_resource
          end
        end
      end

      dummy_controller.destroy

      aggregate_failures do
        expect(custom_html_called).to be true
        expect(custom_json_called).to be true
        expect(dummy_controller).to have_received(:redirect_to).with(
          Post, notice: 'Post was successfully destroyed.'
        )
        expect(dummy_controller).to have_received(:head).with(:no_content)
      end
    end

    context 'with custom response format' do
      before do
        allow(dummy_controller).to receive(:format_response).and_call_original
        allow(dummy_controller).to receive_messages(redirect_to: true, head: true)
      end

      it 'uses format_response with custom format' do
        dummy_controller.destroy
        expect(dummy_controller).to have_received(:format_response).with(
          kind_of(Post),
          notice: 'Post was successfully destroyed.',
          status: :see_other,
          on_error_render: :show,
          formats: {
            html: kind_of(Proc),
            json: kind_of(Proc)
          }
        )
      end
    end
  end

  describe '#resource_params' do
    it 'raises NotImplementedError when not defined' do
      expect { dummy_controller.send(:resource_params) }.to raise_error(Patternist::NotImplementedError)
    end
  end

  describe '#collection' do
    it 'returns all resources' do
      expect(dummy_controller.send(:collection)).to eq(%w[post1 post2 post3])
    end
  end
end
