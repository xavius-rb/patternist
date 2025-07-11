# frozen_string_literal: true

require 'patternist/controllers/actionpack/helpers'
require 'ostruct'

RSpec.describe Patternist::Controllers::ActionPack::Helpers do
  let(:dummy_controller_class) do
    Class.new do
      include Patternist::Controllers::ActionPack::Helpers

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
    stub_const('Post', Class.new do
      def self.name
        'Post'
      end

      def self.model_name
        OpenStruct.new(human: 'Post')
      end
    end)
  end

  describe 'ClassMethods' do
    before do
      allow(dummy_controller_class).to receive(:name).and_return('PostsController')
    end

    describe '.resource_class' do
      it 'infers the resource class from the controller name' do
        expect(dummy_controller_class.resource_class).to eq(Post)
      end

      it 'infers the resource class from namespaced controller names' do
        allow(dummy_controller_class).to receive(:name).and_return('Admin::PostsController')
        expect(dummy_controller_class.resource_class).to eq(Post)
      end

      it 'raises a NameError if the resource class cannot be found' do
        allow(dummy_controller_class).to receive(:name).and_return('UnknownController')
        expect { dummy_controller_class.resource_class }.to raise_error(Patternist::NameError)
      end

      it 'caches the result' do
        allow(Object).to receive(:const_get).with('Post').once.and_return(Post)
        2.times { dummy_controller_class.resource_class }
        expect(Object).to have_received(:const_get).with('Post').once
      end
    end

    describe '.resource_name' do
      it 'returns the underscored name of the resource class' do
        expect(dummy_controller_class.resource_name).to eq('post')
      end

      it 'caches the result' do
        allow(dummy_controller_class).to receive(:resource_class).once.and_return(Post)
        2.times { dummy_controller_class.resource_name }
        expect(dummy_controller_class.resource_name).to eq('post')
      end
    end
  end

  describe 'InstanceMethods' do
    before do
      allow(dummy_controller_class).to receive_messages(resource_class: Post, resource_name: 'post')
    end

    describe '#resource_class' do
      it 'returns the class resource_class inferred from the controller' do
        expect(dummy_controller.resource_class).to eq(Post)
      end

      it 'infers the resource class from namespaced controller names' do
        allow(dummy_controller_class).to receive(:name).and_return('Admin::PostsController')
        expect(dummy_controller.resource_class).to eq(Post)
      end
    end

    describe '#resource_name' do
      it 'returns the underscored name of the resource' do
        expect(dummy_controller.resource_name).to eq('post')
      end
    end

    describe '#resource_class_name' do
      it 'returns the human-readable name of the resource class' do
        expect(dummy_controller.resource_class_name).to eq('Post')
      end

      it 'falls back to class name if model_name is not available' do
        stub_const('SimplePost', Class.new do
          def self.name
            'SimplePost'
          end
        end)
        allow(dummy_controller_class).to receive(:resource_class).and_return(SimplePost)

        expect(dummy_controller.resource_class_name).to eq('SimplePost')
      end
    end

    describe '#collection_name' do
      it 'returns the pluralized name of the resource' do
        expect(dummy_controller.collection_name).to eq('posts')
      end
    end

    describe '#resource' do
      it 'returns the resource from the instance variable' do
        dummy_controller.instance_variable_set(:@post, 'dummy resource')
        expect(dummy_controller.resource).to eq('dummy resource')
      end
    end

    describe '#id_param' do
      it 'fetches the ID param from params' do
        dummy_controller.params[:id] = 123
        expect(dummy_controller.id_param).to eq(123)
      end

      it 'returns nil if the ID param is not found' do
        expect(dummy_controller.id_param).to be_nil
      end
    end
  end
end
