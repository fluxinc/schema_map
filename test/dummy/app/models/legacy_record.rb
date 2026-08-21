# frozen_string_literal: true

# Abstract: must never appear in the map.
class LegacyRecord < ApplicationRecord
  self.abstract_class = true
end
