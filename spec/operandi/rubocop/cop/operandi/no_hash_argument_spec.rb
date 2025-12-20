# frozen_string_literal: true

require "rubocop"
require "rubocop/rspec/support"
require "operandi/rubocop"

RSpec.describe RuboCop::Cop::Operandi::NoHashArgument, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) do
    RuboCop::Config.new(
      "Operandi/NoHashArgument" => { "Enabled" => true },
    )
  end

  context "with .run method" do
    it "registers an offense for single variable argument" do
      expect_offense(<<~RUBY)
        UserService.run(args)
        ^^^^^^^^^^^^^^^^^^^^^ Use keyword arguments or `**` splat instead of hash argument for `.run`.
      RUBY
    end

    it "registers an offense for hash merge expression" do
      expect_offense(<<~RUBY)
        UserService.run(args.merge(new: true))
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use keyword arguments or `**` splat instead of hash argument for `.run`.
      RUBY
    end

    it "registers an offense for explicit hash literal" do
      expect_offense(<<~RUBY)
        UserService.run({ name: "John" })
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use keyword arguments or `**` splat instead of hash argument for `.run`.
      RUBY
    end

    it "registers an offense for method call returning hash" do
      expect_offense(<<~RUBY)
        UserService.run(build_params)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use keyword arguments or `**` splat instead of hash argument for `.run`.
      RUBY
    end

    it "registers an offense for instance variable" do
      expect_offense(<<~RUBY)
        UserService.run(@params)
        ^^^^^^^^^^^^^^^^^^^^^^^^ Use keyword arguments or `**` splat instead of hash argument for `.run`.
      RUBY
    end

    it "does not register an offense for keyword arguments" do
      expect_no_offenses(<<~RUBY)
        UserService.run(name: "John", age: 25)
      RUBY
    end

    it "does not register an offense for keyword splat" do
      expect_no_offenses(<<~RUBY)
        UserService.run(**args)
      RUBY
    end

    it "does not register an offense for keyword splat with merge" do
      expect_no_offenses(<<~RUBY)
        UserService.run(**args.merge(new: true))
      RUBY
    end

    it "does not register an offense for keyword splat with additional kwargs" do
      expect_no_offenses(<<~RUBY)
        UserService.run(**args, new: true)
      RUBY
    end

    it "does not register an offense for no arguments" do
      expect_no_offenses(<<~RUBY)
        UserService.run
      RUBY
    end

    it "does not register an offense for empty parentheses" do
      expect_no_offenses(<<~RUBY)
        UserService.run()
      RUBY
    end

    it "does not register an offense for block pass" do
      expect_no_offenses(<<~RUBY)
        UserService.run(name: "John", &block)
      RUBY
    end
  end

  context "with .run! method" do
    it "registers an offense for single variable argument" do
      expect_offense(<<~RUBY)
        UserService.run!(args)
        ^^^^^^^^^^^^^^^^^^^^^^ Use keyword arguments or `**` splat instead of hash argument for `.run!`.
      RUBY
    end

    it "registers an offense for hash merge expression" do
      expect_offense(<<~RUBY)
        UserService.run!(args.merge(new: true))
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use keyword arguments or `**` splat instead of hash argument for `.run!`.
      RUBY
    end

    it "does not register an offense for keyword arguments" do
      expect_no_offenses(<<~RUBY)
        UserService.run!(name: "John")
      RUBY
    end

    it "does not register an offense for keyword splat" do
      expect_no_offenses(<<~RUBY)
        UserService.run!(**args)
      RUBY
    end
  end

  context "with namespaced classes" do
    it "registers an offense for namespaced class with Service suffix" do
      expect_offense(<<~RUBY)
        User::CreateService.run(params)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use keyword arguments or `**` splat instead of hash argument for `.run`.
      RUBY
    end

    it "registers an offense for namespaced class without Service suffix" do
      expect_offense(<<~RUBY)
        Auth::SignIn.run(params)
        ^^^^^^^^^^^^^^^^^^^^^^^^ Use keyword arguments or `**` splat instead of hash argument for `.run`.
      RUBY
    end

    it "registers an offense for deeply namespaced class" do
      expect_offense(<<~RUBY)
        Auth::RequestResetPassword.run(service_args)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use keyword arguments or `**` splat instead of hash argument for `.run`.
      RUBY
    end
  end

  context "with default pattern (checks all classes)" do
    it "registers an offense for any class" do
      expect_offense(<<~RUBY)
        UserCreator.run(args)
        ^^^^^^^^^^^^^^^^^^^^^ Use keyword arguments or `**` splat instead of hash argument for `.run`.
      RUBY
    end

    it "registers an offense for method call argument" do
      expect_offense(<<~RUBY)
        Auth::SignInWithCode.run(service_args(code_id: params[:code_id]))
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use keyword arguments or `**` splat instead of hash argument for `.run`.
      RUBY
    end
  end

  context "with custom ServicePattern to restrict checks" do
    let(:config) do
      RuboCop::Config.new(
        "Operandi/NoHashArgument" => {
          "ServicePattern" => "(Service|Creator|Interactor)$",
        },
      )
    end

    it "registers an offense for Service class" do
      expect_offense(<<~RUBY)
        UserService.run(args)
        ^^^^^^^^^^^^^^^^^^^^^ Use keyword arguments or `**` splat instead of hash argument for `.run`.
      RUBY
    end

    it "registers an offense for Creator class" do
      expect_offense(<<~RUBY)
        UserCreator.run(args)
        ^^^^^^^^^^^^^^^^^^^^^ Use keyword arguments or `**` splat instead of hash argument for `.run`.
      RUBY
    end

    it "registers an offense for Interactor class" do
      expect_offense(<<~RUBY)
        CreateUserInteractor.run(args)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use keyword arguments or `**` splat instead of hash argument for `.run`.
      RUBY
    end

    it "does not register an offense for non-matching classes" do
      expect_no_offenses(<<~RUBY)
        UserBuilder.run(args)
        UserFactory.run(args)
        Auth::SignIn.run(args)
      RUBY
    end
  end

  context "with mixed valid and invalid arguments" do
    it "registers an offense when hash argument is mixed with kwargs" do
      expect_offense(<<~RUBY)
        UserService.run(args, extra: true)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use keyword arguments or `**` splat instead of hash argument for `.run`.
      RUBY
    end
  end
end
