# frozen_string_literal: true

require "spec_helper"

RSpec.describe Liquidbook::MockData do
  # FIXTURE_THEME/.liquid-preview/mocks.yml で product.title と product.price をオーバーライド

  describe "#to_assigns" do
    subject(:assigns) { described_class.new.to_assigns }

    it "includes default fixture keys" do
      expect(assigns).to have_key("shop")
      expect(assigns).to have_key("product")
      expect(assigns).to have_key("cart")
      expect(assigns).to have_key("collection")
      expect(assigns).to have_key("customer")
    end

    it "deep-merges user mocks.yml on top of defaults" do
      # fixture mocks.yml: product.title: "Override Product"
      expect(assigns["product"]["title"]).to eq("Override Product")
    end

    it "preserves default keys not overridden by user mocks" do
      # default_mocks.yml の product.handle はオーバーライドされていない
      expect(assigns["product"]["handle"]).to eq("sample-product")
    end

    it "returns a distinct top-level hash each time on the same instance" do
      # 同一インスタンスで to_assigns を2回呼び、トップレベルキーの変更が影響しないことを確認
      mock = described_class.new
      a = mock.to_assigns
      b = mock.to_assigns
      a["new_key"] = "injected"
      expect(b).not_to have_key("new_key")
    end
  end

  describe "#with_section" do
    it "adds a section key with settings and blocks from schema parser" do
      parser = instance_double(
        Liquidbook::SchemaParser,
        default_settings: { "title" => "Hello" },
        default_blocks: [{ "type" => "slide", "settings" => {} }]
      )
      assigns = described_class.new.with_section(parser)
      expect(assigns["section"]["settings"]["title"]).to eq("Hello")
      expect(assigns["section"]["blocks"].first["type"]).to eq("slide")
    end

    it "preserves other mock data alongside section" do
      parser = instance_double(
        Liquidbook::SchemaParser,
        default_settings: {},
        default_blocks: []
      )
      assigns = described_class.new.with_section(parser)
      expect(assigns).to have_key("product")
      expect(assigns).to have_key("section")
    end
  end
end
