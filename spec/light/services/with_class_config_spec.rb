# frozen_string_literal: true

RSpec.describe WithClassConfig do
  let(:service) { described_class.run }

  it { expect { service }.to raise_error(Light::Services::Error) }
end
