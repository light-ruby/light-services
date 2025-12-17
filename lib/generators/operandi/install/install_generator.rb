# frozen_string_literal: true

require "rails/generators/base"

module Operandi
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      class_option :skip_initializer, type: :boolean, default: false,
                                      desc: "Skip creating the initializer file"
      class_option :skip_spec, type: :boolean, default: false,
                               desc: "Skip creating the spec file"

      desc "Creates ApplicationService and initializer for Operandi"

      def create_application_service
        template "application_service.rb.tt", "app/services/application_service.rb"
      end

      def create_initializer
        return if options[:skip_initializer]

        template "initializer.rb.tt", "config/initializers/operandi.rb"
      end

      def create_spec_file
        return if options[:skip_spec]
        return unless rspec_installed?

        template "application_service_spec.rb.tt", "spec/services/application_service_spec.rb"
      end

      private

      def rspec_installed?
        File.directory?(File.join(destination_root, "spec"))
      end
    end
  end
end
