# frozen_string_literal: true

require "rubocop"
require "rubocop/rspec/support"
require "operandi/rubocop"

RSpec.describe RuboCop::Cop::Operandi::NoDirectInstantiation, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  context "with default ServicePattern (Service$)" do
    it "registers an offense for .new on Service class" do
      expect_offense(<<~RUBY)
        UserService.new(name: "John")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Operandi/NoDirectInstantiation: Use `.run`, `.run!`, or `.call` instead of `.new` for service classes.
      RUBY
    end

    it "registers an offense for .new on namespaced Service class" do
      expect_offense(<<~RUBY)
        User::CreateService.new(params: {})
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Operandi/NoDirectInstantiation: Use `.run`, `.run!`, or `.call` instead of `.new` for service classes.
      RUBY
    end

    it "registers an offense for .new without arguments" do
      expect_offense(<<~RUBY)
        MyService.new
        ^^^^^^^^^^^^^ Operandi/NoDirectInstantiation: Use `.run`, `.run!`, or `.call` instead of `.new` for service classes.
      RUBY
    end

    it "does not register an offense for .run" do
      expect_no_offenses(<<~RUBY)
        UserService.run(name: "John")
      RUBY
    end

    it "does not register an offense for .run!" do
      expect_no_offenses(<<~RUBY)
        UserService.run!(name: "John")
      RUBY
    end

    it "does not register an offense for .call" do
      expect_no_offenses(<<~RUBY)
        UserService.call(name: "John")
      RUBY
    end

    it "does not register an offense for non-service classes" do
      expect_no_offenses(<<~RUBY)
        User.new(name: "John")
        Hash.new
        Array.new(5)
        OpenStruct.new(foo: "bar")
      RUBY
    end

    it "does not register an offense for classes not matching pattern" do
      expect_no_offenses(<<~RUBY)
        UserCreator.new(name: "John")
        UserBuilder.new(name: "John")
      RUBY
    end
  end

  context "with custom ServicePattern" do
    let(:config) do
      RuboCop::Config.new(
        "Operandi/NoDirectInstantiation" => {
          "ServicePattern" => "(Service|Creator|Interactor)$",
        },
      )
    end

    it "registers an offense for Service class" do
      expect_offense(<<~RUBY)
        UserService.new
        ^^^^^^^^^^^^^^^ Use `.run`, `.run!`, or `.call` instead of `.new` for service classes.
      RUBY
    end

    it "registers an offense for Creator class" do
      expect_offense(<<~RUBY)
        UserCreator.new
        ^^^^^^^^^^^^^^^ Use `.run`, `.run!`, or `.call` instead of `.new` for service classes.
      RUBY
    end

    it "registers an offense for Interactor class" do
      expect_offense(<<~RUBY)
        CreateUserInteractor.new
        ^^^^^^^^^^^^^^^^^^^^^^^^ Use `.run`, `.run!`, or `.call` instead of `.new` for service classes.
      RUBY
    end

    it "does not register an offense for non-matching classes" do
      expect_no_offenses(<<~RUBY)
        UserBuilder.new
        UserFactory.new
      RUBY
    end
  end

  context "with pattern matching any class" do
    let(:config) do
      RuboCop::Config.new(
        "Operandi/NoDirectInstantiation" => {
          "ServicePattern" => ".*",
        },
      )
    end

    it "registers an offense for any class" do
      expect_offense(<<~RUBY)
        User.new
        ^^^^^^^^ Use `.run`, `.run!`, or `.call` instead of `.new` for service classes.
      RUBY
    end
  end

  context "when .new is called on a method result" do
    let(:config) do
      RuboCop::Config.new(
        "Operandi/NoDirectInstantiation" => {
          "ServicePattern" => "service$",
        },
      )
    end

    it "registers an offense when method result name matches pattern" do
      expect_offense(<<~RUBY)
        user_service.new(name: "John")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `.run`, `.run!`, or `.call` instead of `.new` for service classes.
      RUBY
    end

    it "does not register an offense when method name does not match pattern" do
      expect_no_offenses(<<~RUBY)
        get_user_creator.new(name: "John")
      RUBY
    end

    it "handles chained method calls matching pattern" do
      expect_offense(<<~RUBY)
        factory.user_service.new
        ^^^^^^^^^^^^^^^^^^^^^^^^ Use `.run`, `.run!`, or `.call` instead of `.new` for service classes.
      RUBY
    end
  end
end
