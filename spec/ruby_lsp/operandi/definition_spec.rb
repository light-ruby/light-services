# frozen_string_literal: true

require "prism"

# Mock modules for testing without ruby-lsp dependency
module Interface
  Location = Struct.new(:uri, :range, keyword_init: true)
  Range = Struct.new(:start, :end, keyword_init: true)
  Position = Struct.new(:line, :character, keyword_init: true)
end

module URI
  class Generic
    def self.from_path(path:)
      new(path)
    end

    def initialize(path)
      @path = path
    end

    def to_s
      "file://#{@path}"
    end
  end
end

# Mock entry for method definitions
class MockMethodEntry
  attr_reader :file_path, :location

  def initialize(file_path:, start_line:, end_line:, start_column:, end_column:)
    @file_path = file_path
    @location = MockLocation.new(start_line, end_line, start_column, end_column)
  end

  MockLocation = Struct.new(:start_line, :end_line, :start_column, :end_column)
end

# Mock classes for verified doubles
MockDispatcher = Class.new do
  def register(*); end
end

MockIndex = Class.new do
  def resolve_method(*); end
end

MockNodeContext = Class.new do
  attr_accessor :nesting, :node, :call_node
end

require_relative "../../../lib/ruby_lsp/operandi/definition"

RSpec.describe RubyLsp::Operandi::Definition do
  subject(:definition) do
    described_class.new(response_builder, uri, node_context, index, dispatcher)
  end

  let(:response_builder) { [] }
  let(:uri) { "file:///test/service.rb" }
  let(:dispatcher) { instance_double(MockDispatcher) }
  let(:index) { instance_double(MockIndex) }

  # Parse source and extract the symbol node at the expected position
  let(:parsed) { Prism.parse(source) }
  let(:call_node) { parsed.value.statements.body.first }

  let(:node_context) do
    instance_double(
      MockNodeContext,
      nesting: ["MyService"],
      node: symbol_node,
      call_node: call_node,
    )
  end

  before do
    allow(dispatcher).to receive(:register)
  end

  describe "#initialize" do
    let(:source) { "step :validate" }
    let(:symbol_node) { call_node.arguments.arguments.first }

    it "registers for on_symbol_node_enter events" do
      definition

      expect(dispatcher).to have_received(:register).with(definition, :on_symbol_node_enter)
    end
  end

  describe "#on_symbol_node_enter" do
    context "when clicking on step method name" do
      let(:source) { "step :validate" }
      let(:symbol_node) { call_node.arguments.arguments.first }
      let(:method_entry) do
        MockMethodEntry.new(
          file_path: "/test/service.rb",
          start_line: 10,
          end_line: 12,
          start_column: 2,
          end_column: 5,
        )
      end

      before do
        allow(index).to receive(:resolve_method)
          .with("validate", "MyService")
          .and_return([method_entry])
      end

      it "finds the step method and appends location to response" do
        definition.on_symbol_node_enter(symbol_node)

        expect(response_builder.size).to eq(1)
        location = response_builder.first
        expect(location.uri).to eq("file:///test/service.rb")
        expect(location.range.start.line).to eq(9) # 0-indexed
        expect(location.range.start.character).to eq(2)
      end
    end

    context "when clicking on if condition symbol" do
      let(:source) { "step :validate, if: :should_validate?" }
      # Symbol node for :should_validate?
      let(:symbol_node) do
        keyword_hash = call_node.arguments.arguments.last
        keyword_hash.elements.first.value
      end

      let(:method_entry) do
        MockMethodEntry.new(
          file_path: "/test/service.rb",
          start_line: 20,
          end_line: 22,
          start_column: 2,
          end_column: 5,
        )
      end

      before do
        allow(index).to receive(:resolve_method)
          .with("should_validate?", "MyService")
          .and_return([method_entry])
      end

      it "finds the condition method and appends location to response" do
        definition.on_symbol_node_enter(symbol_node)

        expect(response_builder.size).to eq(1)
        location = response_builder.first
        expect(location.uri).to eq("file:///test/service.rb")
        expect(location.range.start.line).to eq(19) # 0-indexed
      end
    end

    context "when clicking on unless condition symbol" do
      let(:source) { "step :process, unless: :skip_processing?" }
      let(:symbol_node) do
        keyword_hash = call_node.arguments.arguments.last
        keyword_hash.elements.first.value
      end

      let(:method_entry) do
        MockMethodEntry.new(
          file_path: "/test/service.rb",
          start_line: 30,
          end_line: 32,
          start_column: 2,
          end_column: 5,
        )
      end

      before do
        allow(index).to receive(:resolve_method)
          .with("skip_processing?", "MyService")
          .and_return([method_entry])
      end

      it "finds the unless condition method and appends location to response" do
        definition.on_symbol_node_enter(symbol_node)

        expect(response_builder.size).to eq(1)
        location = response_builder.first
        expect(location.range.start.line).to eq(29) # 0-indexed
      end
    end

    context "when call_node is not a step call" do
      let(:source) { "arg :name, type: String" }
      let(:symbol_node) { call_node.arguments.arguments.first }

      it "does not append any location" do
        definition.on_symbol_node_enter(symbol_node)

        expect(response_builder).to be_empty
      end
    end

    context "when call_node is nil (symbol outside of call)" do
      let(:source) { "step :validate" }
      let(:symbol_node) { call_node.arguments.arguments.first }
      let(:node_context) do
        instance_double(
          MockNodeContext,
          nesting: ["MyService"],
          node: symbol_node,
          call_node: nil,
        )
      end

      it "does not append any location" do
        definition.on_symbol_node_enter(symbol_node)

        expect(response_builder).to be_empty
      end
    end

    context "when method is not found in index" do
      let(:source) { "step :unknown_method" }
      let(:symbol_node) { call_node.arguments.arguments.first }

      before do
        allow(index).to receive(:resolve_method)
          .with("unknown_method", "MyService")
          .and_return(nil)
      end

      it "does not append any location" do
        definition.on_symbol_node_enter(symbol_node)

        expect(response_builder).to be_empty
      end
    end

    context "when nesting is empty" do
      let(:source) { "step :validate" }
      let(:symbol_node) { call_node.arguments.arguments.first }
      let(:node_context) do
        instance_double(
          MockNodeContext,
          nesting: [],
          node: symbol_node,
          call_node: call_node,
        )
      end

      it "does not append any location" do
        definition.on_symbol_node_enter(symbol_node)

        expect(response_builder).to be_empty
      end
    end

    context "when clicking on non-condition keyword option" do
      let(:source) { "step :validate, always: :some_method" }
      # Symbol value for always: option (not if/unless)
      let(:symbol_node) do
        keyword_hash = call_node.arguments.arguments.last
        keyword_hash.elements.first.value
      end

      it "does not append any location (only if/unless are supported)" do
        definition.on_symbol_node_enter(symbol_node)

        expect(response_builder).to be_empty
      end
    end

    context "with nested class nesting" do
      let(:source) { "step :validate" }
      let(:symbol_node) { call_node.arguments.arguments.first }
      let(:node_context) do
        instance_double(
          MockNodeContext,
          nesting: ["MyModule", "MyService"],
          node: symbol_node,
          call_node: call_node,
        )
      end

      let(:method_entry) do
        MockMethodEntry.new(
          file_path: "/test/service.rb",
          start_line: 10,
          end_line: 12,
          start_column: 2,
          end_column: 5,
        )
      end

      before do
        allow(index).to receive(:resolve_method)
          .with("validate", "MyModule::MyService")
          .and_return([method_entry])
      end

      it "uses the full nesting path to resolve method" do
        definition.on_symbol_node_enter(symbol_node)

        expect(response_builder.size).to eq(1)
        expect(index).to have_received(:resolve_method).with("validate", "MyModule::MyService")
      end
    end

    context "when multiple method entries exist" do
      let(:source) { "step :validate" }
      let(:symbol_node) { call_node.arguments.arguments.first }
      let(:method_entries) do
        [
          MockMethodEntry.new(
            file_path: "/test/service.rb",
            start_line: 10,
            end_line: 12,
            start_column: 2,
            end_column: 5,
          ),
          MockMethodEntry.new(
            file_path: "/test/base_service.rb",
            start_line: 5,
            end_line: 7,
            start_column: 2,
            end_column: 5,
          ),
        ]
      end

      before do
        allow(index).to receive(:resolve_method)
          .with("validate", "MyService")
          .and_return(method_entries)
      end

      it "appends all method locations to response" do
        definition.on_symbol_node_enter(symbol_node)

        expect(response_builder.size).to eq(2)
      end
    end
  end
end
