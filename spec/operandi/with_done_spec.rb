# frozen_string_literal: true

RSpec.describe WithDone do
  context "with arguments" do
    let(:service) { described_class.run(add_c: true, do_not_add_d: false) }

    it { expect(service.word).to eql("ab") }
  end
end
