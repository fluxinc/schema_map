# frozen_string_literal: true

class Car < Vehicle
  has_many :comments, as: :commentable
end
