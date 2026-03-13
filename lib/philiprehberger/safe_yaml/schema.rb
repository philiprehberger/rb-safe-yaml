# frozen_string_literal: true

module Philiprehberger
  module SafeYaml
    # DSL-based schema validation for parsed YAML data.
    class Schema
      # @param block [Proc] DSL block defining required and optional fields
      def initialize(&block)
        @fields = []
        instance_eval(&block) if block
      end

      # Declares a required key with an expected type.
      #
      # @param key [String, Symbol] the key that must be present
      # @param type [Class] the expected type of the value
      # @return [void]
      def required(key, type)
        @fields << { key: key.to_s, type: type, required: true }
      end

      # Declares an optional key with an expected type.
      #
      # @param key [String, Symbol] the key that may be present
      # @param type [Class] the expected type if the key is present
      # @return [void]
      def optional(key, type)
        @fields << { key: key.to_s, type: type, required: false }
      end

      # Validates data against the schema, raising on failure.
      #
      # @param data [Hash] the parsed YAML data to validate
      # @return [true] if validation passes
      # @raise [SchemaError] if validation fails
      def validate!(data)
        result = validate(data)
        return true if result[:valid]

        raise SchemaError, result[:errors].join("; ")
      end

      # Validates data against the schema without raising.
      #
      # @param data [Hash] the parsed YAML data to validate
      # @return [Hash] result with :valid (Boolean) and :errors (Array<String>)
      def validate(data)
        errors = collect_errors(data)
        { valid: errors.empty?, errors: errors }
      end

      private

      # Collects all validation errors for the given data.
      #
      # @param data [Hash] the data to validate
      # @return [Array<String>] list of error messages
      def collect_errors(data)
        errors = []
        errors << "expected a Hash, got #{data.class}" unless data.is_a?(Hash)
        return errors unless data.is_a?(Hash)

        @fields.each { |field| errors.concat(validate_field(data, field)) }
        errors
      end

      # Validates a single field against the data.
      #
      # @param data [Hash] the data hash
      # @param field [Hash] the field definition
      # @return [Array<String>] errors for this field
      def validate_field(data, field)
        key = field[:key]
        return missing_error(key, field) unless data.key?(key)
        return type_error(key, field, data[key]) unless data[key].is_a?(field[:type])

        []
      end

      # Returns a missing-key error if the field is required.
      #
      # @param key [String] the missing key
      # @param field [Hash] the field definition
      # @return [Array<String>] error array (empty if optional)
      def missing_error(key, field)
        field[:required] ? ["missing required key: #{key}"] : []
      end

      # Returns a type-mismatch error.
      #
      # @param key [String] the key with wrong type
      # @param field [Hash] the field definition
      # @param value [Object] the actual value
      # @return [Array<String>] single-element error array
      def type_error(key, field, value)
        ["key #{key}: expected #{field[:type]}, got #{value.class}"]
      end
    end
  end
end
