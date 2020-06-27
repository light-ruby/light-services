# frozen_string_literal: true

RSpec.describe Letter::BuildWord do
  context "with correct symbol" do
    let(:symbol) { %w[! # @].sample }

    context "with correct letters" do
      subject { described_class.run(letters: letters, symbol: symbol).word }

      let(:letters) { %w[H e l l o] }
      let(:word) { "#{letters.join}#{symbol}" }

      it { is_expected.to eq(word) }
    end

    context "with incorrect letters" do
      subject { described_class.run(letters: letters, symbol: symbol) }

      let(:letters) { [1, 2, 3] }

      it { is_expected.not_to be_success }
    end
  end

  context "with incorrect symbol" do
    let(:symbol) { %w[a b c].sample }

    context "with correct letters" do
      subject { described_class.run(letters: letters, symbol: symbol) }

      let(:letters) { %w[H e l l o] }

      it { is_expected.not_to be_success }
    end

    context "with incorrect letters" do
      subject { described_class.run(letters: letters, symbol: symbol) }

      let(:letters) { [1, 2, 3] }

      it { is_expected.not_to be_success }
    end
  end

  context "without symbol" do
    context "with correct letters" do
      subject { described_class.run(letters: letters).word }

      let(:letters) { %w[H e l l o] }
      let(:word) { letters.join }

      it { is_expected.to eq(word) }
    end

    context "with incorrect letters" do
      subject { described_class.run(letters: letters) }

      let(:letters) { [1, 2, 3] }

      it { is_expected.not_to be_success }
    end
  end
end
