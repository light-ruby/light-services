# frozen_string_literal: true

RSpec.describe WithConditions do
  context "with arguments" do
    let(:service) { described_class.run(add_c: true, do_not_add_d: false) }

    it { expect(service.word).to eql("abcd") }
  end

  context "without arguments" do
    let(:service) { described_class.run }

    it { expect(service.word).to eql("ab") }
  end

  context "with fake error" do
    let(:service) { described_class.with(use_transactions: false).run(fake_error: true) }

    it { expect(service.word).to eql("error") }
    it { expect(service.warnings?).to be(true) }
    it { expect(service.warnings).to have_key(:word) }
  end

  context "with wrong arguments type in `run` method" do
    it { expect { described_class.run("Hello, world!") }.to raise_error(Light::Services::ArgTypeError) }
  end

  context "with wrong arguments type in `with` method" do
    it { expect { described_class.with("Hello, world!").run }.to raise_error(Light::Services::ArgTypeError) }
  end
end
