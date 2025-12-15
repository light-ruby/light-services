# frozen_string_literal: true

require "parser/current"

# Mock Solargraph module structure for testing
module Solargraph
  class Location
    attr_reader :filename, :range

    def initialize(filename, range)
      @filename = filename
      @range = range
    end
  end

  class Range
    attr_reader :start, :ending

    def self.from_to(start_line, start_col, end_line, end_col)
      new(
        Position.new(start_line, start_col),
        Position.new(end_line, end_col),
      )
    end

    def initialize(start_pos, end_pos)
      @start = start_pos
      @ending = end_pos
    end
  end

  class Position
    attr_reader :line, :column

    def initialize(line, column)
      @line = line
      @column = column
    end
  end

  class Source
    attr_reader :code, :filename, :node

    def initialize(code:, filename:)
      @code = code
      @filename = filename
      @node = Parser::CurrentRuby.parse(code)
    end
  end

  class Environ
    attr_reader :pins

    def initialize(pins: [])
      @pins = pins
    end
  end

  module Pin
    ROOT_PIN = nil

    class Base
      attr_reader :name, :closure, :location

      def initialize(name:, closure: nil, location: nil)
        @name = name
        @closure = closure
        @location = location
      end
    end

    class Namespace < Base
    end

    class Method < Base
      attr_reader :comments, :scope, :visibility, :parameters

      def initialize(name:, closure: nil, location: nil, comments: nil, scope: :instance, visibility: :public,
                     parameters: [])
        super(name: name, closure: closure, location: location)
        @comments = comments
        @scope = scope
        @visibility = visibility
        @parameters = parameters
      end
    end

    class Parameter
      attr_reader :name, :decl

      def initialize(name:, decl:)
        @name = name
        @decl = decl
      end
    end
  end

  module Convention
    class Base
    end

    def self.register(convention_class)
      @conventions ||= []
      @conventions << convention_class
    end
  end
end

require_relative "../../../lib/solargraph/light_services/type_mapper"
require_relative "../../../lib/solargraph/light_services/convention"

