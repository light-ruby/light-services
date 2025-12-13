# frozen_string_literal: true

require "rubocop"
require "rubocop/rspec/support"
require "light/services/rubocop"

RSpec.describe RuboCop::Cop::LightServices::DeprecatedMethods, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  context "when using done! in a service class" do
    it "registers an offense for done!" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :process

          private

          def process
            done!
            ^^^^^ LightServices/DeprecatedMethods: Use `stop!` instead of deprecated `done!`.
          end
        end
      RUBY
    end

    it "registers an offense for self.done!" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :process

          private

          def process
            self.done!
            ^^^^^^^^^^ LightServices/DeprecatedMethods: Use `stop!` instead of deprecated `done!`.
          end
        end
      RUBY
    end

    it "autocorrects done! to stop!" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :process

          private

          def process
            done! if condition_met?
            ^^^^^ LightServices/DeprecatedMethods: Use `stop!` instead of deprecated `done!`.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class MyService < ApplicationService
          step :process

          private

          def process
            stop! if condition_met?
          end
        end
      RUBY
    end

    it "autocorrects self.done! to self.stop!" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :process

          private

          def process
            self.done!
            ^^^^^^^^^^ LightServices/DeprecatedMethods: Use `stop!` instead of deprecated `done!`.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class MyService < ApplicationService
          step :process

          private

          def process
            self.stop!
          end
        end
      RUBY
    end
  end

  context "when using done? in a service class" do
    it "registers an offense for done?" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :process

          private

          def process
            return if done?
                      ^^^^^ LightServices/DeprecatedMethods: Use `stopped?` instead of deprecated `done?`.
          end
        end
      RUBY
    end

    it "registers an offense for self.done?" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :process

          private

          def process
            return if self.done?
                      ^^^^^^^^^^ LightServices/DeprecatedMethods: Use `stopped?` instead of deprecated `done?`.
          end
        end
      RUBY
    end

    it "autocorrects done? to stopped?" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :process

          private

          def process
            return if done?
                      ^^^^^ LightServices/DeprecatedMethods: Use `stopped?` instead of deprecated `done?`.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class MyService < ApplicationService
          step :process

          private

          def process
            return if stopped?
          end
        end
      RUBY
    end

    it "autocorrects self.done? to self.stopped?" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :process

          private

          def process
            return if self.done?
                      ^^^^^^^^^^ LightServices/DeprecatedMethods: Use `stopped?` instead of deprecated `done?`.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class MyService < ApplicationService
          step :process

          private

          def process
            return if self.stopped?
          end
        end
      RUBY
    end
  end

  context "when using both done! and done? in a service class" do
    it "registers offenses for both and autocorrects" do # rubocop:disable RSpec/ExampleLength
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :process

          private

          def process
            done!
            ^^^^^ LightServices/DeprecatedMethods: Use `stop!` instead of deprecated `done!`.
            puts "stopped" if done?
                              ^^^^^ LightServices/DeprecatedMethods: Use `stopped?` instead of deprecated `done?`.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class MyService < ApplicationService
          step :process

          private

          def process
            stop!
            puts "stopped" if stopped?
          end
        end
      RUBY
    end
  end

  context "when inheriting from Light::Services::Base directly" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        class MyService < Light::Services::Base
          step :process

          private

          def process
            done!
            ^^^^^ LightServices/DeprecatedMethods: Use `stop!` instead of deprecated `done!`.
          end
        end
      RUBY
    end
  end

  context "when not in a service class" do
    it "does not register an offense for done! outside a class" do
      expect_no_offenses(<<~RUBY)
        done!
      RUBY
    end

    it "does not register an offense in a non-service class" do
      expect_no_offenses(<<~RUBY)
        class MyClass
          def process
            done!
          end
        end
      RUBY
    end

    it "does not register an offense in a class not matching pattern" do
      expect_no_offenses(<<~RUBY)
        class MyWorker < BaseWorker
          def process
            done!
          end
        end
      RUBY
    end
  end

  context "when done! is called on a different receiver" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          step :process

          private

          def process
            other_object.done!
          end
        end
      RUBY
    end
  end

  context "with custom BaseServiceClasses" do
    let(:config) do
      RuboCop::Config.new(
        "LightServices/DeprecatedMethods" => {
          "BaseServiceClasses" => ["ApplicationService", "BaseCreator"],
        },
      )
    end

    it "detects deprecated methods in classes inheriting from configured base classes" do
      expect_offense(<<~RUBY)
        class User::Create < BaseCreator
          def process
            done!
            ^^^^^ Use `stop!` instead of deprecated `done!`.
          end
        end
      RUBY
    end
  end

  context "when parent class is a method call" do
    let(:config) do
      RuboCop::Config.new(
        "LightServices/DeprecatedMethods" => {
          "BaseServiceClasses" => ["Services.base"],
        },
      )
    end

    it "detects deprecated methods when base class is determined by method call" do
      expect_offense(<<~RUBY)
        class MyService < Services.base
          def process
            done!
            ^^^^^ Use `stop!` instead of deprecated `done!`.
          end
        end
      RUBY
    end

    it "does not register offense when method call does not match configured base classes" do
      expect_no_offenses(<<~RUBY)
        class MyService < Other.base
          def process
            done!
          end
        end
      RUBY
    end
  end

  context "with nested classes" do
    it "only checks the innermost service class" do
      expect_offense(<<~RUBY)
        class OuterService < ApplicationService
          class InnerService < ApplicationService
            def process
              done!
              ^^^^^ LightServices/DeprecatedMethods: Use `stop!` instead of deprecated `done!`.
            end
          end
        end
      RUBY
    end

    it "does not register offense in nested non-service class" do
      expect_no_offenses(<<~RUBY)
        class OuterService < ApplicationService
          class Helper
            def process
              done!
            end
          end
        end
      RUBY
    end
  end
end
