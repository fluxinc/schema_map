# frozen_string_literal: true

module FakeEngine
  class Blob < ActiveRecord::Base
    self.table_name = "active_storage_blobs"
  end
end
