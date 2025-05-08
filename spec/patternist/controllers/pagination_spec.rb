# frozen_string_literal: true

require "patternist/controllers/pagination"

RSpec.describe Patternist::Controllers::Pagination do
  let(:dummy_controller_class) do
    Class.new do
      include Patternist::Controllers::Pagination

      attr_accessor :params

      def initialize
        @params = {}
      end
    end
  end

  let(:dummy_controller) { dummy_controller_class.new }
  let(:collection) { [1, 2, 3, 4, 5] }

  describe "#paginate" do
    context "when no pagination gem is available" do
      it "returns the original collection" do
        expect(dummy_controller.send(:paginate, collection)).to eq(collection)
      end
    end

    context "when Kaminari is available" do
      before do
        stub_const("Kaminari", Module.new)
        allow(collection).to receive(:page).and_return(collection)
        allow(collection).to receive(:per).and_return([1, 2, 3])
      end

      it "paginates using Kaminari" do
        dummy_controller.params = { page: 2, per_page: 3 }
        expect(collection).to receive(:page).with(2)
        expect(collection).to receive(:per).with(3)
        dummy_controller.send(:paginate, collection)
      end

      it "uses default values when params are missing" do
        expect(collection).to receive(:page).with(1)
        expect(collection).to receive(:per).with(described_class::DEFAULT_PAGE_SIZE)
        dummy_controller.send(:paginate, collection)
      end
    end

    context "when WillPaginate is available" do
      before do
        stub_const("WillPaginate", Module.new)
        allow(collection).to receive(:paginate).and_return([1, 2, 3])
      end

      it "paginates using WillPaginate" do
        dummy_controller.params = { page: 2, per_page: 3 }
        expect(collection).to receive(:paginate).with(page: 2, per_page: 3)
        dummy_controller.send(:paginate, collection)
      end

      it "uses default values when params are missing" do
        expect(collection).to receive(:paginate).with(
          page: 1,
          per_page: described_class::DEFAULT_PAGE_SIZE
        )
        dummy_controller.send(:paginate, collection)
      end
    end
  end

  describe "#default_page_size" do
    context "when PER_PAGE is defined" do
      before do
        dummy_controller_class.const_set(:PER_PAGE, 50)
      end

      it "returns the defined PER_PAGE value" do
        expect(dummy_controller.send(:default_page_size)).to eq(50)
      end
    end

    context "when PER_PAGE is not defined" do
      it "returns the default page size" do
        expect(dummy_controller.send(:default_page_size)).to eq(described_class::DEFAULT_PAGE_SIZE)
      end
    end
  end
end