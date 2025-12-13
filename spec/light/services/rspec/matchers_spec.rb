# frozen_string_literal: true

require "spec_helper"
require "light/services/rspec"

RSpec.describe Light::Services::RSpec::Matchers do
  describe "#define_argument" do
    context "with a service that defines arguments" do
      let(:service_class) do
        Class.new(ApplicationService) do
          arg :name, type: String
          arg :email, optional: true
          arg :age, type: Integer, default: 18

          step :process

          private

          def process; end
        end
      end

      it "matches when argument is defined" do
        expect(service_class).to define_argument(:name)
      end

      it "does not match when argument is not defined" do
        expect(service_class).not_to define_argument(:unknown)
      end

      describe ".with_type" do
        it "matches when type is correct" do
          expect(service_class).to define_argument(:name).with_type(String)
        end

        it "does not match when type is incorrect" do
          expect(service_class).not_to define_argument(:name).with_type(Integer)
        end
      end

      describe ".optional" do
        it "matches when argument is optional" do
          expect(service_class).to define_argument(:email).optional
        end

        it "does not match when argument is required" do
          expect(service_class).not_to define_argument(:name).optional
        end
      end

      describe ".required" do
        let(:required_arg_service) do
          Class.new(Light::Services::Base) do
            arg :name, type: String, optional: false # explicitly required

            step :process

            private

            def process; end
          end
        end

        it "matches when argument is required" do
          # name is explicitly set as required
          expect(required_arg_service).to define_argument(:name).required
        end

        it "does not match when argument is optional" do
          # email is explicitly optional
          expect(service_class).not_to define_argument(:email).required
        end
      end

      describe ".with_default" do
        it "matches when default is correct" do
          expect(service_class).to define_argument(:age).with_default(18)
        end

        it "does not match when default is incorrect" do
          expect(service_class).not_to define_argument(:age).with_default(21)
        end

        it "does not match when no default exists" do
          expect(service_class).not_to define_argument(:name).with_default("default")
        end
      end

      describe ".with_context" do
        it "matches when argument has context flag" do
          # current_user is defined in ApplicationService with context: true
          expect(service_class).to define_argument(:current_user).with_context
        end

        it "does not match when argument does not have context flag" do
          expect(service_class).not_to define_argument(:name).with_context
        end
      end

      describe "chaining" do
        it "supports multiple constraints" do
          expect(service_class).to define_argument(:age).with_type(Integer).with_default(18)
        end
      end
    end

    context "with failure messages" do
      let(:service_class) do
        Class.new(ApplicationService) do
          arg :name, type: String, optional: true
          arg :email, type: String, default: "default@example.com"
          arg :age, type: Integer

          step :process

          private

          def process; end
        end
      end

      it "provides helpful message when argument is not defined" do
        matcher = define_argument(:unknown)
        matcher.matches?(service_class)
        expect(matcher.failure_message).to include("to define argument :unknown")
      end

      it "provides helpful message when type does not match" do
        matcher = define_argument(:name).with_type(Integer)
        matcher.matches?(service_class)
        expect(matcher.failure_message).to include("type")
        expect(matcher.failure_message).to include("Integer")
        expect(matcher.failure_message).to include("String")
      end

      it "provides helpful message when optional does not match (expected optional)" do
        matcher = define_argument(:age).optional
        matcher.matches?(service_class)
        expect(matcher.failure_message).to include("to be optional")
        expect(matcher.failure_message).to include("but it is required")
      end

      it "provides helpful message when optional does not match (expected required)" do
        matcher = define_argument(:name).required
        matcher.matches?(service_class)
        expect(matcher.failure_message).to include("to be required")
        expect(matcher.failure_message).to include("but it is optional")
      end

      it "provides helpful message when default does not match" do
        matcher = define_argument(:email).with_default("other@example.com")
        matcher.matches?(service_class)
        expect(matcher.failure_message).to include("to have default")
        expect(matcher.failure_message).to include("other@example.com")
        expect(matcher.failure_message).to include("default@example.com")
      end

      it "provides helpful message when default is expected but none exists" do
        matcher = define_argument(:age).with_default(25)
        matcher.matches?(service_class)
        expect(matcher.failure_message).to include("to have default")
        expect(matcher.failure_message).to include("but no default is defined")
      end

      it "provides helpful message when context flag does not match (expected true)" do
        matcher = define_argument(:name).with_context
        matcher.matches?(service_class)
        expect(matcher.failure_message).to include("to have context flag")
        expect(matcher.failure_message).to include("but it doesn't")
      end

      it "provides helpful message when context flag does not match (expected false)" do
        matcher = define_argument(:current_user).with_context(false)
        matcher.matches?(service_class)
        expect(matcher.failure_message).to include("not to have context flag")
        expect(matcher.failure_message).to include("but it does")
      end

      it "provides failure_message_when_negated" do
        matcher = define_argument(:name)
        matcher.matches?(service_class)
        expect(matcher.failure_message_when_negated).to include("not to define argument :name")
      end

      it "provides description" do
        matcher = define_argument(:name).with_type(String).optional.with_default("test").with_context
        expect(matcher.description).to include("define argument :name")
        expect(matcher.description).to include("with type String")
        expect(matcher.description).to include("as optional")
        expect(matcher.description).to include("with default \"test\"")
        expect(matcher.description).to include("with context")
      end

      it "provides description for required argument" do
        matcher = define_argument(:name).required
        expect(matcher.description).to include("as required")
      end

      it "returns empty string when all checks pass (defensive)" do
        matcher = define_argument(:current_user).with_context
        expect(matcher.matches?(service_class)).to be true
        # Calling failure_message when match passed returns empty string (defensive code)
        expect(matcher.failure_message).to eq("")
      end
    end
  end

  describe "#define_output" do
    context "with a service that defines outputs" do
      let(:service_class) do
        Class.new(ApplicationService) do
          output :result, type: Hash
          output :message, optional: true
          output :count, type: Integer, default: 0

          step :process

          private

          def process
            self.result = {}
          end
        end
      end

      it "matches when output is defined" do
        expect(service_class).to define_output(:result)
      end

      it "does not match when output is not defined" do
        expect(service_class).not_to define_output(:unknown)
      end

      describe ".with_type" do
        it "matches when type is correct" do
          expect(service_class).to define_output(:result).with_type(Hash)
        end

        it "does not match when type is incorrect" do
          expect(service_class).not_to define_output(:result).with_type(Array)
        end
      end

      describe ".optional" do
        it "matches when output is optional" do
          expect(service_class).to define_output(:message).optional
        end

        it "does not match when output is required" do
          expect(service_class).not_to define_output(:result).optional
        end
      end

      describe ".required" do
        let(:required_output_service) do
          Class.new(Light::Services::Base) do
            output :result, type: Hash, optional: false # explicitly required

            step :process

            private

            def process
              self.result = {}
            end
          end
        end

        it "matches when output is required" do
          expect(required_output_service).to define_output(:result).required
        end

        it "does not match when output is optional" do
          expect(service_class).not_to define_output(:message).required
        end
      end

      describe ".with_default" do
        it "matches when default is correct" do
          expect(service_class).to define_output(:count).with_default(0)
        end

        it "does not match when default is incorrect" do
          expect(service_class).not_to define_output(:count).with_default(10)
        end
      end
    end

    context "with failure messages" do
      let(:service_class) do
        Class.new(ApplicationService) do
          output :result, type: Hash
          output :message, optional: true
          output :count, type: Integer, default: 5
          output :status

          step :process

          private

          def process
            self.result = {}
          end
        end
      end

      it "provides helpful message when output is not defined" do
        matcher = define_output(:unknown)
        matcher.matches?(service_class)
        expect(matcher.failure_message).to include("to define output :unknown")
      end

      it "provides helpful message when type does not match" do
        matcher = define_output(:result).with_type(Array)
        matcher.matches?(service_class)
        expect(matcher.failure_message).to include("type")
        expect(matcher.failure_message).to include("Array")
        expect(matcher.failure_message).to include("Hash")
      end

      it "provides helpful message when optional does not match (expected optional)" do
        matcher = define_output(:result).optional
        matcher.matches?(service_class)
        expect(matcher.failure_message).to include("to be optional")
        expect(matcher.failure_message).to include("but it is required")
      end

      it "provides helpful message when optional does not match (expected required)" do
        matcher = define_output(:message).required
        matcher.matches?(service_class)
        expect(matcher.failure_message).to include("to be required")
        expect(matcher.failure_message).to include("but it is optional")
      end

      it "provides helpful message when default does not match" do
        matcher = define_output(:count).with_default(10)
        matcher.matches?(service_class)
        expect(matcher.failure_message).to include("to have default")
        expect(matcher.failure_message).to include("10")
        expect(matcher.failure_message).to include("5")
      end

      it "provides helpful message when default is expected but none exists" do
        matcher = define_output(:status).with_default("pending")
        matcher.matches?(service_class)
        expect(matcher.failure_message).to include("to have default")
        expect(matcher.failure_message).to include("but no default is defined")
      end

      it "provides failure_message_when_negated" do
        matcher = define_output(:result)
        matcher.matches?(service_class)
        expect(matcher.failure_message_when_negated).to include("not to define output :result")
      end

      it "provides description" do
        matcher = define_output(:result).with_type(Hash).optional.with_default({})
        expect(matcher.description).to include("define output :result")
        expect(matcher.description).to include("with type Hash")
        expect(matcher.description).to include("as optional")
        expect(matcher.description).to include("with default {}")
      end

      it "provides description for required output" do
        matcher = define_output(:result).required
        expect(matcher.description).to include("as required")
      end

      it "returns empty string when all checks pass (defensive)" do
        simple_service = Class.new(Light::Services::Base) do
          output :foo, type: String

          step :process

          private

          def process
            self.foo = "bar"
          end
        end

        matcher = define_output(:foo)
        result = matcher.matches?(simple_service)
        expect(result).to be true
        # This calls failure_message even when match passes (defensive path)
        message = matcher.failure_message
        expect(message).to eq("")
      end
    end
  end

  describe "#define_step" do
    context "with a service that defines steps" do
      let(:service_class) do
        Class.new(ApplicationService) do
          arg :skip_notify, default: false

          step :validate
          step :process
          step :notify, if: :should_notify?
          step :skip_log, unless: :logging_enabled?
          step :cleanup, always: true

          private

          def validate; end
          def process; end
          def notify; end
          def skip_log; end
          def cleanup; end
          def should_notify? = !skip_notify
          def logging_enabled? = true
        end
      end

      it "matches when step is defined" do
        expect(service_class).to define_step(:validate)
      end

      it "does not match when step is not defined" do
        expect(service_class).not_to define_step(:unknown)
      end

      describe ".with_always" do
        it "matches when always flag is correct" do
          expect(service_class).to define_step(:cleanup).with_always(true)
        end

        it "does not match when always flag is incorrect" do
          expect(service_class).not_to define_step(:validate).with_always(true)
        end
      end

      describe ".with_if" do
        it "matches when if condition is correct" do
          expect(service_class).to define_step(:notify).with_if(:should_notify?)
        end

        it "does not match when if condition is incorrect" do
          expect(service_class).not_to define_step(:notify).with_if(:other_condition)
        end
      end

      describe ".with_unless" do
        it "matches when unless condition is correct" do
          expect(service_class).to define_step(:skip_log).with_unless(:logging_enabled?)
        end

        it "does not match when unless condition is incorrect" do
          expect(service_class).not_to define_step(:skip_log).with_unless(:other_condition)
        end
      end
    end

    describe "#define_steps" do
      let(:service_class) do
        Class.new(ApplicationService) do
          step :validate
          step :process
          step :save

          private

          def validate; end
          def process; end
          def save; end
        end
      end

      it "matches when all steps are defined" do
        expect(service_class).to define_steps(:validate, :process, :save)
      end

      it "matches when subset of steps are defined" do
        expect(service_class).to define_steps(:validate, :save)
      end

      it "does not match when some steps are missing" do
        expect(service_class).not_to define_steps(:validate, :unknown)
      end
    end

    describe "#define_steps_in_order" do
      let(:service_class) do
        Class.new(ApplicationService) do
          step :validate
          step :process
          step :save

          private

          def validate; end
          def process; end
          def save; end
        end
      end

      it "matches when steps are in correct order" do
        expect(service_class).to define_steps_in_order(:validate, :process, :save)
      end

      it "matches when subset is in correct order" do
        expect(service_class).to define_steps_in_order(:validate, :save)
      end

      it "does not match when steps are in wrong order" do
        expect(service_class).not_to define_steps_in_order(:save, :validate)
      end
    end

    context "with failure messages" do
      let(:service_class) do
        Class.new(ApplicationService) do
          step :validate
          step :process, if: :should_process?
          step :cleanup, always: true

          private

          def validate; end
          def process; end
          def cleanup; end
          def should_process? = true
        end
      end

      it "provides helpful message when step is not defined" do
        matcher = define_step(:unknown)
        matcher.matches?(service_class)
        expect(matcher.failure_message).to include("to define step :unknown")
      end

      it "provides helpful message when always flag does not match" do
        matcher = define_step(:validate).with_always(true)
        matcher.matches?(service_class)
        expect(matcher.failure_message).to include("to have always: true")
        expect(matcher.failure_message).to include("but it has always: nil")
      end

      it "provides helpful message when if condition does not match" do
        matcher = define_step(:process).with_if(:other_condition)
        matcher.matches?(service_class)
        expect(matcher.failure_message).to include("to have if: :other_condition")
        expect(matcher.failure_message).to include("but it has if: :should_process?")
      end

      it "provides helpful message when if condition expected but none is set" do
        simple_service = Class.new(ApplicationService) do
          step :process

          private

          def process; end
        end

        matcher = define_step(:process).with_if(:something)
        matcher.matches?(simple_service)
        expect(matcher.failure_message).to include("to have if:")
        expect(matcher.failure_message).to include("but it has if: nil")
      end

      it "provides helpful message when unless condition does not match" do
        skip_service = Class.new(ApplicationService) do
          step :process, unless: :skip_it?

          private

          def process; end
          def skip_it? = false
        end

        matcher = define_step(:process).with_unless(:other_condition)
        matcher.matches?(skip_service)
        expect(matcher.failure_message).to include("to have unless: :other_condition")
        expect(matcher.failure_message).to include("but it has unless: :skip_it?")
      end

      it "provides helpful message when unless condition expected but none is set" do
        simple_service = Class.new(ApplicationService) do
          step :process

          private

          def process; end
        end

        matcher = define_step(:process).with_unless(:something)
        matcher.matches?(simple_service)
        expect(matcher.failure_message).to include("to have unless:")
        expect(matcher.failure_message).to include("but it has unless: nil")
      end

      it "provides failure_message_when_negated" do
        matcher = define_step(:validate)
        matcher.matches?(service_class)
        expect(matcher.failure_message_when_negated).to include("not to define step :validate")
      end

      it "provides description" do
        matcher = define_step(:process).with_if(:should_process?).with_always(false)
        expect(matcher.description).to include("define step :process")
        expect(matcher.description).to include("with if: :should_process?")
        expect(matcher.description).to include("with always: false")
      end

      it "provides description with unless condition" do
        matcher = define_step(:process).with_unless(:skip_it?)
        expect(matcher.description).to include("with unless: :skip_it?")
      end

      it "provides failure message for define_steps when not all found" do
        matcher = define_steps(:validate, :unknown)
        matcher.matches?(service_class)
        expect(matcher.failure_message).to include("to define steps")
        expect(matcher.failure_message).to include("unknown")
        expect(matcher.failure_message).to include("missing")
      end

      it "provides failure_message_when_negated for define_steps" do
        matcher = define_steps(:validate, :process)
        matcher.matches?(service_class)
        expect(matcher.failure_message_when_negated).to include("not to define steps")
      end

      it "provides description for define_steps" do
        matcher = define_steps(:validate, :process)
        expect(matcher.description).to include("define steps")
      end

      it "provides failure message for define_steps_in_order when not in order" do
        matcher = define_steps_in_order(:process, :validate)
        matcher.matches?(service_class)
        expect(matcher.failure_message).to include("steps")
        expect(matcher.failure_message).to include("order")
      end

      it "provides failure_message_when_negated for define_steps_in_order" do
        matcher = define_steps_in_order(:validate, :process)
        matcher.matches?(service_class)
        expect(matcher.failure_message_when_negated).to include("not to define steps")
        expect(matcher.failure_message_when_negated).to include("in that order")
      end

      it "provides description for define_steps_in_order" do
        matcher = define_steps_in_order(:validate, :process)
        expect(matcher.description).to include("define steps")
        expect(matcher.description).to include("in order")
      end

      it "returns empty string when all checks pass on define_step (defensive)" do
        matcher = define_step(:cleanup).with_always(true)
        expect(matcher.matches?(service_class)).to be true
        expect(matcher.failure_message).to eq("")
      end

      it "returns empty string when all checks pass on define_steps_in_order (defensive)" do
        matcher = define_steps_in_order(:validate, :process)
        expect(matcher.matches?(service_class)).to be true
        expect(matcher.failure_message).to eq("")
      end
    end
  end

  describe "#have_error_on" do
    let(:service_class) do
      Class.new(ApplicationService) do
        arg :name, optional: true

        step :validate

        private

        def validate
          errors.add(:name, "can't be blank") if name.nil? || name.empty?
          errors.add(:name, "is too short") if name && name.length < 3
        end
      end
    end

    context "when service has errors" do
      let(:service) { service_class.run(name: "") }

      it "matches when error key exists" do
        expect(service).to have_error_on(:name)
      end

      it "does not match when error key does not exist" do
        expect(service).not_to have_error_on(:email)
      end

      describe ".with_message" do
        it "matches when message is present" do
          expect(service).to have_error_on(:name).with_message("can't be blank")
        end

        it "does not match when message is not present" do
          expect(service).not_to have_error_on(:name).with_message("is invalid")
        end

        it "matches with regex" do
          expect(service).to have_error_on(:name).with_message(/blank/)
        end
      end
    end

    context "when service has no errors" do
      let(:service) { service_class.run(name: "John") }

      it "does not match" do
        expect(service).not_to have_error_on(:name)
      end
    end

    context "with failure messages" do
      let(:service) { service_class.run(name: "") }

      it "provides helpful message when error key is missing" do
        matcher = have_error_on(:email)
        matcher.matches?(service)
        expect(matcher.failure_message).to include("to have error on :email")
        expect(matcher.failure_message).to include("errors were")
      end

      it "provides helpful message when message does not match" do
        matcher = have_error_on(:name).with_message("wrong message")
        matcher.matches?(service)
        expect(matcher.failure_message).to include("wrong message")
        expect(matcher.failure_message).to include("can't be blank")
      end

      it "provides failure_message_when_negated" do
        matcher = have_error_on(:name)
        matcher.matches?(service)
        expect(matcher.failure_message_when_negated).to include("not to have error on :name")
      end

      it "provides failure_message_when_negated with message" do
        matcher = have_error_on(:name).with_message("can't be blank")
        matcher.matches?(service)
        expect(matcher.failure_message_when_negated).to include("with message")
      end

      it "provides description" do
        matcher = have_error_on(:name)
        expect(matcher.description).to include("have error on :name")
      end

      it "provides description with message" do
        matcher = have_error_on(:name).with_message("can't be blank")
        expect(matcher.description).to include("have error on :name")
        expect(matcher.description).to include("with message")
      end

      it "returns empty string when all checks pass (defensive)" do
        service = service_class.run(name: "")
        matcher = have_error_on(:name)
        expect(matcher.matches?(service)).to be true
        expect(matcher.failure_message).to eq("")
      end

      it "shows empty when service has no errors" do
        no_error_service = Class.new(ApplicationService) do
          step :process

          private

          def process; end
        end.run

        matcher = have_error_on(:foo)
        matcher.matches?(no_error_service)
        expect(matcher.failure_message).to include("errors were: empty")
      end
    end
  end

  describe "#have_errors_on" do
    # NOTE: Testing multiple errors requires config break_on_error: false
    # or using break: false on each error.add call
    let(:service_class) do
      Class.new(ApplicationService) do
        arg :name, optional: true

        step :validate

        private

        def validate
          errors.add(:name, "can't be blank") if name.nil? || name.empty?
          errors.add(:base, "general error")
        end
      end
    end

    context "when service has errors" do
      let(:service) { service_class.run(name: "") }

      it "matches when error key exists" do
        expect(service).to have_errors_on(:name)
      end

      it "does not match when some error keys are missing" do
        expect(service).not_to have_errors_on(:name, :email)
      end
    end

    context "with failure messages" do
      let(:service) { service_class.run(name: "") }

      it "provides failure message when not all errors found" do
        matcher = have_errors_on(:name, :email)
        matcher.matches?(service)
        expect(matcher.failure_message).to include("to have errors on")
        expect(matcher.failure_message).to include("email")
        expect(matcher.failure_message).to include("missing")
      end

      it "provides failure message when service has no errors at all" do
        empty_service = Class.new(ApplicationService) do
          step :process

          private

          def process; end
        end.run

        matcher = have_errors_on(:anything)
        matcher.matches?(empty_service)
        expect(matcher.failure_message).to include("Actual errors: empty")
      end

      it "provides failure_message_when_negated" do
        matcher = have_errors_on(:name, :base)
        matcher.matches?(service)
        expect(matcher.failure_message_when_negated).to include("not to have errors on")
      end

      it "provides description" do
        matcher = have_errors_on(:name, :base)
        expect(matcher.description).to include("have errors on")
      end
    end
  end

  describe "#have_warning_on" do
    let(:service_class) do
      Class.new(ApplicationService) do
        arg :value, optional: true

        step :process

        private

        def process
          warnings.add(:value, "was adjusted") if value && value > 100
        end
      end
    end

    context "when service has warnings" do
      let(:service) { service_class.run(value: 150) }

      it "matches when warning key exists" do
        expect(service).to have_warning_on(:value)
      end

      it "does not match when warning key does not exist" do
        expect(service).not_to have_warning_on(:other)
      end

      describe ".with_message" do
        it "matches when message is present" do
          expect(service).to have_warning_on(:value).with_message("was adjusted")
        end

        it "matches with regex" do
          expect(service).to have_warning_on(:value).with_message(/adjusted/)
        end

        it "does not match when message is not present" do
          expect(service).not_to have_warning_on(:value).with_message("wrong message")
        end
      end
    end

    context "with failure messages" do
      let(:service_class) do
        Class.new(ApplicationService) do
          arg :value, optional: true

          step :process

          private

          def process
            warnings.add(:value, "was adjusted") if value && value > 100
          end
        end
      end

      it "provides failure message when warning key is missing" do
        service = service_class.run(value: 50)
        matcher = have_warning_on(:value)
        matcher.matches?(service)
        expect(matcher.failure_message).to include("to have warning on :value")
        expect(matcher.failure_message).to include("warnings were")
      end

      it "provides failure message when service has no warnings at all" do
        empty_service = Class.new(ApplicationService) do
          step :process

          private

          def process; end
        end.run

        matcher = have_warning_on(:anything)
        matcher.matches?(empty_service)
        expect(matcher.failure_message).to include("warnings were: empty")
      end

      it "provides failure message when message does not match" do
        service = service_class.run(value: 150)
        matcher = have_warning_on(:value).with_message("wrong message")
        matcher.matches?(service)
        expect(matcher.failure_message).to include("wrong message")
        expect(matcher.failure_message).to include("was adjusted")
      end

      it "provides failure_message_when_negated" do
        service = service_class.run(value: 150)
        matcher = have_warning_on(:value)
        matcher.matches?(service)
        expect(matcher.failure_message_when_negated).to include("not to have warning on :value")
      end

      it "provides failure_message_when_negated with message" do
        service = service_class.run(value: 150)
        matcher = have_warning_on(:value).with_message("was adjusted")
        matcher.matches?(service)
        expect(matcher.failure_message_when_negated).to include("with message")
      end

      it "provides description" do
        matcher = have_warning_on(:value)
        expect(matcher.description).to include("have warning on :value")
      end

      it "provides description with message" do
        matcher = have_warning_on(:value).with_message("was adjusted")
        expect(matcher.description).to include("have warning on :value")
        expect(matcher.description).to include("with message")
      end

      it "returns empty string when all checks pass (defensive)" do
        service = service_class.run(value: 150)
        matcher = have_warning_on(:value)
        expect(matcher.matches?(service)).to be true
        expect(matcher.failure_message).to eq("")
      end

      it "shows warnings summary when warning key is missing but warnings exist" do
        service = service_class.run(value: 150)
        matcher = have_warning_on(:other_key)
        matcher.matches?(service)
        expect(matcher.failure_message).to include("warnings were:")
        expect(matcher.failure_message).to include("value")
      end
    end

    describe "#have_warnings_on" do
      let(:service_class) do
        Class.new(ApplicationService) do
          arg :value, optional: true

          step :process

          private

          def process
            warnings.add(:value, "was adjusted") if value && value > 100
            warnings.add(:base, "general warning")
          end
        end
      end

      it "matches when all warning keys exist" do
        service = service_class.run(value: 150)
        expect(service).to have_warnings_on(:value, :base)
      end

      it "does not match when some warning keys are missing" do
        service = service_class.run(value: 150)
        expect(service).not_to have_warnings_on(:value, :other)
      end

      it "provides failure message when not all warnings found" do
        service = service_class.run(value: 150)
        matcher = have_warnings_on(:value, :other)
        matcher.matches?(service)
        expect(matcher.failure_message).to include("to have warnings on")
        expect(matcher.failure_message).to include("other")
        expect(matcher.failure_message).to include("missing")
      end

      it "provides failure message when service has no warnings at all" do
        empty_service = Class.new(ApplicationService) do
          step :process

          private

          def process; end
        end.run

        matcher = have_warnings_on(:anything)
        matcher.matches?(empty_service)
        expect(matcher.failure_message).to include("Actual warnings: empty")
      end

      it "provides failure_message_when_negated" do
        service = service_class.run(value: 150)
        matcher = have_warnings_on(:value, :base)
        matcher.matches?(service)
        expect(matcher.failure_message_when_negated).to include("not to have warnings on")
      end

      it "provides description" do
        matcher = have_warnings_on(:value, :base)
        expect(matcher.description).to include("have warnings on")
      end
    end
  end

  describe "#execute_step and #skip_step" do
    let(:service_class) do
      Class.new(ApplicationService) do
        arg :skip_notify, default: false
        output :executed_steps, default: -> { [] }

        step :validate
        step :process
        step :notify, if: :should_notify?

        after_step_run do |service, step_name|
          service.executed_steps << step_name
        end

        private

        def validate; end
        def process; end
        def notify; end
        def should_notify? = !skip_notify
      end
    end

    describe "#execute_step" do
      context "when step was executed" do
        let(:service) { service_class.run(skip_notify: false) }

        it "matches" do
          expect(service).to execute_step(:validate)
          expect(service).to execute_step(:notify)
        end
      end

      context "when step was skipped" do
        let(:service) { service_class.run(skip_notify: true) }

        it "does not match" do
          expect(service).not_to execute_step(:notify)
        end
      end
    end

    describe "#skip_step" do
      context "when step was skipped" do
        let(:service) { service_class.run(skip_notify: true) }

        it "matches" do
          expect(service).to skip_step(:notify)
        end
      end

      context "when step was executed" do
        let(:service) { service_class.run(skip_notify: false) }

        it "does not match" do
          expect(service).not_to skip_step(:notify)
        end
      end
    end

    describe "#execute_steps" do
      let(:service) { service_class.run(skip_notify: false) }

      it "matches when all steps were executed" do
        expect(service).to execute_steps(:validate, :process, :notify)
      end

      it "does not match when some steps were not executed" do
        service_with_skip = service_class.run(skip_notify: true)
        expect(service_with_skip).not_to execute_steps(:validate, :notify)
      end
    end

    describe "#execute_steps_in_order" do
      let(:service) { service_class.run(skip_notify: false) }

      it "matches when steps were executed in order" do
        expect(service).to execute_steps_in_order(:validate, :process, :notify)
      end

      it "matches for subset in correct order" do
        expect(service).to execute_steps_in_order(:validate, :notify)
      end

      it "does not match when order is wrong" do
        expect(service).not_to execute_steps_in_order(:notify, :validate)
      end
    end

    context "with failure messages" do
      it "provides failure message for execute_step when step was not executed" do
        service = service_class.run(skip_notify: true)
        matcher = execute_step(:notify)
        matcher.matches?(service)
        expect(matcher.failure_message).to include("to execute step :notify")
      end

      it "provides failure message for execute_step when tracking not available" do
        service_without_tracking = Class.new(ApplicationService) do
          step :process

          private

          def process; end
        end.run

        matcher = execute_step(:process)
        matcher.matches?(service_without_tracking)
        message = matcher.failure_message
        expect(message).to include("does not track executed steps")
        # Force full string evaluation
        expect(message.length).to be > 100
        expected = "Add `after_step_run { |service, step| service.executed_steps << step }` to your service"
        expect(message).to include(expected)
      end

      it "provides failure_message_when_negated for execute_step" do
        service = service_class.run(skip_notify: false)
        matcher = execute_step(:notify)
        matcher.matches?(service)
        expect(matcher.failure_message_when_negated).to include("not to execute step :notify")
      end

      it "provides description for execute_step" do
        matcher = execute_step(:notify)
        expect(matcher.description).to include("execute step :notify")
      end

      it "provides failure message for skip_step when step was executed" do
        service = service_class.run(skip_notify: false)
        matcher = skip_step(:notify)
        matcher.matches?(service)
        expect(matcher.failure_message).to include("to skip step :notify")
      end

      it "provides failure message for skip_step when tracking not available" do
        service_without_tracking = Class.new(ApplicationService) do
          step :process

          private

          def process; end
        end.run

        matcher = skip_step(:process)
        matcher.matches?(service_without_tracking)
        expect(matcher.failure_message).to include("does not track executed steps")
      end

      it "provides failure_message_when_negated for skip_step" do
        service = service_class.run(skip_notify: true)
        matcher = skip_step(:notify)
        matcher.matches?(service)
        expect(matcher.failure_message_when_negated).to include("not to skip step :notify")
      end

      it "provides description for skip_step" do
        matcher = skip_step(:notify)
        expect(matcher.description).to include("skip step :notify")
      end

      it "provides failure message for execute_steps when not all executed" do
        service = service_class.run(skip_notify: true)
        matcher = execute_steps(:validate, :notify)
        matcher.matches?(service)
        expect(matcher.failure_message).to include("to execute")
        expect(matcher.failure_message).to include("steps")
      end

      it "provides failure message for execute_steps when tracking not available" do
        service_without_tracking = Class.new(ApplicationService) do
          step :process

          private

          def process; end
        end.run

        matcher = execute_steps(:process, :validate)
        matcher.matches?(service_without_tracking)
        message = matcher.failure_message
        expect(message).to include("does not track executed steps")
        expected = "Add `after_step_run { |service, step| service.executed_steps << step }` to your service"
        expect(message).to include(expected)
      end

      it "provides failure_message_when_negated for execute_steps" do
        service = service_class.run(skip_notify: false)
        matcher = execute_steps(:validate, :notify)
        matcher.matches?(service)
        expect(matcher.failure_message_when_negated).to include("not to execute")
        expect(matcher.failure_message_when_negated).to include("steps")
      end

      it "provides description for execute_steps" do
        matcher = execute_steps(:validate, :notify)
        expect(matcher.description).to include("execute steps")
      end

      it "provides failure message for execute_steps_in_order when not in order" do
        service = service_class.run(skip_notify: false)
        matcher = execute_steps_in_order(:notify, :validate)
        matcher.matches?(service)
        expect(matcher.failure_message).to include("steps")
        expect(matcher.failure_message).to include("order")
      end

      it "provides failure_message_when_negated for execute_steps_in_order" do
        service = service_class.run(skip_notify: false)
        matcher = execute_steps_in_order(:validate, :notify)
        matcher.matches?(service)
        expect(matcher.failure_message_when_negated).to include("not to execute steps")
        expect(matcher.failure_message_when_negated).to include("in that order")
      end

      it "provides description for execute_steps_in_order" do
        matcher = execute_steps_in_order(:validate, :notify)
        expect(matcher.description).to include("execute steps")
        expect(matcher.description).to include("in order")
      end

      it "matches when step was executed (with tracking)" do
        service_with_tracking = Class.new(ApplicationService) do
          output :executed_steps, default: -> { [] }

          step :validate
          step :process

          after_step_run do |service, step_name|
            service.executed_steps << step_name
          end

          private

          def validate; end
          def process; end
        end.run

        expect(service_with_tracking).to execute_step(:validate)
        expect(service_with_tracking).to execute_step(:process)
      end

      it "returns empty string when all checks pass on execute_steps_in_order (defensive)" do
        service = service_class.run(skip_notify: false)
        matcher = execute_steps_in_order(:validate, :notify)
        expect(matcher.matches?(service)).to be true
        expect(matcher.failure_message).to eq("")
      end
    end
  end

  describe "#trigger_callback" do
    let(:service_class) do
      Class.new(ApplicationService) do
        output :callback_log, default: -> { [] }

        before_service_run do |service|
          service.callback_log << :before_service_run
        end

        after_service_run do |service|
          service.callback_log << :after_service_run
        end

        on_service_success do |service|
          service.callback_log << :on_service_success
        end

        on_service_failure do |service|
          service.callback_log << :on_service_failure
        end

        after_step_run do |service, step_name|
          service.callback_log << [:after_step_run, step_name]
        end

        on_step_success do |service, step_name|
          service.callback_log << [:on_step_success, step_name]
        end

        step :validate
        step :process

        private

        def validate; end
        def process; end
      end
    end

    context "with service-level callbacks" do
      let(:service) { service_class.run }

      it "matches when callback was triggered" do
        expect(service).to trigger_callback(:before_service_run)
        expect(service).to trigger_callback(:after_service_run)
        expect(service).to trigger_callback(:on_service_success)
      end

      it "does not match when callback was not triggered" do
        expect(service).not_to trigger_callback(:on_service_failure)
      end
    end

    context "with step-level callbacks" do
      let(:service) { service_class.run }

      describe ".for_step" do
        it "matches when callback was triggered for specific step" do
          expect(service).to trigger_callback(:after_step_run).for_step(:validate)
          expect(service).to trigger_callback(:on_step_success).for_step(:process)
        end

        it "does not match for wrong step" do
          expect(service).not_to trigger_callback(:after_step_run).for_step(:unknown)
        end
      end
    end

    context "with failure messages" do
      let(:service_without_tracking) do
        Class.new(ApplicationService) do
          step :process

          private

          def process; end
        end.run
      end

      it "provides helpful message when tracking is not available" do
        matcher = trigger_callback(:before_service_run)
        matcher.matches?(service_without_tracking)
        expect(matcher.failure_message).to include("does not track callbacks")
      end

      it "provides failure message when callback was not triggered" do
        service = service_class.run
        matcher = trigger_callback(:on_service_failure)
        matcher.matches?(service)
        expect(matcher.failure_message).to include("to trigger callback")
        expect(matcher.failure_message).to include("on_service_failure")
      end

      it "provides failure message for step callback when not triggered" do
        service = service_class.run
        matcher = trigger_callback(:after_step_run).for_step(:unknown)
        matcher.matches?(service)
        expect(matcher.failure_message).to include("to trigger callback")
        expect(matcher.failure_message).to include("after_step_run")
        expect(matcher.failure_message).to include("unknown")
      end

      it "provides failure_message_when_negated" do
        service = service_class.run
        matcher = trigger_callback(:before_service_run)
        matcher.matches?(service)
        expect(matcher.failure_message_when_negated).to include("not to trigger callback :before_service_run")
      end

      it "provides failure_message_when_negated for step callback" do
        service = service_class.run
        matcher = trigger_callback(:after_step_run).for_step(:validate)
        matcher.matches?(service)
        expect(matcher.failure_message_when_negated).to include("not to trigger callback")
        expect(matcher.failure_message_when_negated).to include("for step :validate")
      end

      it "provides description" do
        matcher = trigger_callback(:before_service_run)
        expect(matcher.description).to include("trigger callback :before_service_run")
      end

      it "provides description for step callback" do
        matcher = trigger_callback(:after_step_run).for_step(:validate)
        expect(matcher.description).to include("trigger callback :after_step_run")
        expect(matcher.description).to include("for step :validate")
      end

      it "matches when callback was triggered (defensive check)" do
        service = service_class.run
        matcher = trigger_callback(:before_service_run)
        expect(matcher.matches?(service)).to be true
      end

      it "handles unexpected data type in callback_log gracefully" do
        service_with_weird_log = Class.new(ApplicationService) do
          output :callback_log, default: -> { [123] } # Number instead of Symbol/Array

          step :process

          private

          def process; end
        end.run

        matcher = trigger_callback(:before_service_run)
        expect(matcher.matches?(service_with_weird_log)).to be false
      end
    end
  end
end
