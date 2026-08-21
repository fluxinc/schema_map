# frozen_string_literal: true

class Tenant < ApplicationRecord
  has_many :projects, dependent: :destroy
  has_many :tasks, through: :projects
end
