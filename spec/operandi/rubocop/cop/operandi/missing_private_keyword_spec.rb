# frozen_string_literal: true

require "rubocop"
require "rubocop/rspec/support"
require "operandi/rubocop"

RSpec.describe RuboCop::Cop::Operandi::MissingPrivateKeyword, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  context "when step methods are public" do
    it "registers an offense for public step method" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :process

          def process
          ^^^^^^^^^^^ Operandi/MissingPrivateKeyword: Step method `process` should be private.
            # implementation
          end
        end
      RUBY
    end

    it "registers offenses for multiple public step methods" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :validate
          step :process

          def validate
          ^^^^^^^^^^^^ Operandi/MissingPrivateKeyword: Step method `validate` should be private.
            # implementation
          end

          def process
          ^^^^^^^^^^^ Operandi/MissingPrivateKeyword: Step method `process` should be private.
            # implementation
          end
        end
      RUBY
    end

    it "registers an offense only for step methods, not other public methods" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :process

          def process
          ^^^^^^^^^^^ Operandi/MissingPrivateKeyword: Step method `process` should be private.
            # implementation
          end

          def helper
            # This is fine, it's not a step
          end
        end
      RUBY
    end
  end

  context "when step methods are private" do
    it "does not register an offense when all step methods are private" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          step :validate
          step :process

          private

          def validate
            # implementation
          end

          def process
            # implementation
          end
        end
      RUBY
    end

    it "does not register an offense for private methods with other public methods" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          step :process

          def some_public_helper
            # This is fine
          end

          private

          def process
            # implementation
          end
        end
      RUBY
    end
  end

  context "with mixed visibility" do
    it "registers an offense only for public step methods" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :validate
          step :process
          step :notify

          def validate
          ^^^^^^^^^^^^ Operandi/MissingPrivateKeyword: Step method `validate` should be private.
            # public - bad
          end

          private

          def process
            # private - good
          end

          def notify
            # private - good
          end
        end
      RUBY
    end

    it "handles public keyword after private" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :validate
          step :process

          private

          def validate
            # private - good
          end

          public

          def process
          ^^^^^^^^^^^ Operandi/MissingPrivateKeyword: Step method `process` should be private.
            # public again - bad
          end
        end
      RUBY
    end
  end

  context "without step methods" do
    it "does not register an offense when there are no steps" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          def process
            # No step defined for this, so it's fine
          end
        end
      RUBY
    end
  end

  context "without class definition" do
    it "does not crash on definitions outside a class" do
      expect_no_offenses(<<~RUBY)
        step :process

        def process
        end
      RUBY
    end
  end
end
