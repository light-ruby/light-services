# frozen_string_literal: true

RSpec.describe User::Update do
  let(:service) { described_class.run(user: user, current_user: current_user, params: params) }

  context "when args are good" do
    let(:user) { User::Create.run(params: { user: { name: "Andrew Emelianenko" } }).user }
    let(:current_user) { user }
    let(:name) { "New Name" }

    let(:params) do
      {
        user: {
          name: name,
        },
      }
    end

    it { expect(service).to be_successful }
    it { expect(service.user).to be_a(User) }
    it { expect(service.user.name).to eq(name) }
  end

  context "when current user is absent" do
    let(:user) { User::Create.run(params: { user: { name: "Andrew Emelianenko" } }).user }
    let(:current_user) { nil }
    let(:name) { "New Name" }

    let(:params) do
      {
        user: {
          name: name,
        },
      }
    end

    it { expect(service).to be_failed }
    it { expect(service.errors).to have_key(:user) }
  end

  context "when user is absent" do
    let(:user) { nil }
    let(:current_user) { User::Create.run(params: { user: { name: "Andrew Emelianenko" } }).user }
    let(:name) { "New Name" }

    let(:params) do
      {
        user: {
          name: name,
        },
      }
    end

    it { expect { service }.to raise_error(Light::Services::ArgTypeError) }
  end

  context "when params are absent" do
    let(:user) { User::Create.run(params: { user: { name: "Andrew Emelianenko" } }).user }
    let(:current_user) { user }
    let(:params) { nil }

    it { expect { service }.to raise_error(Light::Services::ArgTypeError) }
  end

  context "when name is not valid" do
    let(:user) { User::Create.run(params: { user: { name: "Andrew Emelianenko" } }).user }
    let(:current_user) { user }
    let(:name) { "" }

    let(:params) do
      {
        user: {
          name: name,
        },
      }
    end

    it { expect(service).to be_failed }
    it { expect(service.errors).to have_key(:name) }
  end
end
