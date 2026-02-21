# frozen_string_literal: true

# Shared examples for testing CRUD controllers/requests backed by Patternist::Controller.
#
# Usage:
#   RSpec.describe "/posts", type: :request do
#     let(:valid_attributes) { { title: "Hello", body: "World" } }
#     let(:invalid_attributes) { { title: nil } }
#
#     it_behaves_like :patternist_controller, :post, Post
#   end
#
# Requirements:
#   - Standard Rails URL helpers must be available in the example group.
#   - ActiveSupport (included via ActionPack) provides +humanize+ / +pluralize+.
#   - +valid_attributes+ and +invalid_attributes+ must be defined by the caller.
#
# Overridable lets:
#   - +valid_attributes+   – required; hash of attributes that pass model validation
#   - +invalid_attributes+ – required; hash of attributes that fail model validation
#   - +new_attributes+     – used in PATCH /update specs; defaults to { name: "Updated <Resource>" }
#
# rubocop:disable Metrics/BlockLength
RSpec.shared_examples :patternist_controller do |resource_name, model_class|
  let(:resource_name) { resource_name }
  let(:model_class) { model_class }
  let(:collection_url) { send("#{resource_name.to_s.pluralize}_url") }
  let(:new_resource_url) { send("new_#{resource_name}_url") }

  describe 'GET /index' do
    it 'renders a successful response' do
      model_class.create!(valid_attributes)
      get collection_url
      expect(response).to be_successful
    end
  end

  describe 'GET /show' do
    it 'renders a successful response' do
      resource = model_class.create!(valid_attributes)
      get send("#{resource_name}_url", resource)
      expect(response).to be_successful
    end
  end

  describe 'GET /new' do
    it 'renders a successful response' do
      get new_resource_url
      expect(response).to be_successful
    end
  end

  describe 'GET /edit' do
    it 'renders a successful response' do
      resource = model_class.create!(valid_attributes)
      get send("edit_#{resource_name}_url", resource)
      expect(response).to be_successful
    end
  end

  describe 'POST /create' do
    context 'with valid parameters' do
      it "creates a new #{resource_name}" do
        expect do
          post collection_url, params: { resource_name.to_sym => valid_attributes }
        end.to change(model_class, :count).by(1)
      end

      it "redirects to the created #{resource_name}" do
        post collection_url, params: { resource_name.to_sym => valid_attributes }
        expect(response).to redirect_to(send("#{resource_name}_url", model_class.last))
      end

      it 'sets a notice message' do
        post collection_url, params: { resource_name.to_sym => valid_attributes }
        expect(flash[:notice]).to eq("#{resource_name.to_s.humanize} was successfully created.")
      end
    end

    context 'with invalid parameters' do
      it "does not create a new #{resource_name}" do
        expect do
          post collection_url, params: { resource_name.to_sym => invalid_attributes }
        end.to change(model_class, :count).by(0)
      end

      it "renders a response with 422 status (i.e. to display the 'new' template)" do
        post collection_url, params: { resource_name.to_sym => invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'PATCH /update' do
    context 'with valid parameters' do
      it "updates the requested #{resource_name}" do
        resource = model_class.create!(valid_attributes)
        patch send("#{resource_name}_url", resource), params: { resource_name.to_sym => new_attributes }
        resource.reload
        new_attributes.each do |attr, value|
          expect(resource.public_send(attr)).to eq(value)
        end
      end

      it "redirects to the #{resource_name}" do
        resource = model_class.create!(valid_attributes)
        patch send("#{resource_name}_url", resource), params: { resource_name.to_sym => new_attributes }
        resource.reload
        expect(response).to redirect_to(send("#{resource_name}_url", resource))
      end

      it 'sets a notice message' do
        resource = model_class.create!(valid_attributes)
        patch send("#{resource_name}_url", resource), params: { resource_name.to_sym => new_attributes }
        expect(flash[:notice]).to eq("#{resource_name.to_s.humanize} was successfully updated.")
      end
    end

    context 'with invalid parameters' do
      it "renders a response with 422 status (i.e. to display the 'edit' template)" do
        resource = model_class.create!(valid_attributes)
        patch send("#{resource_name}_url", resource), params: { resource_name.to_sym => invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE /destroy' do
    it "destroys the requested #{resource_name}" do
      resource = model_class.create!(valid_attributes)
      expect do
        delete send("#{resource_name}_url", resource)
      end.to change(model_class, :count).by(-1)
    end

    it "redirects to the #{resource_name.to_s.pluralize} list" do
      resource = model_class.create!(valid_attributes)
      delete send("#{resource_name}_url", resource)
      expect(response).to redirect_to(collection_url)
    end

    it 'sets a notice message' do
      resource = model_class.create!(valid_attributes)
      delete send("#{resource_name}_url", resource)
      expect(flash[:notice]).to eq("#{resource_name.to_s.humanize} was successfully destroyed.")
    end
  end
end
# rubocop:enable Metrics/BlockLength
