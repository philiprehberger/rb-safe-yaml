# frozen_string_literal: true

require 'spec_helper'
require 'date'
require 'fileutils'
require 'tempfile'
require 'tmpdir'

TestStruct = Struct.new(:table, keyword_init: true)

RSpec.describe Philiprehberger::SafeYaml do
  it 'has a version number' do
    expect(Philiprehberger::SafeYaml::VERSION).not_to be_nil
  end

  describe '.load' do
    it 'loads a valid YAML string' do
      yaml = "name: Alice\nage: 30\n"
      result = described_class.load(yaml)
      expect(result).to eq('name' => 'Alice', 'age' => 30)
    end

    it 'returns nil for an empty string' do
      expect(described_class.load('')).to be_nil
    end

    it 'returns nil for a nil-valued YAML string' do
      expect(described_class.load("---\n")).to be_nil
    end

    it 'rejects unsafe classes by default' do
      yaml = "--- !ruby/object:TestStruct\ntable:\n  name: evil\n"
      expect { described_class.load(yaml) }.to raise_error(Psych::DisallowedClass)
    end

    it 'allows permitted_classes to be specified' do
      yaml = "--- !ruby/object:TestStruct\ntable:\n  name: test\n"
      result = described_class.load(yaml, permitted_classes: [TestStruct])
      expect(result).to be_a(TestStruct)
    end

    it 'raises SizeError when input exceeds max_size' do
      yaml = "data: #{'x' * 100}\n"
      expect { described_class.load(yaml, max_size: 10) }.to raise_error(
        Philiprehberger::SafeYaml::SizeError, /exceeds maximum size/
      )
    end

    it 'does not raise when input is within max_size' do
      yaml = "ok: true\n"
      expect { described_class.load(yaml, max_size: 1000) }.not_to raise_error
    end
  end

  describe '.load_file' do
    it 'loads a valid YAML file' do
      file = Tempfile.new(['test', '.yml'])
      file.write("key: value\n")
      file.close

      result = described_class.load_file(file.path)
      expect(result).to eq('key' => 'value')
    ensure
      file&.unlink
    end

    it 'raises Errno::ENOENT for a missing file' do
      expect { described_class.load_file('/nonexistent/file.yml') }.to raise_error(Errno::ENOENT)
    end

    it 'raises SizeError for an oversized file' do
      file = Tempfile.new(['big', '.yml'])
      file.write("data: #{'x' * 200}\n")
      file.close

      expect { described_class.load_file(file.path, max_size: 10) }.to raise_error(
        Philiprehberger::SafeYaml::SizeError
      )
    ensure
      file&.unlink
    end

    it 'returns nil for an empty file' do
      file = Tempfile.new(['empty', '.yml'])
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

    describe '#validate!' do
      it 'passes for valid data' do
        data = { 'name' => 'Alice', 'age' => 30 }
        expect(schema.validate!(data)).to be true
      end

      it 'passes when optional keys are present with correct type' do
        data = { 'name' => 'Alice', 'age' => 30, 'email' => 'a@b.com' }
        expect(schema.validate!(data)).to be true
      end

      it 'raises SchemaError when a required key is missing' do
        data = { 'name' => 'Alice' }
        expect { schema.validate!(data) }.to raise_error(
          Philiprehberger::SafeYaml::SchemaError, /missing required key: age/
        )
      end

      it 'raises SchemaError when a key has the wrong type' do
        data = { 'name' => 'Alice', 'age' => 'thirty' }
        expect { schema.validate!(data) }.to raise_error(
          Philiprehberger::SafeYaml::SchemaError, /expected Integer, got String/
        )
      end

      it 'raises SchemaError when data is not a Hash' do
        expect { schema.validate!('not a hash') }.to raise_error(
          Philiprehberger::SafeYaml::SchemaError, /expected a Hash/
        )
      end
    end

    describe '#validate' do
      it 'returns valid result for correct data' do
        data = { 'name' => 'Alice', 'age' => 30 }
        result = schema.validate(data)
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end

      it 'returns errors for invalid data' do
        data = { 'name' => 123 }
        result = schema.validate(data)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(/expected String, got Integer/)
        expect(result[:errors]).to include(/missing required key: age/)
      end

      it 'does not error on missing optional keys' do
        data = { 'name' => 'Alice', 'age' => 30 }
        result = schema.validate(data)
        expect(result[:valid]).to be true
      end

      it 'errors when optional key has wrong type' do
        data = { 'name' => 'Alice', 'age' => 30, 'email' => 123 }
        result = schema.validate(data)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(/key email: expected String, got Integer/)
      end
    end
  end

  describe '.load advanced' do
    it 'loads nested hashes' do
      yaml = "parent:\n  child: value\n"
      result = described_class.load(yaml)
      expect(result).to eq('parent' => { 'child' => 'value' })
    end

    it 'loads arrays' do
      yaml = "items:\n  - one\n  - two\n  - three\n"
      result = described_class.load(yaml)
      expect(result['items']).to eq(%w[one two three])
    end

    it 'loads deeply nested structures' do
      yaml = "a:\n  b:\n    c:\n      d: deep\n"
      result = described_class.load(yaml)
      expect(result['a']['b']['c']['d']).to eq('deep')
    end

    it 'loads booleans' do
      yaml = "flag: true\nother: false\n"
      result = described_class.load(yaml)
      expect(result['flag']).to be true
      expect(result['other']).to be false
    end

    it 'loads integers and floats' do
      yaml = "int: 42\nfloat: 3.14\n"
      result = described_class.load(yaml)
      expect(result['int']).to eq(42)
      expect(result['float']).to be_within(0.001).of(3.14)
    end

    it 'loads null values' do
      yaml = "key: null\n"
      result = described_class.load(yaml)
      expect(result['key']).to be_nil
    end

    it 'enforces max_size at exact boundary' do
      yaml = "ok: true\n"
      expect { described_class.load(yaml, max_size: yaml.bytesize) }.not_to raise_error
      expect { described_class.load(yaml, max_size: yaml.bytesize - 1) }.to raise_error(
        Philiprehberger::SafeYaml::SizeError
      )
    end

    it 'loads array at top level' do
      yaml = "- one\n- two\n"
      result = described_class.load(yaml)
      expect(result).to eq(%w[one two])
    end

    it 'loads string-only document' do
      yaml = "--- hello\n"
      result = described_class.load(yaml)
      expect(result).to eq('hello')
    end
  end

  describe Philiprehberger::SafeYaml::Schema do
    describe 'advanced validation' do
      it 'validates schema with no fields against a hash' do
        empty_schema = described_class.new
        expect(empty_schema.validate!({ 'anything' => 'goes' })).to be true
      end

      it 'validates schema with no fields against empty hash' do
        empty_schema = described_class.new
        expect(empty_schema.validate!({})).to be true
      end

      it 'validates Array type fields' do
        array_schema = described_class.new do
          required :tags, Array
        end
        expect(array_schema.validate!({ 'tags' => %w[a b] })).to be true
      end

      it 'rejects wrong type for Array field' do
        array_schema = described_class.new do
          required :tags, Array
        end
        result = array_schema.validate({ 'tags' => 'not-an-array' })
        expect(result[:valid]).to be false
      end

      it 'validates Hash type fields' do
        hash_schema = described_class.new do
          required :meta, Hash
        end
        expect(hash_schema.validate!({ 'meta' => { 'k' => 'v' } })).to be true
      end

      it 'collects multiple errors at once' do
        strict = described_class.new do
          required :a, String
          required :b, Integer
          required :c, Array
        end
        result = strict.validate({})
        expect(result[:errors].length).to eq(3)
      end

      it 'validates Float type' do
        float_schema = described_class.new do
          required :score, Float
        end
        expect(float_schema.validate!({ 'score' => 9.5 })).to be true
      end

      it 'raises SchemaError with semicolon-joined message for multiple errors' do
        strict = described_class.new do
          required :a, String
          required :b, String
        end
        expect { strict.validate!({}) }.to raise_error(
          Philiprehberger::SafeYaml::SchemaError, /;/
        )
      end
    end
  end

  describe '.dump' do
    it 'dumps safe data to YAML string' do
      data = { 'name' => 'test', 'count' => 42 }
      result = described_class.dump(data)
      expect(YAML.safe_load(result)).to eq(data)
    end

    it 'dumps arrays' do
      data = [1, 'two', 3.0, true, nil]
      result = described_class.dump(data)
      expect(YAML.safe_load(result)).to eq(data)
    end

    it 'raises for unsafe types' do
      expect { described_class.dump({ 'key' => Object.new }) }.to raise_error(Philiprehberger::SafeYaml::Error)
    end

    it 'allows permitted classes' do
      data = { 'date' => Date.today }
      expect { described_class.dump(data, permitted_classes: [Date]) }.not_to raise_error
    end
  end

  describe '.dump_file' do
    let(:tmpdir) { Dir.mktmpdir }
    let(:output_path) { File.join(tmpdir, 'output.yml') }

    after { FileUtils.remove_entry(tmpdir) }

    it 'writes YAML to file' do
      data = { 'host' => 'localhost', 'port' => 3000 }
      described_class.dump_file(data, output_path)
      expect(File.exist?(output_path)).to be true
      expect(YAML.safe_load_file(output_path)).to eq(data)
    end

    it 'returns the YAML string' do
      data = { 'key' => 'value' }
      result = described_class.dump_file(data, output_path)
      expect(result).to be_a(String)
    end
  end
end
