# frozen_string_literal: true

RSpec.describe Product::AddToCart do
  let(:service) { described_class.run(current_user: current_user, product: product) }

  context "when args are good" do
    let(:current_user) { User.create!(name: "Andrew Emelianenko") }
    let(:product) { Product.create!(name: "Tesla Model X", price: 100_000) }

    it { expect(service).to be_success }
    it { expect(service.order).to be_a(Order) }
    it { expect(service.order?).to be(true) }
    it { expect(service.order.products).to include(product) }
    it { expect(service.order.total_price).to be(100_000) }
    it { expect(service.outputs[:order]).to be_a(Order) }
    it { expect { service.arguments[:quantity] = 5 }.not_to raise_error }
  end

  context "with quantity" do
    let(:service) { described_class.run(current_user: current_user, product: product, quantity: 2) }
    let(:current_user) { User.create!(name: "Andrew Emelianenko") }
    let(:product) { Product.create!(name: "Tesla Model X", price: 100_000) }

    it { expect(service).to be_success }
    it { expect(service.order).to be_a(Order) }
    it { expect(service.order.products).to include(product) }
    it { expect(service.order.total_price).to be(200_000) }
  end

  context "when current user is absent" do
    let(:current_user) {}
    let(:product) { Product.create!(name: "Tesla Model X", price: 100_000) }

    it { expect { service }.to raise_error(Light::Services::ArgTypeError) }
  end

  context "when product is absent" do
    let(:current_user) { User.create!(name: "Andrew Emelianenko") }
    let(:product) {}

    it { expect { service }.to raise_error(Light::Services::ArgTypeError) }
  end

  context "when benchmark is enabled" do
    let(:service) { described_class.run(current_user: current_user, product: product, benchmark: true) }
    let(:current_user) { User.create!(name: "Andrew Emelianenko") }
    let(:product) { Product.create!(name: "Tesla Model X", price: 100_000) }

    it { expect { service }.to output(/Finished Product::AddToCart in/).to_stdout }
  end

  context "when verbose is enabled" do
    let(:service) { described_class.run(current_user: current_user, product: product, verbose: true) }
    let(:current_user) { User.create!(name: "Andrew Emelianenko") }
    let(:product) { Product.create!(name: "Tesla Model X", price: 100_000) }

    it { expect { service }.to output(/Run service Product::AddToCart/).to_stdout }
  end

  context "when copying errors to hash" do
    let(:service) { described_class.run(current_user: current_user, product: product, notify: true) }
    let(:current_user) { User.create!(name: "Andrew Emelianenko") }
    let(:product) { Product.create!(name: "Tesla Model X", price: 100_000) }
    let(:copied_errors) { service.errors.copy_to({ hello: "world" }) }

    it { expect(service).to be_failed }
    it { expect(copied_errors).to eq({ hello: "world", base: ["something went wrong"], text: ["must be present"] }) }
  end

  context "when copying errors to another service" do
    let(:service) { described_class.run(current_user: current_user, product: product, notify: true) }
    let(:current_user) { User.create!(name: "Andrew Emelianenko") }
    let(:product) { Product.create!(name: "Tesla Model X", price: 100_000) }
    let(:another_service) { Product::Create.with(rollback_on_error: false).run(params: { product: { name: "iPhone", price: 100 } }) }

    before { service.errors.copy_to(another_service) }

    it { expect(another_service).to be_failed }
    it { expect(another_service.errors.to_h).to eq({ base: ["something went wrong"], text: ["must be present"] }) }
  end
end
