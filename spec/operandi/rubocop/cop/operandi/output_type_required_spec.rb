# frozen_string_literal: true

require "rubocop"
require "rubocop/rspec/support"
require "operandi/rubocop"

RSpec.describe RuboCop::Cop::Operandi::OutputTypeRequired, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  context "when output has no options" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          output :result
          ^^^^^^^^^^^^^^ Operandi/OutputTypeRequired: Output `result` must have a `type:` option.
        end
      RUBY
    end
  end

  context "when output has options but no type" do
    it "registers an offense for default option only" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          output :data, default: {}
          ^^^^^^^^^^^^^^^^^^^^^^^^^ Operandi/OutputTypeRequired: Output `data` must have a `type:` option.
        end
      RUBY
    end

    it "registers an offense for optional option only" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          output :metadata, optional: true
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Operandi/OutputTypeRequired: Output `metadata` must have a `type:` option.
        end
      RUBY
    end

    it "registers an offense for multiple options without type" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          output :count, optional: true, default: 0
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Operandi/OutputTypeRequired: Output `count` must have a `type:` option.
        end
      RUBY
    end
  end

  context "when output has type option" do
    it "does not register an offense for type only" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          output :result, type: Hash
        end
      RUBY
    end

    it "does not register an offense for type with other options" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          output :data, type: Hash, default: {}
        end
      RUBY
    end

    it "does not register an offense for type with optional" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          output :metadata, type: Hash, optional: true
        end
      RUBY
    end

    it "does not register an offense for array type" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          output :items, type: [Array, Hash]
        end
      RUBY
    end
  end
end
