# frozen_string_literal: true

class Project < ApplicationRecord
  belongs_to :tenant
  has_many :tasks, dependent: :destroy
  has_many :comments, as: :commentable
  has_many_attached :files
end
