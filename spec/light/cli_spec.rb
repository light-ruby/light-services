# spec/light/cli_spec.rb
require "spec_helper"
require "fileutils"
require 'light/cli'

RSpec.describe Light::CLI do
  let(:filename) { "app/services/application_service.rb" }

  after(:each) do
    FileUtils.rm_f(filename)
  end

  it "generates the correct service file via CLI" do
    Light::CLI.start(["generate", "application"])

    expect(File).to exist(filename)
    expect(File.read(filename)).to include("class ApplicationService")
  end
end