# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe Philiprehberger::SafeYaml do
  it "has a version number" do
    expect(Philiprehberger::SafeYaml::VERSION).not_to be_nil
  end

  describe ".load" do
    it "loads a valid YAML string" do
      yaml = "name: Alice\nage: 30\n"
      result = described_class.load(yaml)
      expect(result).to eq("name" => "Alice", "age" => 30)
    end

    it "returns nil for an empty string" do
      expect(described_class.load("")).to be_nil
    end

    it "returns nil for a nil-valued YAML string" do
      expect(described_class.load("---\n")).to be_nil
    end

    it "rejects unsafe classes by default" do
      yaml = "--- !ruby/object:OpenStruct\ntable:\n  name: evil\n"
      expect { described_class.load(yaml) }.to raise_error(Psych::DisallowedClass)
    end

    it "allows permitted_classes to be specified" do
      yaml = "--- !ruby/object:OpenStruct\ntable:\n  name: test\n"
      result = described_class.load(yaml, permitted_classes: [OpenStruct])
      expect(result).to be_a(OpenStruct)
    end

    it "raises SizeError when input exceeds max_size" do
      yaml = "data: #{"x" * 100}\n"
      expect { described_class.load(yaml, max_size: 10) }.to raise_error(
        Philiprehberger::SafeYaml::SizeError, /exceeds maximum size/
      )
    end

    it "does not raise when input is within max_size" do
      yaml = "ok: true\n"
      expect { described_class.load(yaml, max_size: 1000) }.not_to raise_error
    end
  end

  describe ".load_file" do
    it "loads a valid YAML file" do
      file = Tempfile.new(["test", ".yml"])
      file.write("key: value\n")
      file.close

      result = described_class.load_file(file.path)
      expect(result).to eq("key" => "value")
    ensure
      file&.unlink
    end

    it "raises Errno::ENOENT for a missing file" do
      expect { described_class.load_file("/nonexistent/file.yml") }.to raise_error(Errno::ENOENT)
    end

    it "raises SizeError for an oversized file" do
      file = Tempfile.new(["big", ".yml"])
      file.write("data: #{"x" * 200}\n")
      file.close

      expect { described_class.load_file(file.path, max_size: 10) }.to raise_error(
        Philiprehberger::SafeYaml::SizeError
      )
    ensure
      file&.unlink
    end

    it "returns nil for an empty file" do
      file = Tempfile.new(["empty", ".yml"])
      file.close

      expect(described_class.load_file(file.path)).to be_nil
    ensure
      file&.unlink
    end
  end

  describe Philiprehberger::SafeYaml::Schema do
    let(:schema) do
      described_class.new do
        required :name, String
        required :age, Integer
        optional :email, String
      end
    end

    describe "#validate!" do
      it "passes for valid data" do
        data = { "name" => "Alice", "age" => 30 }
        expect(schema.validate!(data)).to be true
      end

      it "passes when optional keys are present with correct type" do
        data = { "name" => "Alice", "age" => 30, "email" => "a@b.com" }
        expect(schema.validate!(data)).to be true
      end

      it "raises SchemaError when a required key is missing" do
        data = { "name" => "Alice" }
        expect { schema.validate!(data) }.to raise_error(
          Philiprehberger::SafeYaml::SchemaError, /missing required key: age/
        )
      end

      it "raises SchemaError when a key has the wrong type" do
        data = { "name" => "Alice", "age" => "thirty" }
        expect { schema.validate!(data) }.to raise_error(
          Philiprehberger::SafeYaml::SchemaError, /expected Integer, got String/
        )
      end

      it "raises SchemaError when data is not a Hash" do
        expect { schema.validate!("not a hash") }.to raise_error(
          Philiprehberger::SafeYaml::SchemaError, /expected a Hash/
        )
      end
    end

    describe "#validate" do
      it "returns valid result for correct data" do
        data = { "name" => "Alice", "age" => 30 }
        result = schema.validate(data)
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end

      it "returns errors for invalid data" do
        data = { "name" => 123 }
        result = schema.validate(data)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(/expected String, got Integer/)
        expect(result[:errors]).to include(/missing required key: age/)
      end

      it "does not error on missing optional keys" do
        data = { "name" => "Alice", "age" => 30 }
        result = schema.validate(data)
        expect(result[:valid]).to be true
      end

      it "errors when optional key has wrong type" do
        data = { "name" => "Alice", "age" => 30, "email" => 123 }
        result = schema.validate(data)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(/key email: expected String, got Integer/)
      end
    end
  end
end
