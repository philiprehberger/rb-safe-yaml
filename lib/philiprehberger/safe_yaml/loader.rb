# frozen_string_literal: true

require 'set'
require 'yaml'

module Philiprehberger
  module SafeYaml
    # Wraps YAML.safe_load with safe defaults and size limits.
    module Loader
      # Safely loads a YAML string with restricted types.
      #
      # @param string [String] the YAML string to parse
      # @param permitted_classes [Array<Class>] classes allowed during deserialization
      # @param max_aliases [Integer] maximum number of aliases allowed (0 disables aliases)
      # @param max_size [Integer, nil] maximum byte size of the input string
      # @return [Object] the parsed YAML object
      # @raise [SizeError] if string exceeds max_size
      # @raise [Error] if alias count exceeds max_aliases
      # @raise [Psych::DisallowedClass] if YAML contains disallowed classes
      def self.load(string, permitted_classes: [], max_aliases: 0, max_size: nil)
        validate_size!(string, max_size)
        validate_alias_count!(string, max_aliases) if max_aliases.positive?

        YAML.safe_load(
          string,
          permitted_classes: permitted_classes,
          permitted_symbols: [],
          aliases: max_aliases.positive?
        )
      end

      # Safely loads a YAML file with restricted types.
      #
      # @param path [String] path to the YAML file
      # @param opts [Hash] options forwarded to {.load}
      # @return [Object] the parsed YAML object
      # @raise [SizeError] if file content exceeds max_size
      # @raise [Errno::ENOENT] if the file does not exist
      def self.load_file(path, **opts)
        content = File.read(path)
        load(content, **opts)
      end

      # Validates that the string does not exceed the maximum size.
      #
      # @param string [String] the string to check
      # @param max_size [Integer, nil] maximum allowed byte size
      # @raise [SizeError] if string exceeds max_size
      def self.validate_size!(string, max_size)
        return if max_size.nil?
        return if string.bytesize <= max_size

        raise SizeError, "YAML input exceeds maximum size of #{max_size} bytes (got #{string.bytesize})"
      end

      private_class_method :validate_size!

      # Validates that the number of aliases does not exceed the limit.
      #
      # @param string [String] the YAML string to scan
      # @param max_aliases [Integer] maximum allowed alias count
      # @raise [Error] if alias count exceeds max_aliases
      def self.validate_alias_count!(string, max_aliases)
        count = string.scan(/\*\w+/).length - string.scan(/&\w+/).length
        return if count <= max_aliases

        raise Error, "YAML input contains #{count} aliases, exceeding limit of #{max_aliases}"
      end

      private_class_method :validate_alias_count!

      # Sanitizes a YAML string by stripping full-line comments and normalizing whitespace.
      #
      # @param string [String] the raw YAML string
      # @return [String] the cleaned YAML string
      # @raise [Error] if the sanitized string is not valid YAML
      def self.sanitize(string)
        lines = string.each_line.grep_v(/\A\s*#/)
        cleaned = lines.join.gsub(/[^\S\n]+$/, '')
        YAML.safe_load(cleaned) # validate syntax
        cleaned
      end

      # Deep merges two hashes, with the overlay taking precedence.
      #
      # @param base [Hash] the default values
      # @param overlay [Hash] the parsed values that override defaults
      # @return [Hash] the merged result
      def self.deep_merge(base, overlay)
        base.merge(overlay) do |_key, old_val, new_val|
          if old_val.is_a?(Hash) && new_val.is_a?(Hash)
            deep_merge(old_val, new_val)
          else
            new_val
          end
        end
      end

      # Safely dumps data to a YAML string with type validation.
      #
      # @param data [Object] the data to serialize
      # @param permitted_classes [Array<Class>] additional classes allowed for serialization
      # @return [String] the YAML string
      # @raise [Error] if data contains unsafe types
      def self.dump(data, permitted_classes: [])
        validate_dumpable!(data, permitted_classes)
        YAML.dump(data)
      end

      # Safely dumps data to a YAML file with type validation.
      #
      # @param data [Object] the data to serialize
      # @param path [String] path to write the YAML file
      # @param permitted_classes [Array<Class>] additional classes allowed for serialization
      # @return [String] the YAML string written to the file
      # @raise [Error] if data contains unsafe types
      def self.dump_file(data, path, permitted_classes: [])
        content = dump(data, permitted_classes: permitted_classes)
        File.write(path, content)
        content
      end

      # Validates that data only contains safe types for serialization.
      #
      # @param obj [Object] the object to validate
      # @param permitted [Array<Class>] additional permitted classes
      # @param seen [Set] object IDs already visited (cycle detection)
      # @raise [Error] if obj contains unsafe types
      def self.validate_dumpable!(obj, permitted, seen = Set.new)
        return if seen.include?(obj.object_id)

        seen.add(obj.object_id)

        safe_types = [String, Integer, Float, TrueClass, FalseClass, NilClass]
        all_allowed = safe_types + Array(permitted)

        case obj
        when Hash
          obj.each do |k, v|
            validate_dumpable!(k, permitted, seen)
            validate_dumpable!(v, permitted, seen)
          end
        when Array
          obj.each { |v| validate_dumpable!(v, permitted, seen) }
        else
          unless all_allowed.any? { |t| obj.is_a?(t) }
            raise Error, "unsafe type for serialization: #{obj.class}"
          end
        end
      end

      private_class_method :validate_dumpable!
    end
  end
end
