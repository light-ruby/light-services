require 'spec_helper'

RSpec.describe User::Update do
  let(:user)          { User.new('Andrew Emelianenko', 'emelianenko.web@gmail.com', true) }
  let(:another_user)  { User.new('Maksym Hlukhovtsov', 'mordamax@gmail.com', false) }

  it 'update my profile' do
    full_name_new = 'Andrii Yemelianenko'

    service = User::Update.call(
      user: user,
      current_user: user,
      attributes: { full_name: full_name_new }
    )

    expect(service.user.full_name).to eql(full_name_new)
    expect(service.success?).to be(true)
    expect(service.updated).to be(true)
    expect(service.finally_triggered).to be(true)
  end

  it 'update my profile without attributes' do
    expect do
      User::Update.call(
        current_user: user,
        attributes: { full_name: 'Andrii Yemelianenko' }
      )
    end.to raise_error(Light::Services::ParamRequired)

    expect do
      User::Update.call(
        user: user,
        attributes: { full_name: 'Andrii Yemelianenko' }
      )
    end.to raise_error(Light::Services::ParamRequired)

    expect do
      User::Update.call(
        user: user,
        current_user: user
      )
    end.to raise_error(Light::Services::ParamRequired)
  end

  it 'update another user' do
    service = User::Update.call(
      user: user,
      current_user: another_user,
      attributes: { full_name: 'Andrii Yemelianenko' }
    )

    expect(service.success?).to be(false)
    expect(service.errors.to_hash).to eql({ base: ["You don't have permissions to update this user"] })
    expect(service.updated).to be(false)
    expect(service.finally_triggered).to be(true)
  end
end
