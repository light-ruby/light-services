# frozen_string_literal: true

require "rubocop"
require "rubocop/rspec/support"
require "operandi/rubocop"

RSpec.describe RuboCop::Cop::Operandi::PreferOptionalOverDefaultNil, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  context "when arg has default: nil without optional: true" do
    it "registers an offense and corrects" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :user, type: User, default: nil
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Operandi/PreferOptionalOverDefaultNil: Prefer `optional: true` over `default: nil` for `user`.
        end
      RUBY

      expect_correction(<<~RUBY)
        class MyService < ApplicationService
          arg :user, type: User, optional: true
        end
      RUBY
    end

    it "corrects when default: nil is first option" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :user, default: nil, type: User
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Operandi/PreferOptionalOverDefaultNil: Prefer `optional: true` over `default: nil` for `user`.
        end
      RUBY

      expect_correction(<<~RUBY)
        class MyService < ApplicationService
          arg :user, optional: true, type: User
        end
      RUBY
    end

    it "corrects when default: nil is in the middle" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :user, type: User, default: nil, desc: "The user"
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Operandi/PreferOptionalOverDefaultNil: Prefer `optional: true` over `default: nil` for `user`.
        end
      RUBY

      expect_correction(<<~RUBY)
        class MyService < ApplicationService
          arg :user, type: User, optional: true, desc: "The user"
        end
      RUBY
    end
  end

  context "when output has default: nil without optional: true" do
    it "registers an offense and corrects" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          output :result, type: Hash, default: nil
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Operandi/PreferOptionalOverDefaultNil: Prefer `optional: true` over `default: nil` for `result`.
        end
      RUBY

      expect_correction(<<~RUBY)
        class MyService < ApplicationService
          output :result, type: Hash, optional: true
        end
      RUBY
    end
  end

  context "when arg has both optional: true and default: nil" do
    it "registers an offense and removes default: nil" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :user, type: User, optional: true, default: nil
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Operandi/PreferOptionalOverDefaultNil: `default: nil` is redundant when `optional: true` is specified for `user`.
        end
      RUBY

      expect_correction(<<~RUBY)
        class MyService < ApplicationService
          arg :user, type: User, optional: true
        end
      RUBY
    end

    it "corrects when default: nil comes before optional: true" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :user, type: User, default: nil, optional: true
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Operandi/PreferOptionalOverDefaultNil: `default: nil` is redundant when `optional: true` is specified for `user`.
        end
      RUBY

      expect_correction(<<~RUBY)
        class MyService < ApplicationService
          arg :user, type: User, optional: true
        end
      RUBY
    end

    it "corrects when both are in the middle" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :user, optional: true, type: User, default: nil, desc: "User"
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Operandi/PreferOptionalOverDefaultNil: `default: nil` is redundant when `optional: true` is specified for `user`.
        end
      RUBY

      expect_correction(<<~RUBY)
        class MyService < ApplicationService
          arg :user, optional: true, type: User, desc: "User"
        end
      RUBY
    end
  end

  context "when output has both optional: true and default: nil" do
    it "registers an offense and removes default: nil" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          output :result, type: Hash, optional: true, default: nil
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Operandi/PreferOptionalOverDefaultNil: `default: nil` is redundant when `optional: true` is specified for `result`.
        end
      RUBY

      expect_correction(<<~RUBY)
        class MyService < ApplicationService
          output :result, type: Hash, optional: true
        end
      RUBY
    end
  end

  context "when default is not nil" do
    it "does not register an offense for arg with non-nil default" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          arg :name, type: String, default: "guest"
        end
      RUBY
    end

    it "does not register an offense for output with non-nil default" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          output :count, type: Integer, default: 0
        end
      RUBY
    end
  end

  context "when arg has only optional: true (no default)" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          arg :user, type: User, optional: true
        end
      RUBY
    end
  end

  context "when output has only optional: true (no default)" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          output :result, type: Hash, optional: true
        end
      RUBY
    end
  end

  context "when arg has no options" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          arg :name
        end
      RUBY
    end
  end

  context "when arg has only type option" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          arg :name, type: String
        end
      RUBY
    end
  end
end
