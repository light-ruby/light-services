# frozen_string_literal: true

require "rails/generators/base"

module Operandi
  module Generators
    class ServiceGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      argument :name, type: :string, required: true,
                      desc: "The name of the service (e.g., user/create or CreateUser)"

      class_option :args, type: :array, default: [],
                          desc: "List of arguments for the service"
      class_option :steps, type: :array, default: [],
                           desc: "List of steps for the service"
      class_option :outputs, type: :array, default: [],
                             desc: "List of outputs for the service"
      class_option :skip_spec, type: :boolean, default: false,
                               desc: "Skip creating the spec file"
      class_option :parent, type: :string, default: "ApplicationService",
                            desc: "Parent class for the service"

      desc "Creates a new service class"

      def create_service_file
        template "service.rb.tt", "app/services/#{file_path}.rb"
      end

      def create_spec_file
        return if options[:skip_spec]
        return unless rspec_installed?

        template "service_spec.rb.tt", "spec/services/#{file_path}_spec.rb"
      end

      private

      def file_path
        name.underscore
      end

      def class_name
        name.camelize
      end

      def parent_class
        options[:parent]
      end

      def arguments
        options[:args]
      end

      def steps
        options[:steps]
      end

      def outputs
        options[:outputs]
      end

      def rspec_installed?
        File.directory?(File.join(destination_root, "spec"))
      end
    end
  end
end
