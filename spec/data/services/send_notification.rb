# frozen_string_literal: true

class SendNotification < ApplicationService
  # Arguments
  arg :text, type: String

  # Steps
  step :validate_text
  step :send_notification

  private

  def validate_text
    return if text.present?

    errors.add(:text, "must be present")
  end

  def send_notification
    # Great logic goes here
  end
end
