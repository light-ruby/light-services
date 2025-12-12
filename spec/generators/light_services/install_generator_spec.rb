# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"
require "erb"

RSpec.describe "LightServices::Generators::InstallGenerator" do
  let(:destination_root) { Dir.mktmpdir }
  let(:templates_path) do
    File.expand_path("../../../lib/generators/light_services/install/templates", __dir__)
  end

  before do
    FileUtils.mkdir_p(destination_root)
  end

  after do
    FileUtils.rm_rf(destination_root)
  end

  def copy_template(source, destination)
    source_path = File.join(templates_path, source)
    dest_path = File.join(destination_root, destination)

    FileUtils.mkdir_p(File.dirname(dest_path))
    FileUtils.cp(source_path, dest_path)
  end

  describe "application_service.rb template" do
    it "exists" do
      template_path = File.join(templates_path, "application_service.rb.tt")
      expect(File.exist?(template_path)).to be true
    end

    it "contains correct base class inheritance" do
      template_path = File.join(templates_path, "application_service.rb.tt")
      content = File.read(template_path)

      expect(content).to include("frozen_string_literal: true")
      expect(content).to include("class ApplicationService < Light::Services::Base")
    end

    it "includes example context argument comment" do
      template_path = File.join(templates_path, "application_service.rb.tt")
      content = File.read(template_path)

      expect(content).to include("arg :current_user")
      expect(content).to include("context: true")
    end
  end

  describe "initializer.rb template" do
    it "exists" do
      template_path = File.join(templates_path, "initializer.rb.tt")
      expect(File.exist?(template_path)).to be true
    end

    it "contains configuration block" do
      template_path = File.join(templates_path, "initializer.rb.tt")
      content = File.read(template_path)

      expect(content).to include("frozen_string_literal: true")
      expect(content).to include("Light::Services.configure do |config|")
    end

    it "includes common configuration options" do
      template_path = File.join(templates_path, "initializer.rb.tt")
      content = File.read(template_path)

      expect(content).to include("config.use_transactions")
      expect(content).to include("config.break_on_error")
      expect(content).to include("config.raise_on_error")
    end
  end

  describe "application_service_spec.rb template" do
    it "exists" do
      template_path = File.join(templates_path, "application_service_spec.rb.tt")
      expect(File.exist?(template_path)).to be true
    end

    it "contains RSpec describe block" do
      template_path = File.join(templates_path, "application_service_spec.rb.tt")
      content = File.read(template_path)

      expect(content).to include("frozen_string_literal: true")
      expect(content).to include('require "rails_helper"')
      expect(content).to include("RSpec.describe ApplicationService, type: :service")
    end
  end
end
