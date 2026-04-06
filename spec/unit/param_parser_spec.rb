# frozen_string_literal: true

require "spec_helper"

RSpec.describe Liquidbook::ParamParser do
  let(:source) do
    <<~LIQUID
      {% comment %}
        @param {String} title [My Card] - Card heading text
        @param {Number} price [1980] - Price in yen
        @param {Boolean} featured [false] - Show featured badge
        @param {Float} rating - No default given
      {% endcomment %}
      <div>{{ title }}</div>
    LIQUID
  end

  describe "#parse" do
    subject(:params) { described_class.new(source).parse }

    it "returns one entry per @param line" do
      expect(params.length).to eq(4)
    end

    # 型の正規化テスト
    it "normalizes String type to text" do
      expect(params[0]["type"]).to eq("text")
    end

    it "normalizes Number type to number" do
      expect(params[1]["type"]).to eq("number")
    end

    it "normalizes Boolean type to checkbox" do
      expect(params[2]["type"]).to eq("checkbox")
    end

    it "normalizes Float type to number" do
      expect(params[3]["type"]).to eq("number")
    end

    # デフォルト値の型変換テスト
    it "keeps String default as string" do
      expect(params[0]["default"]).to eq("My Card")
    end

    it "coerces Number default to integer" do
      expect(params[1]["default"]).to eq(1980)
    end

    it "coerces Boolean default to false" do
      expect(params[2]["default"]).to eq(false)
    end

    it "uses sample value when no default is provided" do
      # Float without default -> 1.0
      expect(params[3]["default"]).to eq(1.0)
    end

    it "captures description text" do
      expect(params[0]["description"]).to eq("Card heading text")
    end

    it "returns empty array for source with no @param comments" do
      expect(described_class.new("<p>hi</p>").parse).to eq([])
    end
  end

  describe "#default_assigns" do
    it "returns a hash of name => coerced default" do
      assigns = described_class.new(source).default_assigns
      expect(assigns).to eq(
        "title" => "My Card",
        "price" => 1980,
        "featured" => false,
        "rating" => 1.0
      )
    end
  end
end
