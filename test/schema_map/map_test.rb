# frozen_string_literal: true

require "test_helper"

class SchemaMap::MapTest < ActiveSupport::TestCase
  # PostgreSQL normalizes a partial-index predicate when it stores it; SQLite keeps the source text.
  PARTIAL_INDEX_PREDICATE = ActiveRecord::Base.connection.adapter_name =~ /postg/i ?
    "((slug IS NOT NULL) AND (archived_at IS NULL))" : "slug IS NOT NULL AND archived_at IS NULL"

  EXPECTED_LINES = [
    "- **Car** (vehicles; STI < Vehicle) — has_many comments[commentable]; owner none",
    "- **Comment** (comments) — belongs_to commentable*; cols body:text, commentable_id:integer!, commentable_type:string!; owner none",
    "- **Project** (projects) — belongs_to tenant; has_many comments[commentable], tasks; attached files[]; cols lock_version:integer!=0, position:integer!=0, tenant_id:integer!, title:string!; unique tenant_id+position; owner tenant_id",
    "- **Task** (tasks) — belongs_to confirmed_by, project; has_one tenant→project; has_many comments[commentable]; attached scan; concerns Confirmable; cols confirmed_at:datetime, confirmed_by_id:integer, done:boolean!=false, estimate:decimal, name:string, notes:text, project_id:integer!; checks tasks_confirmation_pair; owner via project.tenant_id",
    "- **Tenant** (tenants) — has_many projects, tasks→projects; cols archived_at:datetime, name:string!, slug:string; unique slug where(#{PARTIAL_INDEX_PREDICATE}); owner self",
    "- **User** (users) — cols email:string!; unique email; owner none",
    "- **Vehicle** (vehicles) — cols plate:string, type:string!, wheels:integer!=4; unique plate; owner none"
  ].freeze

  def render(**overrides)
    SchemaMap::Map.new(SchemaMap::Configuration.new(root: Rails.root, ownership_column: "tenant_id", **overrides)).render
  end

  test "renders one deterministic line per model" do
    lines = render.lines.map(&:chomp).select { |l| l.start_with?("- ") }
    assert_equal EXPECTED_LINES, lines
  end

  test "renders a header naming the regenerate and check commands and the legend" do
    header = render.lines.first.chomp
    assert_includes header, "`bin/rails agents:data_model`"
    assert_includes header, "`bin/rails agents:data_model:check`"
    assert_includes header, "do not edit"
    assert_includes header, "Legend"
    assert_includes header, "`x[]` has_many_attached"
  end

  test "is idempotent" do
    assert_equal render, render
  end

  test "omits the owner segment when no ownership column is configured" do
    body = render(ownership_column: nil)
    refute_match(/owner/, body.lines.drop(1).join)
  end

  test "reports a custom command in the header" do
    assert_includes render(command: "bin/rake agents:data_model").lines.first, "`bin/rake agents:data_model`"
  end
end
