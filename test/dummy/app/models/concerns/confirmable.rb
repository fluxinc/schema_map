# frozen_string_literal: true

module Confirmable
  extend ActiveSupport::Concern

  included do
    belongs_to :confirmed_by, class_name: "User", optional: true
  end
end
