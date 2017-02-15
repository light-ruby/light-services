require 'spec_helper'

RSpec.describe User::Register do
  it 'register' do
    service = User::Register.call(
      first_name: ' Michail',
      last_name: ' Belousov',
      email: 'michail@frontalle.com'
    )

    expect(service.success?).to be(true)
    expect(service.any_warnings?).to be(false)

    expect(service.user.full_name).to eql('Michail Belousov')
    expect(service.user.email).to eql('michail@frontalle.com')
  end

  it 'register without email' do
    expect do
      User::Register.call(first_name: 'Michail', last_name: 'Belousov')
    end.to raise_error(Light::Services::ParamRequired)
  end

  it 'register with already existed email' do
    service = User::Register.call(
      first_name: 'Andrew',
      last_name: 'Emelianenko',
      email: 'emelianenko.web@gmail.com'
    )

    expect(service.success?).to be(false)
    expect(service.errors.any?).to be(true)
    expect(service.errors.blank?).to be(false)
    expect(service.any_warnings?).to be(false)
    expect(service.errors.to_hash).to eql(email: [:taken])

    service.errors.delete(:email)
    expect(service.errors.to_hash).to eql({})
  end

  it 'register with wrong parameter type' do
    expect do
      User::Register.call(
        first_name: 123,
        last_name: 123,
        email: 'michail@frontalle.com'
      )
    end.to raise_error(Light::Services::ParamType)
  end
end
