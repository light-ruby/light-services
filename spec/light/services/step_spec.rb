# frozen_string_literal: true

RSpec.describe Light::Services::Settings::Step do
  describe "step ordering" do
    describe "with before: option" do
      let(:service) { WithStepInsertion.run }

      it "inserts step before specified step" do
        expect(service.execution_order).to eq([:a, :b, :c])
      end
    end

    describe "with after: option" do
      let(:service) { WithStepAfter.run }

      it "inserts step after specified step" do
        expect(service.execution_order).to eq([:a, :b, :c])
      end
    end
  end

  describe "remove_step" do
    let(:service) { WithStepRemoval.run }

    it "removes the step from execution" do
      expect(service.execution_order).to eq([:a, :c])
      expect(service.execution_order).not_to include(:b)
    end
  end

  describe "step conditions" do
    describe "with if: Symbol" do
      let(:service_with_c) { WithConditions.run(add_c: true) }
      let(:service_without_c) { WithConditions.run(add_c: false) }

      it "runs step when condition is true" do
        expect(service_with_c.word).to include("c")
      end

      it "skips step when condition is false" do
        expect(service_without_c.word).not_to include("c")
      end
    end

    describe "with unless: Symbol" do
      let(:service_with_d) { WithConditions.run(do_not_add_d: false) }
      let(:service_without_d) { WithConditions.run(do_not_add_d: true) }

      it "runs step when condition is false" do
        expect(service_with_d.word).to include("d")
      end

      it "skips step when condition is true" do
        expect(service_without_d.word).not_to include("d")
      end
    end

    describe "with if: Proc" do
      let(:service) { WithConditions.run }

      it "evaluates proc in instance context" do
        # step :letter_a, if: -> { true } always runs
        expect(service.word).to start_with("a")
      end
    end

    describe "with unless: Proc" do
      let(:service) { WithConditions.run }

      it "evaluates proc in instance context" do
        # step :letter_b, unless: -> { false } always runs
        expect(service.word).to include("b")
      end
    end
  end

  describe "always: option" do
    context "when there are errors" do
      let(:service) { WithConditions.with(use_transactions: false).run(fake_error: true) }

      it "runs the step even after errors" do
        # replace_word has always: true and runs even after add_error
        expect(service.word).to eq("error")
      end
    end

    context "when step was already executed" do
      let(:service) { WithConditions.run }

      it "does not run again" do
        # replace_word has always: true but only runs once
        expect(service.word).not_to eq("error")
      end
    end
  end

  describe "done! behavior" do
    let(:service) { WithDone.run(add_c: true, do_not_add_d: false) }

    it "stops execution of subsequent steps" do
      # done! is called in letter_b, so letter_c and letter_d never run
      expect(service.word).to eq("ab")
    end
  end

  describe "#run" do
    let(:step) { described_class.new(:test_step, TestStepService) }

    context "when step method does not exist" do
      before do
        stub_const("TestStepService", Class.new(Light::Services::Base))
      end

      it "raises NoStepError" do
        instance = TestStepService.new
        expect { step.run(instance) }.to raise_error(Light::Services::NoStepError, /Cannot find step/)
      end
    end
  end
end

RSpec.describe "Steps collection" do
  describe "step indexing" do
    it "returns index of existing item" do
      steps = WithConditions.steps
      # WithConditions has steps: letter_a, letter_b, letter_c, letter_d, add_error, replace_word
      expect(steps.keys.index(:letter_a)).to eq(0)
      expect(steps.keys.index(:letter_b)).to eq(1)
    end
  end

  describe "steps retrieval" do
    it "returns all steps for class" do
      steps = WithConditions.steps
      expect(steps).to be_a(Hash)
      expect(steps.keys).to include(:letter_a, :letter_b)
    end
  end

  describe "inheritance" do
    it "inherits steps from parent class" do
      # CreateService has steps, Product::Create inherits from CreateService
      expect(Product::Create.steps.keys).to include(:initialize_entity, :assign_attributes, :save)
    end

    it "allows child to modify inherited steps" do
      # Order::Create removes :assign_attributes and adds new steps
      expect(Order::Create.steps.keys).not_to include(:assign_attributes)
      expect(Order::Create.steps.keys).to include(:assign_user, :assign_default_attributes)
    end
  end
end