RSpec.describe Solargraph::LightServices::Convention do
  subject(:convention) { described_class.new }

  describe "#local" do
    def create_source(code, filename: "test_service.rb")
      Solargraph::Source.new(code: code, filename: filename)
    end

    def pins_for(code, filename: "test_service.rb")
      source = create_source(code, filename: filename)
      convention.local(source).pins
    end

    context "with a simple service class" do
      let(:code) do
        <<~RUBY
          class TestService < Light::Services::Base
            arg :user, type: User
            arg :options, type: Hash

            output :result, type: String
          end
        RUBY
      end

      it "generates pins for arg declarations" do
        pins = pins_for(code)
        pin_names = pins.map(&:name)

        expect(pin_names).to include("user", "user?", "user=")
        expect(pin_names).to include("options", "options?", "options=")
      end

      it "generates pins for output declarations" do
        pins = pins_for(code)
        pin_names = pins.map(&:name)

        expect(pin_names).to include("result", "result?", "result=")
      end

      it "generates 9 pins total (3 per field)" do
        pins = pins_for(code)
        expect(pins.size).to eq(9)
      end
    end

    context "with namespaced service class" do
      let(:code) do
        <<~RUBY
          module Admin
            class CreateUser < ApplicationService
              arg :name, type: String
              output :user, type: User
            end
          end
        RUBY
      end

      it "generates pins for the namespaced class" do
        pins = pins_for(code)
        pin_names = pins.map(&:name)

        expect(pin_names).to include("name", "name?", "name=")
        expect(pin_names).to include("user", "user?", "user=")
      end
    end

    context "with deeply nested namespace" do
      let(:code) do
        <<~RUBY
          module Api
            module V1
              class UserService < Light::Services::Base
                arg :params, type: Hash
              end
            end
          end
        RUBY
      end

      it "generates pins for the deeply nested class" do
        pins = pins_for(code)
        pin_names = pins.map(&:name)

        expect(pin_names).to include("params", "params?", "params=")
      end
    end

    context "with type information" do
      let(:code) do
        <<~RUBY
          class TestService < Light::Services::Base
            arg :name, type: String
            arg :count, type: Integer
            output :data, type: Hash
          end
        RUBY
      end

      it "includes return type in getter comments" do
        pins = pins_for(code)
        name_getter = pins.find { |p| p.name == "name" }

        expect(name_getter.comments).to include("@return [String]")
      end

      it "includes Boolean return type for predicate methods" do
        pins = pins_for(code)
        name_predicate = pins.find { |p| p.name == "name?" }

        expect(name_predicate.comments).to include("@return [Boolean]")
      end

      it "includes param and return tags for setter" do
        pins = pins_for(code)
        name_setter = pins.find { |p| p.name == "name=" }

        expect(name_setter.comments).to include("@param value [String]")
        expect(name_setter.comments).to include("@return [String]")
      end
    end

    context "with dry-types" do
      let(:code) do
        <<~RUBY
          class TestService < Light::Services::Base
            arg :name, type: Types::Strict::String
            arg :active, type: Types::Bool
            output :items, type: Types::Array
          end
        RUBY
      end

      it "maps dry-types to Ruby types in comments" do
        pins = pins_for(code)

        name_getter = pins.find { |p| p.name == "name" }
        expect(name_getter.comments).to include("@return [String]")

        active_getter = pins.find { |p| p.name == "active" }
        expect(active_getter.comments).to include("@return [Boolean]")

        items_getter = pins.find { |p| p.name == "items" }
        expect(items_getter.comments).to include("@return [Array]")
      end
    end

    context "with setter visibility" do
      let(:code) do
        <<~RUBY
          class TestService < Light::Services::Base
            arg :name, type: String
          end
        RUBY
      end

      it "marks setter as private" do
        pins = pins_for(code)
        setter = pins.find { |p| p.name == "name=" }

        expect(setter.visibility).to eq(:private)
      end

      it "marks getter as public" do
        pins = pins_for(code)
        getter = pins.find { |p| p.name == "name" }

        expect(getter.visibility).to eq(:public)
      end

      it "marks predicate as public" do
        pins = pins_for(code)
        predicate = pins.find { |p| p.name == "name?" }

        expect(predicate.visibility).to eq(:public)
      end
    end

    context "with method scope" do
      let(:code) do
        <<~RUBY
          class TestService < Light::Services::Base
            arg :name, type: String
          end
        RUBY
      end

      it "sets all methods as instance methods" do
        pins = pins_for(code)

        pins.each do |pin|
          expect(pin.scope).to eq(:instance)
        end
      end
    end

    context "when file does not contain Light::Services" do
      let(:code) do
        <<~RUBY
          class RegularClass
            def initialize
            end
          end
        RUBY
      end

      it "returns empty pins" do
        pins = pins_for(code)
        expect(pins).to be_empty
      end
    end

    context "when file contains ApplicationService" do
      let(:code) do
        <<~RUBY
          class MyService < ApplicationService
            arg :data, type: Hash
          end
        RUBY
      end

      it "processes the file" do
        pins = pins_for(code)
        pin_names = pins.map(&:name)

        expect(pin_names).to include("data", "data?", "data=")
      end
    end

    context "with optional arguments" do
      let(:code) do
        <<~RUBY
          class TestService < Light::Services::Base
            arg :name, type: String, optional: true
            arg :count, type: Integer, default: 0
          end
        RUBY
      end

      it "generates pins regardless of optional/default options" do
        pins = pins_for(code)
        pin_names = pins.map(&:name)

        expect(pin_names).to include("name", "name?", "name=")
        expect(pin_names).to include("count", "count?", "count=")
      end
    end

    context "with context arguments" do
      let(:code) do
        <<~RUBY
          class TestService < Light::Services::Base
            arg :current_user, type: User, context: true
          end
        RUBY
      end

      it "generates pins for context arguments" do
        pins = pins_for(code)
        pin_names = pins.map(&:name)

        expect(pin_names).to include("current_user", "current_user?", "current_user=")
      end
    end

    context "with array type syntax" do
      let(:code) do
        <<~RUBY
          class TestService < Light::Services::Base
            arg :ids, type: [String, Integer]
          end
        RUBY
      end

      it "generates pins even with array type" do
        pins = pins_for(code)
        pin_names = pins.map(&:name)

        expect(pin_names).to include("ids", "ids?", "ids=")
      end
    end

    context "with parameterized dry-types" do
      let(:code) do
        <<~RUBY
          class TestService < Light::Services::Base
            arg :tags, type: Types::Array.of(Types::String)
            arg :email, type: Types::String.constrained(format: /@/)
          end
        RUBY
      end

      it "extracts base type from parameterized types" do
        pins = pins_for(code)

        tags_getter = pins.find { |p| p.name == "tags" }
        expect(tags_getter.comments).to include("@return [Array]")

        email_getter = pins.find { |p| p.name == "email" }
        expect(email_getter.comments).to include("@return [String]")
      end
    end

    context "with setter parameters" do
      let(:code) do
        <<~RUBY
          class TestService < Light::Services::Base
            arg :name, type: String
          end
        RUBY
      end

      it "includes value parameter for setter" do
        pins = pins_for(code)
        setter = pins.find { |p| p.name == "name=" }

        expect(setter.parameters.size).to eq(1)
        expect(setter.parameters.first.name).to eq("value")
      end
    end
  end
end

