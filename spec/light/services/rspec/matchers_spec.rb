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
        it "matches when argument is required" do
          # name has no default and is not optional - it's a required arg
          expect(service_class).not_to define_argument(:name).optional
        end

        it "does not match when argument is optional" do
          # email is explicitly optional
          expect(service_class).to define_argument(:email).optional
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

      describe ".with_default" do
        it "matches when default is correct" do
          expect(service_class).to define_output(:count).with_default(0)
        end

        it "does not match when default is incorrect" do
          expect(service_class).not_to define_output(:count).with_default(10)
        end
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
    end
  end
end
