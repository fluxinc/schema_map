# frozen_string_literal: true

class Task < ApplicationRecord
  include Confirmable

  belongs_to :project
  has_one :tenant, through: :project
  has_many :comments, as: :commentable, dependent: :destroy
  has_one_attached :scan
end
