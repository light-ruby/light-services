# frozen_string_literal: true

require 'spec_helper'

RSpec.describe User::Register do
  subject { service }

  let(:service) { described_class.call(params) }

  context 'with correct params' do
    let(:params) { { first_name: ' Andrew', last_name: ' Emelianenko', email: 'andrew@iamdev.io' } }

    it 'success' do
      is_expected.to be_success
    end

    it 'does not have any warnings' do
      is_expected.not_to be_any_warnings
    end

    it 'builds full name' do
      expect(service.user.full_name).to eq('Andrew Emelianenko')
    end

    it 'stores correct email' do
      expect(service.user.email).to eq('andrew@iamdev.io')
    end
  end

  context 'without required parameter' do
    let(:params) { { first_name: 'Andrew', last_name: 'Emelianenko' } }

    it 'raises exception' do
      expect { service }.to raise_error(Light::Services::ParamRequired)
    end
  end

  context 'with already existed email' do
    let(:params) { { first_name: 'Andrew', last_name: 'Emelianenko', email: 'emelianenko.web@gmail.com' } }

    it 'failed' do
      is_expected.not_to be_success
    end

    it 'errors any present' do
      expect(service.errors).to be_any
    end

    it 'errors not blank' do
      expect(service.errors).not_to be_blank
    end

    it 'has error about taken email' do
      expect(service.errors.to_hash).to eql(email: [:taken])
    end
  end

  context 'with wrong parameter type' do
    let(:params) { { first_name: 100, last_name: 200, email: 'andrew@iamdev.io' } }

    it 'raises error' do
      expect { service }.to raise_error(Light::Services::ParamType)
    end
  end

  context 'with nil parameter which allow be nil' do
    let(:params) { { first_name: 'Andrew', last_name: 'Emelianenko', email: 'andrew@iamdev.io', referer: nil } }

    it 'success' do
      is_expected.to be_success
    end
  end
end
