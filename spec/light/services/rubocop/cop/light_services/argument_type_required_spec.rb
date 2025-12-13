# frozen_string_literal: true

require "rubocop"
require "rubocop/rspec/support"
require "light/services/rubocop"

RSpec.describe RuboCop::Cop::LightServices::ArgumentTypeRequired, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  context "when arg has no options" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :user_id
          ^^^^^^^^^^^^ LightServices/ArgumentTypeRequired: Argument `user_id` must have a `type:` option.
        end
      RUBY
    end
  end

  context "when arg has options but no type" do
    it "registers an offense for default option only" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :params, default: {}
          ^^^^^^^^^^^^^^^^^^^^^^^^ LightServices/ArgumentTypeRequired: Argument `params` must have a `type:` option.
        end
      RUBY
    end

    it "registers an offense for optional option only" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :name, optional: true
          ^^^^^^^^^^^^^^^^^^^^^^^^^ LightServices/ArgumentTypeRequired: Argument `name` must have a `type:` option.
        end
      RUBY
    end

    it "registers an offense for context option only" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :current_user, context: true
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ LightServices/ArgumentTypeRequired: Argument `current_user` must have a `type:` option.
        end
      RUBY
    end

    it "registers an offense for multiple options without type" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :status, optional: true, default: "pending"
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ LightServices/ArgumentTypeRequired: Argument `status` must have a `type:` option.
        end
      RUBY
    end
  end

  context "when arg has type option" do
    it "does not register an offense for type only" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          arg :user_id, type: Integer
        end
      RUBY
    end

    it "does not register an offense for type with other options" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          arg :params, type: Hash, default: {}
        end
      RUBY
    end

    it "does not register an offense for type with optional" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          arg :name, type: String, optional: true
        end
      RUBY
    end

    it "does not register an offense for type with context" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          arg :current_user, type: User, context: true
        end
      RUBY
    end

    it "does not register an offense for array type" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          arg :id, type: [String, Integer]
        end
      RUBY
    end
  end
end
