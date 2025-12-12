# frozen_string_literal: true

RSpec.describe Light::Services::Base do
  describe "#success?" do
    context "when no errors" do
      let(:service) { WithConditions.run }

      it { expect(service.success?).to be(true) }
    end

    context "when there are errors" do
      let(:service) { WithConditions.with(use_transactions: false).run(fake_error: true) }

      it { expect(service.success?).to be(false) }
    end
  end

  describe "#failed?" do
    context "when no errors" do
      let(:service) { WithConditions.run }

      it { expect(service.failed?).to be(false) }
    end

    context "when there are errors" do
      let(:service) { WithConditions.with(use_transactions: false).run(fake_error: true) }

      it { expect(service.failed?).to be(true) }
    end
  end

  describe "#errors?" do
    context "when no errors" do
      let(:service) { WithConditions.run }

      it { expect(service.errors?).to be(false) }
    end

    context "when there are errors" do
      let(:service) { WithConditions.with(use_transactions: false).run(fake_error: true) }

      it { expect(service.errors?).to be(true) }
    end
  end

  describe "#warnings?" do
    context "when no warnings" do
      let(:service) { WithConditions.run }

      it { expect(service.warnings?).to be(false) }
    end

    context "when there are warnings" do
      let(:service) { WithConditions.with(use_transactions: false).run(fake_error: true) }

      it { expect(service.warnings?).to be(true) }
    end
  end

  describe "#done!" do
    let(:service) { WithDone.run(add_c: true) }

    it "stops execution of subsequent steps" do
      expect(service.word).to eq("ab")
    end
  end

  describe "#done?" do
    let(:service) { WithDone.run }

    it "returns true after done! is called" do
      expect(service.done?).to be(true)
    end
  end

  describe "exception handling" do
    context "when a step raises an exception" do
      it "still runs steps with always: true" do
        expect { WithException.run }.to raise_error(StandardError, "Something went wrong!")
      end

      it "runs always steps before re-raising" do
        service = WithException.new
        expect { service.call }.to raise_error(StandardError)
        expect(service.always_step_ran).to be(true)
      end
    end
  end

  describe ".run" do
    it "creates and calls the service" do
      service = WithConditions.run
      expect(service).to be_a(WithConditions)
      expect(service.word).to eq("ab")
    end
  end

  describe ".run!" do
    context "when service succeeds" do
      it "returns the service" do
        service = WithConditions.run!
        expect(service).to be_success
      end
    end

    context "when service fails" do
      it "raises an error" do
        expect { WithClassConfig.run! }.to raise_error(Light::Services::Error)
      end
    end
  end

  describe ".with" do
    context "with config hash" do
      it "applies config to service" do
        service = WithConditions.with(use_transactions: false).run(fake_error: true)
        expect(service.failed?).to be(true)
      end
    end

    context "with parent service" do
      it "copies context arguments from parent" do
        user = User.create!(name: "Test User")
        product = Product.create!(name: "Test Product", price: 100)
        service = Product::AddToCart.run(current_user: user, product: product)
        # current_user is passed to Order::Create via .with(self) which passes context args
        expect(service).to be_success
        expect(service.order).to be_persisted
      end
    end

    context "with invalid parent service" do
      it "raises ArgTypeError" do
        expect { WithConditions.with(Object.new).run }.to raise_error(Light::Services::ArgTypeError)
      end
    end
  end

  describe ".config" do
    it "sets class-level config" do
      expect(WithClassConfig.class_config).to eq({ raise_on_error: true })
    end
  end

  describe "#log" do
    let(:service) { WithConditions.new(deepness: 0) }

    it "outputs formatted message" do
      expect { service.log("test message") }.to output(/→ test message/).to_stdout
    end

    context "with deepness" do
      let(:service) { WithConditions.new(deepness: 2) }

      it "indents based on deepness" do
        expect { service.log("test") }.to output(/    → test/).to_stdout
      end
    end
  end

  describe "outputs" do
    let(:service) { WithConditions.run }

    it "provides access via method" do
      expect(service.word).to eq("ab")
    end

    it "provides access via outputs collection" do
      expect(service.outputs[:word]).to eq("ab")
    end

    it "provides boolean check method" do
      expect(service.word?).to be(true)
    end
  end

  describe "arguments" do
    let(:service) { Product::AddToCart.run(current_user: user, product: product) }
    let(:user) { User.create!(name: "Test User") }
    let(:product) { Product.create!(name: "Test Product", price: 100) }

    it "provides access via method" do
      expect(service.current_user).to eq(user)
    end

    it "provides access via arguments collection" do
      expect(service.arguments[:current_user]).to eq(user)
    end

    it "provides boolean check method" do
      expect(service.current_user?).to be(true)
    end

    it "allows setting via collection" do
      service.arguments[:quantity] = 10
      expect(service.arguments[:quantity]).to eq(10)
    end
  end

  describe "default arguments" do
    it "uses default values when not provided" do
      service = WithConditions.run
      expect(service.verbose).to be(false)
      expect(service.benchmark).to be(false)
    end

    it "overrides defaults when provided" do
      service = WithConditions.run(verbose: true)
      expect(service.verbose).to be(true)
    end
  end

  describe "Proc defaults" do
    let(:product) { Product.create!(name: "Test", price: 100) }
    let(:user) { User.create!(name: "Test User") }

    it "evaluates Proc defaults in instance context" do
      service = Product::AddToCart.run(current_user: user, product: product)
      # test_default has default: -> { product }
      expect(service.arguments[:test_default]).to eq(product)
    end
  end
end
