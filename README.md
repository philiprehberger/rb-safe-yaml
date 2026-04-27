# philiprehberger-safe_yaml

[![Tests](https://github.com/philiprehberger/rb-safe-yaml/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-safe-yaml/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-safe_yaml.svg)](https://rubygems.org/gems/philiprehberger-safe_yaml)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-safe-yaml)](https://github.com/philiprehberger/rb-safe-yaml/commits/main)

Safe YAML loading with restricted types, schema validation, and size limits

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-safe_yaml"
```

Or install directly:

```bash
gem install philiprehberger-safe_yaml
```

## Usage

```ruby
require "philiprehberger/safe_yaml"

# Load a YAML string safely
data = Philiprehberger::SafeYaml.load("name: Alice\nage: 30\n")
# => {"name"=>"Alice", "age"=>30}

# Load from a file
data = Philiprehberger::SafeYaml.load_file("config.yml")
```

### Size Limits

```ruby
# Reject oversized input
Philiprehberger::SafeYaml.load(huge_string, max_size: 1024)
# => raises Philiprehberger::SafeYaml::SizeError if input exceeds 1024 bytes
```

### Permitted Classes

```ruby
# Allow specific classes during deserialization
data = Philiprehberger::SafeYaml.load(yaml_string, permitted_classes: [Symbol, Date])
```

### Safe Serialization

```ruby
require "philiprehberger/safe_yaml"

data = { "host" => "localhost", "port" => 3000, "debug" => true }
yaml_string = Philiprehberger::SafeYaml.dump(data)
Philiprehberger::SafeYaml.dump_file(data, "config.yml")
```

### Schema Validation

```ruby
schema = Philiprehberger::SafeYaml::Schema.new do
  required :name, String
  required :age, Integer
  optional :email, String
end

data = Philiprehberger::SafeYaml.load("name: Alice\nage: 30\n")

# Validate with exceptions
schema.validate!(data)
# => true (or raises SchemaError)

# Validate without exceptions
result = schema.validate(data)
# => { valid: true, errors: [] }
```

### Alias Limits

```ruby
# Block all aliases (default behavior)
Philiprehberger::SafeYaml.load(yaml_with_aliases)
# => raises Psych::BadAlias

# Allow up to 3 aliases
data = Philiprehberger::SafeYaml.load(yaml_with_aliases, max_aliases: 3)

# Exceeding the limit raises an error
Philiprehberger::SafeYaml.load(yaml_with_many_aliases, max_aliases: 2)
# => raises Philiprehberger::SafeYaml::Error
```

### Load and Validate

```ruby
schema = Philiprehberger::SafeYaml::Schema.new do
  required :name, String
  required :port, Integer
end

# Parse and validate in one step
data = Philiprehberger::SafeYaml.load_and_validate("name: app\nport: 3000\n", schema: schema)
# => {"name"=>"app", "port"=>3000}

# Raises SchemaError if validation fails
Philiprehberger::SafeYaml.load_and_validate("name: app\n", schema: schema)
# => raises Philiprehberger::SafeYaml::SchemaError
```

### Sanitize

```ruby
raw = "# This is a comment\nname: Alice\n# Another comment\nage: 30\n"
cleaned = Philiprehberger::SafeYaml.sanitize(raw)
# => "name: Alice\nage: 30\n"
```

### Defaults Merge

```ruby
defaults = { 'host' => 'localhost', 'port' => 3000, 'db' => { 'pool' => 5, 'timeout' => 30 } }
yaml = "port: 8080\ndb:\n  pool: 10\n"

data = Philiprehberger::SafeYaml.load_with_defaults(yaml, defaults: defaults)
# => {"host"=>"localhost", "port"=>8080, "db"=>{"pool"=>10, "timeout"=>30}}
```

### Merging

Merge multiple YAML sources into a single deeply merged Hash. Each source can be either inline YAML or a path to a YAML file. When `as_files` is `nil` (the default), a String source is treated as a file path if `File.file?(source)` is true, and as inline YAML otherwise. Pass `as_files: false` to force inline interpretation. Later sources win on conflicts; nested Hashes are deep-merged; arrays are **replaced**, not concatenated.

```ruby
base   = "host: localhost\nport: 3000\ndb:\n  pool: 5\n  timeout: 30\n"
override = "port: 8080\ndb:\n  pool: 10\n"

Philiprehberger::SafeYaml.merge(base, override)
# => {"host"=>"localhost", "port"=>8080, "db"=>{"pool"=>10, "timeout"=>30}}

# Mix files and inline YAML; load_opts (max_size, permitted_classes, ...) propagate
Philiprehberger::SafeYaml.merge('config/defaults.yml', 'config/overrides.yml', max_size: 10_240)
```

### Custom Validation Rules

```ruby
schema = Philiprehberger::SafeYaml::Schema.new do
  required :port, Integer, rule: ->(v) { (1..65_535).cover?(v) }, message: 'must be between 1 and 65535'
  required :status, String, rule: ->(v) { %w[active inactive].include?(v) }
  optional :email, String, rule: ->(v) { v.include?('@') }, message: 'must be a valid email'
end

schema.validate!({ 'port' => 80, 'status' => 'active' })
# => true

result = schema.validate({ 'port' => 0, 'status' => 'unknown' })
# => { valid: false, errors: ["key port: must be between 1 and 65535", "key status: failed validation rule"] }
```

## API

| Method / Class | Description |
|----------------|-------------|
| `SafeYaml.load(string, **opts)` | Safely load a YAML string |
| `SafeYaml.load_file(path, **opts)` | Safely load a YAML file |
| `SafeYaml.load_and_validate(string, schema:, **opts)` | Load and validate in one step |
| `SafeYaml.load_with_defaults(string, defaults:, **opts)` | Load and deep merge over defaults |
| `SafeYaml.merge(*sources, as_files:, **load_opts)` | Deep merge multiple inline YAML strings and/or file paths (later wins; arrays replaced) |
| `SafeYaml.sanitize(string)` | Strip comments and normalize whitespace |
| `SafeYaml.dump(data, permitted_classes:)` | Safely dump data to a YAML string |
| `SafeYaml.dump_file(data, path, permitted_classes:)` | Safely dump data to a YAML file |
| `Loader.load(string, permitted_classes:, max_aliases:, max_size:)` | Core safe loading with all options |
| `Loader.load_file(path, **opts)` | Read file and delegate to `Loader.load` |
| `Loader.dump(data, permitted_classes:)` | Dump data to YAML with type validation |
| `Loader.dump_file(data, path, permitted_classes:)` | Write validated YAML to file |
| `Schema.new(&block)` | Define a validation schema with DSL |
| `Schema#required(key, type, rule:, message:)` | Declare a required key with expected type and optional validation rule |
| `Schema#optional(key, type, rule:, message:)` | Declare an optional key with expected type and optional validation rule |
| `Schema#validate!(data)` | Validate and raise `SchemaError` on failure |
| `Schema#validate(data)` | Validate and return `{ valid:, errors: }` |
| `SafeYaml::Error` | Base error class |
| `SafeYaml::SchemaError` | Raised on schema validation failure |
| `SafeYaml::SizeError` | Raised when input exceeds max_size |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-safe-yaml)

🐛 [Report issues](https://github.com/philiprehberger/rb-safe-yaml/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-safe-yaml/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
