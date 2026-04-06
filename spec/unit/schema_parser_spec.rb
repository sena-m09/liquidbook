# frozen_string_literal: true

require "spec_helper"

RSpec.describe Liquidbook::SchemaParser do
  # {% schema %} ブロックを持つソース
  let(:source_with_schema) do
    <<~LIQUID
      <h1>{{ section.settings.title }}</h1>
      {% schema %}
      {
        "name": "Hero",
        "settings": [
          { "id": "title", "type": "text", "default": "Hello" },
          { "id": "count", "type": "number", "default": 3 }
        ],
        "blocks": [
          { "type": "slide", "settings": [{ "id": "img", "default": "a.jpg" }] }
        ]
      }
      {% endschema %}
    LIQUID
  end

  # ダッシュ付きの {% schema %} タグ（空白制御）
  let(:source_with_dash_schema) do
    <<~LIQUID
      <p>content</p>
      {%- schema -%}
      { "name": "Dash", "settings": [{ "id": "x", "default": 1 }] }
      {%- endschema -%}
    LIQUID
  end

  let(:source_without_schema) { "<p>{{ product.title }}</p>" }
  let(:source_invalid_json) { '{% schema %}{ bad json }{% endschema %}<p>x</p>' }

  describe "#parse" do
    it "returns parsed schema hash when schema block is present" do
      result = described_class.new(source_with_schema).parse
      expect(result["name"]).to eq("Hero")
      expect(result["settings"].length).to eq(2)
    end

    it "parses schema with whitespace-control dashes" do
      result = described_class.new(source_with_dash_schema).parse
      expect(result["name"]).to eq("Dash")
    end

    it "returns empty hash when no schema block is present" do
      expect(described_class.new(source_without_schema).parse).to eq({})
    end

    it "returns empty hash and warns on invalid JSON" do
      # 不正なJSONでも例外を上げずに {} を返す
      parser = described_class.new(source_invalid_json)
      result = nil
      expect { result = parser.parse }.to output(/Warning/).to_stderr
      expect(result).to eq({})
    end
  end

  describe "#template_without_schema" do
    it "strips the schema block from the source" do
      result = described_class.new(source_with_schema).template_without_schema
      expect(result).not_to include("{% schema %}")
      expect(result).not_to include("endschema")
      expect(result).to include("<h1>")
    end

    it "returns source unchanged when no schema is present" do
      result = described_class.new(source_without_schema).template_without_schema
      expect(result).to eq(source_without_schema)
    end
  end

  describe "#default_settings" do
    it "builds a hash of id => default pairs from schema settings" do
      result = described_class.new(source_with_schema).default_settings
      expect(result).to eq("title" => "Hello", "count" => 3)
    end

    it "returns empty hash when no schema is present" do
      expect(described_class.new(source_without_schema).default_settings).to eq({})
    end
  end

  describe "#default_blocks" do
    it "builds block array with type and settings defaults" do
      result = described_class.new(source_with_schema).default_blocks
      expect(result.length).to eq(1)
      expect(result.first).to eq("type" => "slide", "settings" => { "img" => "a.jpg" })
    end

    it "skips blocks without a type" do
      source = <<~LIQUID
        {% schema %}
        { "blocks": [{ "settings": [] }] }
        {% endschema %}
      LIQUID
      expect(described_class.new(source).default_blocks).to eq([])
    end
  end
end
