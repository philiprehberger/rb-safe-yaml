# frozen_string_literal: true

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
      # @raise [Psych::DisallowedClass] if YAML contains disallowed classes
      def self.load(string, permitted_classes: [], max_aliases: 0, max_size: nil)
        validate_size!(string, max_size)

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
    end
  end
end
