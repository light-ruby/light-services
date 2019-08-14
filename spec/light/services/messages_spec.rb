# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Light::Services::Messages do
  let(:messages) { described_class.new }

  describe '#from_record' do
    let(:record)          { User.new('Andrew Emelianenko', 'emelianenko.web@gmail.com', true) }
    let(:errors)          { { email: [:taken] } }
    let(:expected_errors) { { email: [:taken] } }

    before do
      allow(record).to receive(:errors).and_return(double(messages: errors, any?: true))

      messages.from_record(record)
    end

    it 'imports errors from active record' do
      expect(messages.to_h).to eq(expected_errors)
    end
  end

  describe '#delete' do
    let(:error_key)     { :email }
    let(:error_message) { :taken }

    before { messages.add(error_key, error_message) }

    it 'deletes error from storage' do
      messages.delete(error_key)
      expect(messages).to be_blank
    end
  end
end
