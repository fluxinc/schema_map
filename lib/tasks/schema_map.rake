# frozen_string_literal: true

namespace :agents do
  desc "Regenerate the data-model map block (SchemaMap) in the configured file"
  task data_model: :environment do
    path = SchemaMap.configuration.file_path
    if SchemaMap.write!
      puts "schema_map: updated data-model map in #{path}"
    else
      puts "schema_map: data-model map in #{path} already current"
    end
  rescue SchemaMap::Error => e
    abort e.message
  end

  namespace :data_model do
    desc "Verify the committed data-model map matches the schema; exit 1 with a diff when stale"
    task check: :environment do
      result = SchemaMap.check
      if result.ok?
        puts result.message
      else
        warn result.message
        exit 1
      end
    end
  end
end

# Regenerate whenever a schema file is dumped. Multi-database apps dump through db:schema:dump:<name>,
# so every matching task is enhanced. Production is inert by default (dump_schema_after_migration=false).
# The dump mirrors the live database by definition (also after db:rollback), so pending migrations are allowed here.
Rake::Task.tasks.select { |task| task.name.match?(/\Adb:schema:dump(:\w+)?\z/) }.each do |task|
  task.enhance do
    Rake::Task["schema_map:regenerate_after_dump"].invoke
  end
end

namespace :schema_map do
  task regenerate_after_dump: :environment do
    path = SchemaMap.configuration.file_path
    if SchemaMap.write!(allow_pending_migrations: true)
      puts "schema_map: updated data-model map in #{path}"
    else
      puts "schema_map: data-model map in #{path} already current"
    end
  rescue SchemaMap::MarkersMissing => e
    abort e.message
  end
end
