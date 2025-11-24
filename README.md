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
