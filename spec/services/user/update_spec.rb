# frozen_string_literal: true

require 'spec_helper'

RSpec.describe User::Update do
  subject { service }

  let(:service)      { described_class.call(params) }
  let(:user)         { nil }
  let(:current_user) { nil }
  let(:attributes)   { {} }
  let(:params)       { { user: user, current_user: current_user, attributes: attributes } }

  context 'update own profile' do
    let(:user)         { User.new('Andrew Emelianenko', 'emelianenko.web@gmail.com', true) }
    let(:current_user) { user }
    let(:attributes)   { { full_name: 'Andrii Yemelianenko' } }

    it 'success' do
      is_expected.to be_success
    end

    it 'changed full name' do
      expect(service.user.full_name).to eq('Andrii Yemelianenko')
    end

    it 'triggers finally callbacks' do
      expect(service.finally_triggered).to be(true)
    end
  end

  context 'update profile without attributes' do
    it 'raises error' do
      expect { service }.to raise_error(Light::Services::ParamType)
    end
  end

  context 'update another user' do
    let(:user)         { User.new('Andrew Emelianenko', 'emelianenko.web@gmail.com', true) }
    let(:current_user) { User.new('Maksym Hlukhovtsov', 'mordamax@gmail.com', false) }
    let(:attributes)   { { full_name: 'Andrii Yemelianenko' } }

    it 'fails' do
      is_expected.not_to be_success
    end

    it 'returns errors' do
      expect(service.errors.to_hash).to eql(base: ["You don't have permissions to update this user"])
    end

    it 'does not mark record as updated' do
      expect(service.updated).to be(false)
    end

    it 'triggers finally callbacks' do
      expect(service.finally_triggered).to be(true)
    end
  end
end
