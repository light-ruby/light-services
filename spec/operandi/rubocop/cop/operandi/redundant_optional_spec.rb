# frozen_string_literal: true

require "rubocop"
require "rubocop/rspec/support"
require "operandi/rubocop"

RSpec.describe RuboCop::Cop::Operandi::RedundantOptional, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  context "when arg has both optional: true and default:" do
    it "registers an offense and corrects" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :name, type: String, optional: true, default: "guest"
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Operandi/RedundantOptional: `optional: true` is redundant when `default:` is specified for `name`.
        end
      RUBY

      expect_correction(<<~RUBY)
        class MyService < ApplicationService
          arg :name, type: String, default: "guest"
        end
      RUBY
    end

    it "corrects when optional is first" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :count, optional: true, type: Integer, default: 0
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Operandi/RedundantOptional: `optional: true` is redundant when `default:` is specified for `count`.
        end
      RUBY

      expect_correction(<<~RUBY)
        class MyService < ApplicationService
          arg :count, type: Integer, default: 0
        end
      RUBY
    end

    it "corrects when default is in the middle" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :status, type: String, default: "pending", optional: true
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Operandi/RedundantOptional: `optional: true` is redundant when `default:` is specified for `status`.
        end
      RUBY

      expect_correction(<<~RUBY)
        class MyService < ApplicationService
          arg :status, type: String, default: "pending"
        end
      RUBY
    end
  end

  context "when output has both optional: true and default:" do
    it "registers an offense and corrects" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          output :count, type: Integer, optional: true, default: 0
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Operandi/RedundantOptional: `optional: true` is redundant when `default:` is specified for `count`.
        end
      RUBY

      expect_correction(<<~RUBY)
        class MyService < ApplicationService
          output :count, type: Integer, default: 0
        end
      RUBY
    end

    it "corrects when optional is first" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          output :result, optional: true, type: Hash, default: {}
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Operandi/RedundantOptional: `optional: true` is redundant when `default:` is specified for `result`.
        end
      RUBY

      expect_correction(<<~RUBY)
        class MyService < ApplicationService
          output :result, type: Hash, default: {}
        end
      RUBY
    end
  end

  context "when arg has only optional: true (no default)" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          arg :name, type: String, optional: true
        end
      RUBY
    end
  end

  context "when arg has only default: (no optional)" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          arg :name, type: String, default: "guest"
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

  context "when output has only default: (no optional)" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          output :count, type: Integer, default: 0
        end
      RUBY
    end
  end

  context "when optional: false is used with default:" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          arg :name, type: String, optional: false, default: "guest"
        end
      RUBY
    end
  end

  context "when optional: Rails.env.production? is used with default:" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          arg :name, type: String, optional: Rails.env.production?, default: "guest"
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
end
