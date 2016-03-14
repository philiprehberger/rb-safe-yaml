# Changelog

## 0.1.3

- Add License badge to README
- Add bug_tracker_uri to gemspec

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
