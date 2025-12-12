# frozen_string_literal: true

RSpec.describe "Reserved Names Validation" do # rubocop:disable RSpec/DescribeClass
  describe "ReservedNames constants" do
    it "includes expected base methods" do
      expect(Light::Services::ReservedNames::BASE_METHODS).to include(
        :outputs, :arguments, :errors, :warnings,
        :success?, :failed?, :errors?, :warnings?,
        :done!, :done?, :call,
      )
    end

    it "includes expected callback methods" do
      expect(Light::Services::ReservedNames::CALLBACK_METHODS).to include(
        :before_step_run, :after_step_run, :around_step_run,
        :on_step_success, :on_step_failure, :on_step_crash,
        :before_service_run, :after_service_run, :around_service_run,
        :on_service_success, :on_service_failure,
      )
    end

    it "includes Ruby reserved words" do
      expect(Light::Services::ReservedNames::RUBY_RESERVED).to include(
        :initialize, :class, :send, :method,
      )
    end

    it "combines all reserved names into ALL constant" do
      all_names = Light::Services::ReservedNames::ALL
      expect(all_names).to include(:outputs)
      expect(all_names).to include(:before_step_run)
      expect(all_names).to include(:initialize)
    end
  end

  describe "argument reserved name validation" do
    it "raises ReservedNameError for reserved gem method names" do
      expect do
        Class.new(Light::Services::Base) do
          arg :errors
        end
      end.to raise_error(
        Light::Services::ReservedNameError,
        /Cannot use `errors` as argument name.*reserved word/,
      )
    end

    it "raises ReservedNameError for callback names" do
      expect do
        Class.new(Light::Services::Base) do
          arg :before_step_run
        end
      end.to raise_error(
        Light::Services::ReservedNameError,
        /Cannot use `before_step_run` as argument name.*reserved word/,
      )
    end

    it "raises ReservedNameError for Ruby reserved words" do
      expect do
        Class.new(Light::Services::Base) do
          arg :initialize
        end
      end.to raise_error(
        Light::Services::ReservedNameError,
        /Cannot use `initialize` as argument name.*reserved word/,
      )
    end

    it "allows valid argument names" do
      expect do
        Class.new(Light::Services::Base) do
          arg :user_name, type: String
          arg :email, type: String
        end
      end.not_to raise_error
    end
  end

  describe "output reserved name validation" do
    it "raises ReservedNameError for reserved gem method names" do
      expect do
        Class.new(Light::Services::Base) do
          output :warnings
        end
      end.to raise_error(
        Light::Services::ReservedNameError,
        /Cannot use `warnings` as output name.*reserved word/,
      )
    end

    it "raises ReservedNameError for callback names" do
      expect do
        Class.new(Light::Services::Base) do
          output :on_service_success
        end
      end.to raise_error(
        Light::Services::ReservedNameError,
        /Cannot use `on_service_success` as output name.*reserved word/,
      )
    end

    it "raises ReservedNameError for Ruby reserved words" do
      expect do
        Class.new(Light::Services::Base) do
          output :class
        end
      end.to raise_error(
        Light::Services::ReservedNameError,
        /Cannot use `class` as output name.*reserved word/,
      )
    end

    it "allows valid output names" do
      expect do
        Class.new(Light::Services::Base) do
          output :result, type: Hash
          output :status, type: String
        end
      end.not_to raise_error
    end
  end

  describe "step reserved name validation" do
    it "raises ReservedNameError for reserved gem method names" do
      expect do
        Class.new(Light::Services::Base) do
          step :call
        end
      end.to raise_error(
        Light::Services::ReservedNameError,
        /Cannot use `call` as step name.*reserved word/,
      )
    end

    it "raises ReservedNameError for callback names" do
      expect do
        Class.new(Light::Services::Base) do
          step :after_service_run
        end
      end.to raise_error(
        Light::Services::ReservedNameError,
        /Cannot use `after_service_run` as step name.*reserved word/,
      )
    end

    it "raises ReservedNameError for Ruby reserved words" do
      expect do
        Class.new(Light::Services::Base) do
          step :send
        end
      end.to raise_error(
        Light::Services::ReservedNameError,
        /Cannot use `send` as step name.*reserved word/,
      )
    end

    it "allows valid step names" do
      expect do
        Class.new(Light::Services::Base) do
          step :validate_input
          step :process_data
        end
      end.not_to raise_error
    end
  end

  describe "cross-field name conflict validation" do
    describe "argument conflicts" do
      it "raises ReservedNameError when argument name conflicts with output" do
        expect do
          Class.new(Light::Services::Base) do
            output :data
            arg :data
          end
        end.to raise_error(
          Light::Services::ReservedNameError,
          /Cannot use `data` as argument name.*already defined as an output/,
        )
      end

      it "raises ReservedNameError when argument name conflicts with step" do
        expect do
          Class.new(Light::Services::Base) do
            step :process
            arg :process
          end
        end.to raise_error(
          Light::Services::ReservedNameError,
          /Cannot use `process` as argument name.*already defined as a step/,
        )
      end
    end

    describe "output conflicts" do
      it "raises ReservedNameError when output name conflicts with argument" do
        expect do
          Class.new(Light::Services::Base) do
            arg :result
            output :result
          end
        end.to raise_error(
          Light::Services::ReservedNameError,
          /Cannot use `result` as output name.*already defined as an argument/,
        )
      end

      it "raises ReservedNameError when output name conflicts with step" do
        expect do
          Class.new(Light::Services::Base) do
            step :calculate
            output :calculate
          end
        end.to raise_error(
          Light::Services::ReservedNameError,
          /Cannot use `calculate` as output name.*already defined as a step/,
        )
      end
    end

    describe "step conflicts" do
      it "raises ReservedNameError when step name conflicts with argument" do
        expect do
          Class.new(Light::Services::Base) do
            arg :validate
            step :validate
          end
        end.to raise_error(
          Light::Services::ReservedNameError,
          /Cannot use `validate` as step name.*already defined as an argument/,
        )
      end

      it "raises ReservedNameError when step name conflicts with output" do
        expect do
          Class.new(Light::Services::Base) do
            output :transform
            step :transform
          end
        end.to raise_error(
          Light::Services::ReservedNameError,
          /Cannot use `transform` as step name.*already defined as an output/,
        )
      end
    end

    it "allows different names for arguments, outputs, and steps" do
      expect do
        Class.new(Light::Services::Base) do
          arg :user_id, type: Integer
          output :result, type: Hash
          step :process

          private

          def process
            self.result = { user_id: user_id }
          end
        end
      end.not_to raise_error
    end
  end

  describe "ReservedNameError exception" do
    it "is a subclass of Light::Services::Error" do
      expect(Light::Services::ReservedNameError).to be < Light::Services::Error
    end
  end

  describe "inheritance conflict validation" do
    let(:parent_class) do
      Class.new(Light::Services::Base) do
        arg :user_id, type: Integer
        output :result, type: Hash
        step :process

        private

        def process
          self.result = { user_id: user_id }
        end
      end
    end

    it "raises ReservedNameError when child argument conflicts with inherited output" do
      parent = parent_class
      expect do
        Class.new(parent) do
          arg :result
        end
      end.to raise_error(
        Light::Services::ReservedNameError,
        /Cannot use `result` as argument name.*already defined as an output/,
      )
    end

    it "raises ReservedNameError when child argument conflicts with inherited step" do
      parent = parent_class
      expect do
        Class.new(parent) do
          arg :process
        end
      end.to raise_error(
        Light::Services::ReservedNameError,
        /Cannot use `process` as argument name.*already defined as a step/,
      )
    end

    it "raises ReservedNameError when child output conflicts with inherited argument" do
      parent = parent_class
      expect do
        Class.new(parent) do
          output :user_id
        end
      end.to raise_error(
        Light::Services::ReservedNameError,
        /Cannot use `user_id` as output name.*already defined as an argument/,
      )
    end

    it "raises ReservedNameError when child output conflicts with inherited step" do
      parent = parent_class
      expect do
        Class.new(parent) do
          output :process
        end
      end.to raise_error(
        Light::Services::ReservedNameError,
        /Cannot use `process` as output name.*already defined as a step/,
      )
    end

    it "raises ReservedNameError when child step conflicts with inherited argument" do
      parent = parent_class
      expect do
        Class.new(parent) do
          step :user_id
        end
      end.to raise_error(
        Light::Services::ReservedNameError,
        /Cannot use `user_id` as step name.*already defined as an argument/,
      )
    end

    it "raises ReservedNameError when child step conflicts with inherited output" do
      parent = parent_class
      expect do
        Class.new(parent) do
          step :result
        end
      end.to raise_error(
        Light::Services::ReservedNameError,
        /Cannot use `result` as step name.*already defined as an output/,
      )
    end

    it "allows child to define non-conflicting names" do
      parent = parent_class
      expect do
        Class.new(parent) do
          arg :name, type: String
          output :status, type: String
          step :validate
        end
      end.not_to raise_error
    end
  end
end
