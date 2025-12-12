# frozen_string_literal: true

module Light
  module Services
    # Collection type constants
    module CollectionTypes
      ARGUMENTS = :arguments
      OUTPUTS = :outputs

      ALL = [ARGUMENTS, OUTPUTS].freeze
    end

    # Field type constants
    module FieldTypes
      ARGUMENT = :argument
      OUTPUT = :output

      ALL = [ARGUMENT, OUTPUT].freeze
    end
  end
end
