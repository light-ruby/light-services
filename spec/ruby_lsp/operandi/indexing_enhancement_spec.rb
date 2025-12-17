# frozen_string_literal: true

require "prism"

# Mock RubyIndexer module for testing without ruby-lsp dependency
module RubyIndexer
  class Enhancement
    attr_reader :listener

    # In ruby-lsp 0.26+, Enhancement takes listener in initialize
    def initialize(listener)
      @listener = listener
    end
  end

  module Entry
    class Signature
      attr_reader :parameters

      def initialize(parameters)
        @parameters = parameters
      end
    end

    class RequiredParameter
      attr_reader :name

      def initialize(name:)
        @name = name
      end
    end
  end
end

require_relative "../../../lib/ruby_lsp/operandi/indexing_enhancement"

RSpec.describe RubyLsp::Operandi::IndexingEnhancement do
  # In ruby-lsp 0.26+, Enhancement is instantiated with the listener
  subject(:enhancement) { described_class.new(listener) }

  let(:listener) do
    instance_double(
      RubyIndexer::DeclarationListener,
      current_owner: "TestService",
      add_method: nil,
    )
  end

  before do
    # Define a mock class for the double reference
    stub_const("RubyIndexer::DeclarationListener", Class.new)
    allow(listener).to receive(:is_a?).and_return(true)
  end

  describe "#on_call_node_enter" do
    context "when processing an arg declaration" do
      let(:source) { "arg :name, type: String" }
      let(:node) { Prism.parse(source).value.statements.body.first }

      it "registers the getter method" do
        enhancement.on_call_node_enter(node)

        expect(listener).to have_received(:add_method).with(
          "name",
          anything,
          array_including(an_instance_of(RubyIndexer::Entry::Signature)),
          comments: anything,
        )
      end

      it "registers the predicate method" do
        enhancement.on_call_node_enter(node)

        expect(listener).to have_received(:add_method).with(
          "name?",
          anything,
          array_including(an_instance_of(RubyIndexer::Entry::Signature)),
          comments: anything,
        )
      end

      it "registers the setter method" do
        enhancement.on_call_node_enter(node)

        expect(listener).to have_received(:add_method).with(
          "name=",
          anything,
          array_including(an_instance_of(RubyIndexer::Entry::Signature)),
          comments: anything,
        )
      end

      it "registers exactly three methods" do
        enhancement.on_call_node_enter(node)

        expect(listener).to have_received(:add_method).exactly(3).times
      end
    end

    context "when processing an output declaration" do
      let(:source) { "output :result, type: Hash" }
      let(:node) { Prism.parse(source).value.statements.body.first }

      it "registers the getter method" do
        enhancement.on_call_node_enter(node)

        expect(listener).to have_received(:add_method).with(
          "result",
          anything,
          array_including(an_instance_of(RubyIndexer::Entry::Signature)),
          comments: anything,
        )
      end

      it "registers the predicate method" do
        enhancement.on_call_node_enter(node)

        expect(listener).to have_received(:add_method).with(
          "result?",
          anything,
          array_including(an_instance_of(RubyIndexer::Entry::Signature)),
          comments: anything,
        )
      end

      it "registers the setter method" do
        enhancement.on_call_node_enter(node)

        expect(listener).to have_received(:add_method).with(
          "result=",
          anything,
          array_including(an_instance_of(RubyIndexer::Entry::Signature)),
          comments: anything,
        )
      end
    end

    context "when processing arg with multiple options" do
      let(:source) { "arg :user, type: User, optional: true, context: true" }
      let(:node) { Prism.parse(source).value.statements.body.first }

      it "registers all three methods" do
        enhancement.on_call_node_enter(node)

        expect(listener).to have_received(:add_method).with("user", anything, anything, comments: anything)
        expect(listener).to have_received(:add_method).with("user?", anything, anything, comments: anything)
        expect(listener).to have_received(:add_method).with("user=", anything, anything, comments: anything)
      end
    end

    context "when processing non-arg/output method calls" do
      let(:source) { "step :validate" }
      let(:node) { Prism.parse(source).value.statements.body.first }

      it "does not register any methods" do
        enhancement.on_call_node_enter(node)

        expect(listener).not_to have_received(:add_method)
      end
    end

    context "when there is no current owner" do
      let(:source) { "arg :name, type: String" }
      let(:node) { Prism.parse(source).value.statements.body.first }

      before do
        allow(listener).to receive(:current_owner).and_return(nil)
      end

      it "does not register any methods" do
        enhancement.on_call_node_enter(node)

        expect(listener).not_to have_received(:add_method)
      end
    end

    context "when arg is called without arguments" do
      let(:source) { "arg" }
      let(:node) { Prism.parse(source).value.statements.body.first }

      it "does not register any methods" do
        enhancement.on_call_node_enter(node)

        expect(listener).not_to have_received(:add_method)
      end
    end

    context "when first argument is not a symbol" do
      let(:source) { 'arg "name", type: String' }
      let(:node) { Prism.parse(source).value.statements.body.first }

      it "does not register any methods" do
        enhancement.on_call_node_enter(node)

        expect(listener).not_to have_received(:add_method)
      end
    end
  end

  describe "#on_call_node_leave" do
    let(:source) { "arg :name, type: String" }
    let(:node) { Prism.parse(source).value.statements.body.first }

    it "does nothing (no-op)" do
      expect { enhancement.on_call_node_leave(node) }.not_to raise_error
    end
  end

  describe "type extraction" do
    # Type extraction resolves the `type:` option to a Ruby type string.
    # It handles simple Ruby classes and namespaced classes.

    describe "#extract_ruby_type (private method)" do
      def extract_type_for(source)
        node = Prism.parse(source).value.statements.body.first
        enhancement.send(:extract_ruby_type, node)
      end

      it "extracts simple Ruby class types" do
        expect(extract_type_for("arg :name, type: String")).to eq("String")
        expect(extract_type_for("arg :data, type: Hash")).to eq("Hash")
        expect(extract_type_for("arg :items, type: Array")).to eq("Array")
      end

      it "extracts custom class types" do
        expect(extract_type_for("arg :user, type: User")).to eq("User")
        expect(extract_type_for("arg :order, type: Order")).to eq("Order")
      end

      it "extracts namespaced class types" do
        expect(extract_type_for("arg :payment, type: Stripe::Charge")).to eq("Stripe::Charge")
        expect(extract_type_for("arg :config, type: MyApp::Config")).to eq("MyApp::Config")
      end

      it "returns nil when no type option is present" do
        expect(extract_type_for("arg :name")).to be_nil
        expect(extract_type_for("arg :name, optional: true")).to be_nil
      end

      it "works with output declarations" do
        expect(extract_type_for("output :result, type: Hash")).to eq("Hash")
        expect(extract_type_for("output :user, type: User")).to eq("User")
      end
    end

    context "with types in method registration" do
      let(:source) { "arg :name, type: String" }
      let(:node) { Prism.parse(source).value.statements.body.first }

      it "registers all three methods even with type option" do
        enhancement.on_call_node_enter(node)

        expect(listener).to have_received(:add_method).with("name", anything, anything, anything)
        expect(listener).to have_received(:add_method).with("name?", anything, anything, anything)
        expect(listener).to have_received(:add_method).with("name=", anything, anything, anything)
      end
    end
  end

  describe "YARD comments for type information" do
    def comments_for(method_name)
      captured_comments = nil
      allow(listener).to receive(:add_method) do |name, _loc, _sigs, comments:|
        captured_comments = comments if name == method_name
      end
      enhancement.on_call_node_enter(node)
      captured_comments
    end

    context "with simple Ruby class type" do
      let(:source) { "arg :user, type: User" }
      let(:node) { Prism.parse(source).value.statements.body.first }

      it "includes @return tag for getter" do
        expect(comments_for("user")).to eq("@return [User]")
      end

      it "includes @return [Boolean] for predicate" do
        expect(comments_for("user?")).to eq("@return [Boolean]")
      end

      it "includes @param and @return tags for setter" do
        expect(comments_for("user=")).to eq("@param value [User] the value to set\n@return [User]")
      end
    end

    context "without type option" do
      let(:source) { "arg :name" }
      let(:node) { Prism.parse(source).value.statements.body.first }

      it "returns nil for getter comment" do
        expect(comments_for("name")).to be_nil
      end

      it "still includes @return [Boolean] for predicate" do
        expect(comments_for("name?")).to eq("@return [Boolean]")
      end

      it "includes basic @param for setter" do
        expect(comments_for("name=")).to eq("@param value the value to set")
      end
    end
  end

  describe "custom type mappings from config" do
    def extract_type_for(source)
      node = Prism.parse(source).value.statements.body.first
      enhancement.send(:extract_ruby_type, node)
    end

    after do
      Operandi.config.ruby_lsp_type_mappings = {}
    end

    context "with custom type mappings configured" do
      before do
        Operandi.config.ruby_lsp_type_mappings = {
          "CustomTypes::UUID" => "String",
          "CustomTypes::Money" => "BigDecimal",
          "CustomTypes::Email" => "String",
        }
      end

      it "maps custom CustomTypes::UUID to String" do
        expect(extract_type_for("arg :id, type: CustomTypes::UUID")).to eq("String")
      end

      it "maps custom CustomTypes::Money to BigDecimal" do
        expect(extract_type_for("arg :price, type: CustomTypes::Money")).to eq("BigDecimal")
      end

      it "maps custom namespaced types" do
        expect(extract_type_for("arg :email, type: CustomTypes::Email")).to eq("String")
      end

      it "returns the original type string when no mapping exists" do
        expect(extract_type_for("arg :name, type: UnmappedType")).to eq("UnmappedType")
      end
    end

    context "with parameterized custom types" do
      before do
        Operandi.config.ruby_lsp_type_mappings = {
          "CustomTypes::JSON" => "Hash",
        }
      end

      it "extracts base type from method chain" do
        expect(extract_type_for("arg :data, type: CustomTypes::JSON.optional")).to eq("Hash")
      end
    end

    context "with nested method chains" do
      before do
        Operandi.config.ruby_lsp_type_mappings = {
          "SomeClass" => "String",
        }
      end

      it "extracts base type from deeply nested method chain" do
        # This triggers the recursive call in extract_receiver_constant
        # when receiver is a CallNode (e.g., SomeClass.method1.method2)
        expect(extract_type_for("arg :data, type: SomeClass.method1.method2")).to eq("String")
      end
    end
  end

  describe "error handling in type mappings" do
    def extract_type_for(source)
      node = Prism.parse(source).value.statements.body.first
      enhancement.send(:extract_ruby_type, node)
    end

    context "when config.ruby_lsp_type_mappings raises NoMethodError" do
      let(:mock_config) { instance_double(Operandi::Config) }

      before do
        allow(Operandi).to receive(:config).and_return(mock_config)
        allow(mock_config).to receive(:ruby_lsp_type_mappings).and_raise(NoMethodError)
      end

      it "returns original type string when mappings unavailable" do
        expect(extract_type_for("arg :name, type: SomeType")).to eq("SomeType")
      end
    end
  end
end
