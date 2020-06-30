# frozen_string_literal: true

RSpec.describe User::Create do
  let(:service) { described_class.run(params: params) }

  context "when args are good" do
    let(:name) { "Andrew Emelianenko" }

    let(:params) do
      {
        user: {
          name: name
        }
      }
    end

    it { expect(service).to be_success }
    it { expect(service.user).to be_a(User) }
    it { expect(service.user.name).to eq(name) }
  end

  context "when params are wrong" do
    let(:params) { "hey" }

    it { expect { service }.to raise_error(Light::Services::ArgTypeError) }
  end

  context "when user is absent" do
    let(:params) { {} }

    it { expect(service).to be_failed }
    it { expect(service.errors).to have_key(:params) }
  end

  context "when name is absent" do
    let(:service) { described_class.run(params: params) }

    let(:params) do
      {
        user: {
          name: ""
        }
      }
    end

    it { expect(service).to be_failed }
    it { expect(service.errors).to have_key(:name) }
  end
end
