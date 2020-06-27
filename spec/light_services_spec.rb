# frozen_string_literal: true

RSpec.describe Light::Services do
  it "has a version number" do
    expect(Light::Services::VERSION).not_to be nil
  end

  it "works" do
    params = {
      user: {
        name: "Andrew"
      }
    }

    User::Create.run(params: params)
  end

  describe ".config" do
    let(:boolean_params) { %i[load_errors use_transactions rollback_on_error raise_on_error] }

    it "responds to params" do
      boolean_params.each do |param|
        expect(described_class.config).to respond_to(param)
      end
    end
  end
end
