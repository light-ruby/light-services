# frozen_string_literal: true

require "spec_helper"
require "rspec-benchmark"

RSpec.describe "Operandi Performance", type: :performance do # rubocop:disable RSpec/DescribeClass
  include RSpec::Benchmark::Matchers

  # Create a hierarchy to test memoization benefits
  let(:base_service) do
    Class.new(Operandi::Base) do
      arg :base_arg1, type: String
      arg :base_arg2, type: Integer
      output :base_output1, type: String
      output :base_output2, type: Hash
      step :base_step1
      step :base_step2

      private

      def base_step1
        # noop
      end

      def base_step2
        # noop
      end
    end
  end

  let(:child_service) do
    Class.new(base_service) do
      arg :child_arg1, type: String
      arg :child_arg2, type: [TrueClass, FalseClass], default: true
      arg :child_arg3, type: Array, optional: true
      output :child_output1, type: Integer
      output :child_output2, type: String
      output :child_output3, type: Hash
      step :child_step1
      step :child_step2
      step :child_step3

      private

      def child_step1
        # noop
      end

      def child_step2
        # noop
      end

      def child_step3
        # noop
      end
    end
  end

  describe "memoization performance" do
    it "performs arguments lookup efficiently with memoization" do
      # First call builds the arguments hash
      child_service.arguments

      # Subsequent calls should be fast due to memoization
      expect { child_service.arguments }.to perform_under(0.001, warmup: 2, times: 100)
    end

    it "performs outputs lookup efficiently with memoization" do
      # First call builds the outputs hash
      child_service.outputs

      # Subsequent calls should be fast due to memoization
      expect { child_service.outputs }.to perform_under(0.001, warmup: 2, times: 100)
    end

    it "performs steps lookup efficiently with memoization" do
      # First call builds the steps hash
      child_service.steps

      # Subsequent calls should be fast due to memoization
      expect { child_service.steps }.to perform_under(0.001, warmup: 2, times: 100)
    end

    it "maintains consistent object identity with memoization" do
      # Test that memoization returns the same object
      args1 = child_service.arguments
      args2 = child_service.arguments
      expect(args1).to be(args2) # Same object identity

      outputs1 = child_service.outputs
      outputs2 = child_service.outputs
      expect(outputs1).to be(outputs2) # Same object identity

      steps1 = child_service.steps
      steps2 = child_service.steps
      expect(steps1).to be(steps2) # Same object identity
    end

    it "invalidates cache when adding new arguments" do
      original_args = child_service.arguments

      # Adding new argument should clear cache
      child_service.class_eval do
        arg :new_arg, type: String
      end

      new_args = child_service.arguments
      expect(new_args).not_to be(original_args) # Different object
      expect(new_args.size).to eq(original_args.size + 1)
    end

    it "invalidates cache when adding new outputs" do
      original_outputs = child_service.outputs

      # Adding new output should clear cache
      child_service.class_eval do
        output :new_output, type: String
      end

      new_outputs = child_service.outputs
      expect(new_outputs).not_to be(original_outputs) # Different object
      expect(new_outputs.size).to eq(original_outputs.size + 1)
    end

    it "invalidates cache when adding new steps" do
      original_steps = child_service.steps

      # Adding new step should clear cache
      child_service.class_eval do
        step :new_step

        private

        def new_step
          # noop
        end
      end

      new_steps = child_service.steps
      expect(new_steps).not_to be(original_steps) # Different object
      expect(new_steps.size).to eq(original_steps.size + 1)
    end
  end

  describe "inheritance performance" do
    it "builds complex inheritance hierarchies efficiently" do
      # Test that building inheritance is reasonably fast
      expect do
        child_service.arguments
        child_service.outputs
        child_service.steps
      end.to perform_under(0.01, warmup: 2, times: 10)
    end

    it "handles repeated inheritance queries efficiently" do
      # After memoization, repeated queries should be very fast
      child_service.arguments # Prime the cache
      child_service.outputs   # Prime the cache
      child_service.steps     # Prime the cache

      expect do
        10.times do
          child_service.arguments
          child_service.outputs
          child_service.steps
        end
      end.to perform_under(0.001, warmup: 2, times: 10)
    end
  end
end
