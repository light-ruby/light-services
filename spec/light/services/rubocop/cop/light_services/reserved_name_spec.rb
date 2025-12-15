# frozen_string_literal: true

require "rubocop"
require "rubocop/rspec/support"
require "light/services/rubocop"

RSpec.describe RuboCop::Cop::LightServices::ReservedName, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  describe "reserved argument names" do
    it "registers an offense for :errors" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :errors, type: Array
          ^^^^^^^^^^^^^^^^^^^^^^^^ LightServices/ReservedName: `errors` is a reserved name and cannot be used as an argument. It conflicts with Light::Services methods.
        end
      RUBY
    end

    it "registers an offense for :outputs" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :outputs, type: Hash
          ^^^^^^^^^^^^^^^^^^^^^^^^ LightServices/ReservedName: `outputs` is a reserved name and cannot be used as an argument. It conflicts with Light::Services methods.
        end
      RUBY
    end

    it "registers an offense for :success?" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :success?, type: [TrueClass, FalseClass]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ LightServices/ReservedName: `success?` is a reserved name and cannot be used as an argument. It conflicts with Light::Services methods.
        end
      RUBY
    end

    it "registers an offense for :initialize" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :initialize, type: Proc
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^ LightServices/ReservedName: `initialize` is a reserved name and cannot be used as an argument. It conflicts with Light::Services methods.
        end
      RUBY
    end
  end

  describe "reserved step names" do
    it "registers an offense for :call" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :call
          ^^^^^^^^^^ LightServices/ReservedName: `call` is a reserved name and cannot be used as a step. It conflicts with Light::Services methods.
        end
      RUBY
    end

    it "registers an offense for :initialize" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :initialize
          ^^^^^^^^^^^^^^^^ LightServices/ReservedName: `initialize` is a reserved name and cannot be used as a step. It conflicts with Light::Services methods.
        end
      RUBY
    end

    it "registers an offense for :before_step_run" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :before_step_run
          ^^^^^^^^^^^^^^^^^^^^^ LightServices/ReservedName: `before_step_run` is a reserved name and cannot be used as a step. It conflicts with Light::Services methods.
        end
      RUBY
    end

    it "registers an offense for :stop!" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :stop!
          ^^^^^^^^^^^ LightServices/ReservedName: `stop!` is a reserved name and cannot be used as a step. It conflicts with Light::Services methods.
        end
      RUBY
    end
  end

  describe "reserved output names" do
    it "registers an offense for :success?" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          output :success?, type: [TrueClass, FalseClass]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ LightServices/ReservedName: `success?` is a reserved name and cannot be used as an output. It conflicts with Light::Services methods.
        end
      RUBY
    end

    it "registers an offense for :warnings" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          output :warnings, type: Array
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ LightServices/ReservedName: `warnings` is a reserved name and cannot be used as an output. It conflicts with Light::Services methods.
        end
      RUBY
    end

    it "registers an offense for :errors" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          output :errors, type: Array
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^ LightServices/ReservedName: `errors` is a reserved name and cannot be used as an output. It conflicts with Light::Services methods.
        end
      RUBY
    end

    it "registers an offense for :failed?" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          output :failed?, type: [TrueClass, FalseClass]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ LightServices/ReservedName: `failed?` is a reserved name and cannot be used as an output. It conflicts with Light::Services methods.
        end
      RUBY
    end
  end

  describe "valid non-reserved names" do
    it "does not register an offense for non-reserved argument names" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          arg :user_id, type: Integer
          arg :params, type: Hash
          arg :validation_errors, type: Array
        end
      RUBY
    end

    it "does not register an offense for non-reserved step names" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          step :validate
          step :process
          step :execute
        end
      RUBY
    end

    it "does not register an offense for non-reserved output names" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          output :result, type: Hash
          output :user, type: User
          output :succeeded, type: [TrueClass, FalseClass]
        end
      RUBY
    end
  end

  describe "edge cases" do
    it "handles multiple DSL calls with mixed reserved and valid names" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :user_id, type: Integer
          arg :errors, type: Array
          ^^^^^^^^^^^^^^^^^^^^^^^^ LightServices/ReservedName: `errors` is a reserved name and cannot be used as an argument. It conflicts with Light::Services methods.
          step :validate
          step :call
          ^^^^^^^^^^ LightServices/ReservedName: `call` is a reserved name and cannot be used as a step. It conflicts with Light::Services methods.
          output :result, type: Hash
          output :success?, type: [TrueClass, FalseClass]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ LightServices/ReservedName: `success?` is a reserved name and cannot be used as an output. It conflicts with Light::Services methods.
        end
      RUBY
    end
  end
end
