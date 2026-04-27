# frozen_string_literal: true

require_relative 'safe_yaml/version'
require_relative 'safe_yaml/loader'
require_relative 'safe_yaml/schema'

module Philiprehberger
  module SafeYaml
    # Base error class for SafeYaml.
    class Error < StandardError; end

    # Raised when YAML schema validation fails.
    class SchemaError < Error; end

    # Raised when YAML input exceeds the maximum allowed size.
    class SizeError < Error; end

    # Safely loads a YAML string with restricted types.
    #
    # @param string [String] the YAML string to parse
    # @param opts [Hash] options forwarded to {Loader.load}
    # @return [Object] the parsed YAML object
    # @raise [SizeError] if string exceeds max_size
    def self.load(string, **opts)
      Loader.load(string, **opts)
    end

    # Safely loads a YAML file with restricted types.
    #
    # @param path [String] path to the YAML file
    # @param opts [Hash] options forwarded to {Loader.load}
    # @return [Object] the parsed YAML object
    # @raise [SizeError] if file content exceeds max_size
    def self.load_file(path, **opts)
      Loader.load_file(path, **opts)
    end

    # Safely dumps data to a YAML string with type validation.
    #
    # @param data [Object] the data to serialize
    # @param permitted_classes [Array<Class>] additional classes allowed for serialization
    # @return [String] the YAML string
    # @raise [Error] if data contains unsafe types
    def self.dump(data, permitted_classes: [])
      Loader.dump(data, permitted_classes: permitted_classes)
    end

    # Safely dumps data to a YAML file with type validation.
    #
    # @param data [Object] the data to serialize
    # @param path [String] path to write the YAML file
    # @param permitted_classes [Array<Class>] additional classes allowed for serialization
    # @return [String] the YAML string written to the file
    # @raise [Error] if data contains unsafe types
    def self.dump_file(data, path, permitted_classes: [])
      Loader.dump_file(data, path, permitted_classes: permitted_classes)
    end

    # Loads and validates a YAML string against a schema in one step.
    #
    # @param string [String] the YAML string to parse
    # @param schema [Schema] the schema to validate against
    # @param opts [Hash] options forwarded to {Loader.load}
    # @return [Object] the parsed and validated YAML data
    # @raise [SchemaError] if validation fails
    def self.load_and_validate(string, schema:, **opts)
      data = Loader.load(string, **opts)
      schema.validate!(data)
      data
    end

    # Sanitizes a YAML string by stripping full-line comments and normalizing whitespace.
    #
    # @param string [String] the raw YAML string
    # @return [String] the cleaned YAML string
    # @raise [Error] if the sanitized string is not valid YAML
    def self.sanitize(string)
      Loader.sanitize(string)
    end

    # Loads a YAML string and deep merges over default values.
    #
    # @param string [String] the YAML string to parse
    # @param defaults [Hash] default values to merge under parsed data
    # @param opts [Hash] options forwarded to {Loader.load}
    # @return [Hash] the merged result with parsed values taking precedence
    def self.load_with_defaults(string, defaults: {}, **opts)
      data = Loader.load(string, **opts)
      Loader.deep_merge(defaults, data || {})
    end

    # Loads multiple YAML sources through the safe loader and deep merges them
    # in order, with later sources winning on conflicts.
    #
    # Each source may be either inline YAML or a path to a YAML file. The
    # following heuristic distinguishes the two: when +as_files+ is +nil+
    # (the default), a String source is treated as a file path if
    # +File.file?(source)+ returns true, and as inline YAML otherwise.
    # Pass +as_files: false+ to force every source to be parsed as inline
    # YAML, or +as_files: true+ to force every source to be read as a file.
    #
    # All sources are loaded through {Loader.load} so size, alias, and
    # permitted-class limits passed via +load_opts+ apply uniformly.
    #
    # Merge semantics:
    # - Nested Hashes are merged recursively.
    # - Non-Hash conflicts (including arrays) are replaced by the later
    #   source's value. Arrays are not concatenated.
    # - An empty source list returns an empty Hash.
    #
    # @param sources [Array<String>] inline YAML strings or file paths
    # @param as_files [Boolean, nil] +nil+ auto-detect (default), +true+
    #   treat all sources as file paths, +false+ treat all as inline YAML
    # @param load_opts [Hash] options forwarded to {Loader.load}
    #   (e.g. +permitted_classes:+, +max_aliases:+, +max_size:+)
    # @return [Hash] the deeply merged result
    # @raise [ArgumentError] if any source does not parse to a Hash
    # @raise [SizeError] if a source exceeds max_size
    def self.merge(*sources, as_files: nil, **load_opts)
      sources.each_with_index.reduce({}) do |acc, (source, idx)|
        result = load_source(source, idx, as_files, load_opts)
        unless result.is_a?(Hash)
          raise ArgumentError,
                "merge sources must yield Hash, got #{result.class} from source #{idx}"
        end
        Loader.deep_merge(acc, result)
      end
    end

    # Loads a single source for {.merge}, applying the file/inline heuristic.
    #
    # @param source [String] inline YAML or file path
    # @param idx [Integer] source index (used in error messages)
    # @param as_files [Boolean, nil] override flag from {.merge}
    # @param load_opts [Hash] options forwarded to {Loader.load}
    # @return [Object] the parsed YAML value
    def self.load_source(source, idx, as_files, load_opts)
      treat_as_file =
        case as_files
        when true then true
        when false then false
        else source.is_a?(String) && File.file?(source)
        end

      if treat_as_file
        Loader.load_file(source, **load_opts)
      else
        unless source.is_a?(String)
          raise ArgumentError,
                "merge sources must be String YAML or file paths, got #{source.class} at index #{idx}"
        end
        Loader.load(source, **load_opts)
      end
    end

    private_class_method :load_source
  end
end
