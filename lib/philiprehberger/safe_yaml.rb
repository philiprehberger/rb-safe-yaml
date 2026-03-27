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
  end
end
