require 'spec_helper'

RSpec.describe User::Register do
  it 'register' do
    service = User::Register.call(
      first_name: ' Michail',
      last_name: ' Belousov',
      email: 'michail@soften-it.com'
    )

    expect(service.success?).to be(true)
    expect(service.user.full_name).to eql('Michail Belousov')
    expect(service.user.email).to eql('michail@soften-it.com')
  end

  it 'register without email' do
    expect {
      User::Register.call(
        first_name: 'Michail',
        last_name: 'Belousov'
      )
    }.to raise_error(Light::Service::ParamRequired)
  end

  it 'register with already existed email' do
    service = User::Register.call(
      first_name: 'Andrew',
      last_name: 'Emelianenko',
      email: 'emelianenko.web@gmail.com'
    )

    expect(service.success?).to be(false)
    expect(service.errors.to_hash).to eql({ email: [:taken] })
  end

  it 'register with wrong parameter type' do
    expect {
      User::Register.call(
        first_name: 123,
        last_name: 123,
        email: 'michail@soften-it.com'
      )
    }.to raise_error(Light::Service::ParamType)
  end
end
