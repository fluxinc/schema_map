# frozen_string_literal: true

require_relative "lib/schema_map/version"

Gem::Specification.new do |spec|
  spec.name = "schema_map"
  spec.version = SchemaMap::VERSION
  spec.authors = [ "Flux Inc" ]
  spec.summary = "A generated, verified one-line-per-model data-model map kept inside AGENTS.md."
  spec.description = <<~DESC
    Reflects your Active Record models (associations, concerns, columns, unique indexes,
    check constraints, ownership column) into a compact block between markers in AGENTS.md,
    regenerates it whenever the schema is dumped, and fails tests, CI, and commits when the
    committed block is stale. The annotate pattern, aimed at the brief agents read every session.
  DESC
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.homepage = "https://github.com/fluxinc/schema_map"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*", "CHANGELOG.md", "LICENSE.txt", "README.md"]
  spec.require_paths = [ "lib" ]

  spec.add_dependency "activerecord", ">= 7.1"
  spec.add_dependency "railties", ">= 7.1"
end
