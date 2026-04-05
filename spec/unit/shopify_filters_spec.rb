# frozen_string_literal: true

require "spec_helper"

RSpec.describe Liquidbook::Filters::ShopifyFilters do
  # フィルターはモジュールなので、テスト用オブジェクトにインクルードして検証
  let(:ctx) { Class.new { include Liquidbook::Filters::ShopifyFilters }.new }

  describe "#money" do
    it "formats integer as yen" do
      expect(ctx.money(1980)).to eq("¥1980")
    end

    it "returns empty string for nil" do
      expect(ctx.money(nil)).to eq("")
    end

    it "coerces string input" do
      expect(ctx.money("2500")).to eq("¥2500")
    end
  end

  describe "#money_with_currency" do
    it "appends JPY" do
      expect(ctx.money_with_currency(1980)).to eq("¥1980 JPY")
    end
  end

  describe "#handle" do
    it "lowercases and replaces non-alphanumeric with hyphens" do
      expect(ctx.handle("My Product Name!")).to eq("my-product-name")
    end

    it "strips leading and trailing hyphens" do
      expect(ctx.handle("--hello--")).to eq("hello")
    end

    it "returns empty string for nil" do
      expect(ctx.handle(nil)).to eq("")
    end
  end

  describe "#handleize" do
    it "is an alias for handle" do
      expect(ctx.handleize("Hello World")).to eq(ctx.handle("Hello World"))
    end
  end

  describe "#image_url" do
    it "returns src as-is when no dimensions given" do
      expect(ctx.image_url("https://example.com/img.jpg")).to eq("https://example.com/img.jpg")
    end

    it "appends width param" do
      result = ctx.image_url("https://example.com/img.jpg", width: 400)
      expect(result).to eq("https://example.com/img.jpg?width=400")
    end

    it "appends both width and height" do
      result = ctx.image_url("https://example.com/img.jpg", width: 400, height: 300)
      expect(result).to eq("https://example.com/img.jpg?width=400&height=300")
    end

    it "extracts src from Hash input" do
      expect(ctx.image_url({ "src" => "https://example.com/img.jpg" }))
        .to eq("https://example.com/img.jpg")
    end

    it "returns empty string for nil" do
      expect(ctx.image_url(nil)).to eq("")
    end
  end

  describe "#link_to" do
    it "wraps text in an anchor tag" do
      result = ctx.link_to("Click me", "/products/sample")
      expect(result).to eq('<a href="/products/sample">Click me</a>')
    end

    it "includes title attribute when provided" do
      result = ctx.link_to("Click", "/path", "My Title")
      expect(result).to include('title="My Title"')
    end
  end

  describe "#json" do
    it "serializes a hash to JSON string" do
      expect(ctx.json({ "key" => "value" })).to eq('{"key":"value"}')
    end

    it "serializes an array" do
      expect(ctx.json([1, 2, 3])).to eq("[1,2,3]")
    end
  end

  describe "#img_tag" do
    it "returns an img element with loading=lazy" do
      result = ctx.img_tag("https://example.com/photo.jpg")
      expect(result).to include('src="https://example.com/photo.jpg"')
      expect(result).to include('loading="lazy"')
    end
  end

  describe "#asset_url" do
    it "prepends /assets/ to the filename" do
      expect(ctx.asset_url("logo.png")).to eq("/assets/logo.png")
    end
  end
end
