require 'thor'
require 'fileutils'

module Light
  class CLI < Thor
    desc "generate NAME", "Generates a new service file with the given NAME"
    def generate(name)
      # TODO: can let the user decide their preferred directory
      dir = "app/services" 
      path = File.join(Dir.pwd, "#{dir}/#{name}_service.rb")
      FileUtils.mkdir_p(File.dirname(path))

      content = <<~RUBY
        class #{name.capitalize}Service < Light::Services::Base
          # Nothing to put here yet
        end
      RUBY

      File.write(path, content)
      puts "✅ Generated: #{path}"
    end
  end
end
