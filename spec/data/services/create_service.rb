# frozen_string_literal: true

class CreateService < ApplicationService
  # Arguments
  arg :params, type: Hash, default: {}

  # Outputs
  output :entity
  output :data, default: {}

  # Steps
  step :initialize_entity
  step :assign_attributes
  step :authorize
  step :save
  step :log_action

  private

  def entity_class
    raise NotImplementedError
  end

  def filtered_params
    raise NotImplementedError
  end

  def initialize_entity
    self.entity = entity_class.new
  end

  def assign_attributes
    entity.assign_attributes(filtered_params)
  end

  def authorize
    # TODO: Implement this method
  end

  def save
    entity.save!
  rescue ActiveRecord::RecordInvalid
    errors.from_record(entity)
  end

  def log_action
    # Save information about this action anywhere
  end
end
