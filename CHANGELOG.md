# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-04-26

### Added
- `SafeYaml.merge(*sources, as_files: nil, **load_opts)` — loads each YAML source through the safe loader and deep merges them in order, with later sources winning. Sources may be inline YAML strings or file paths (auto-detected via `File.file?`, override with `as_files:`). Arrays are replaced (not concatenated). Raises `ArgumentError` when a source does not yield a Hash.

## [0.4.0] - 2026-04-14

### Added
- `max_aliases:` keyword on `SafeYaml.load` — controls alias limit passed to YAML.safe_load; raises `Error` when count exceeds limit
- `SafeYaml.load_and_validate(string, schema:, **opts)` — convenience method combining load and schema validation in one call
- `SafeYaml.sanitize(string)` — strips full-line comments, normalizes trailing whitespace, and validates YAML syntax
- `SafeYaml.load_with_defaults(string, defaults: {})` — parses YAML then deep merges over a defaults hash

## [0.3.0] - 2026-04-11

### Added
- `rule:` keyword argument on `Schema#required` and `Schema#optional` for custom validation predicates
- `message:` keyword argument for custom validation error messages when rules fail

### Fixed
- Bug report template gem version field now required
- Removed duplicate `[0.1.4]` entry in CHANGELOG

## [0.2.0] - 2026-04-04

### Added
- `dump` method for safe YAML serialization with type validation
- `dump_file` method for writing safe YAML to files
- GitHub issue template gem version field
- Feature request "Alternatives considered" field

## [0.1.9] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.1.8] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.1.7] - 2026-03-26

### Changed

- Add Sponsor badge and fix License link format in README

## [0.1.6] - 2026-03-24

### Fixed
- Fix README one-liner to remove trailing period

## [0.1.5] - 2026-03-24

### Fixed
- Remove inline comments from Development section to match template

## [0.1.4] - 2026-03-22

### Changed

- Expand test coverage to 30+ examples with nested structures, arrays, booleans, null values, boundary size checks, and schema validation edge cases

## [0.1.3] - 2026-03-16

### Changed
- Add License badge to README
- Add bug_tracker_uri to gemspec

## [0.1.2] - 2026-03-13

### Fixed
- Fix RuboCop offenses: NumericPredicate, ExtraSpacing, StringLiteralsInInterpolation
- Replace OpenStruct with Struct in tests to satisfy Style/OpenStructUse

## [0.1.0] - 2026-03-13

### Added
- Initial release
- Safe YAML loading via `YAML.safe_load` with sensible defaults
- `Loader.load` and `Loader.load_file` with permitted_classes and max_size options
- Schema validation DSL with `required` and `optional` field declarations
- `Schema#validate!` raises `SchemaError` on mismatch
- `Schema#validate` returns result hash with errors
- `SizeError` for input size enforcement
