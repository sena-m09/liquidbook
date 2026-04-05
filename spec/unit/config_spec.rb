# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe Liquidbook::Config do
  subject(:config) { described_class.new }

  describe "#head_tags_html" do
    it "passes raw HTML entries through unchanged" do
      tags = config.head_tags_html
      expect(tags).to include('<meta name="preview" content="true">')
    end

    it "converts .css file paths to <link> tags with /__imports__/ URL" do
      css_tag = config.head_tags_html.find { |t| t.include?("stylesheet") }
      expect(css_tag).not_to be_nil
      expect(css_tag).to include("/__imports__/")
    end
  end

  describe "#import_files" do
    it "returns a hash keyed by /__imports__/ serve paths" do
      expect(config.import_files.keys).to all(start_with("/__imports__/"))
    end

    it "maps serve path to absolute file path" do
      # config.yml has one file entry: ./assets/styles.css
      expect(config.import_files.values.length).to eq(1)
      expect(config.import_files.values.first).to end_with("assets/styles.css")
    end
  end

  describe "#port" do
    it "returns the configured port" do
      expect(config.port).to eq(4567)
    end
  end

  describe "#host" do
    it "returns the configured host" do
      expect(config.host).to eq("127.0.0.1")
    end
  end

  describe "#[]" do
    it "provides hash-style access to config values" do
      expect(config["port"]).to eq(4567)
    end
  end

  # config.yml が存在しない場合のデフォルト値テスト
  context "when config.yml is absent" do
    let(:empty_root) { Dir.mktmpdir("liquidbook_test_") }

    before do
      Liquidbook.root = empty_root
      Liquidbook.reset!
    end

    after { FileUtils.remove_entry(empty_root) }

    it "returns empty head_tags_html" do
      expect(described_class.new(theme_root: empty_root).head_tags_html).to eq([])
    end

    it "returns default port 4567" do
      expect(described_class.new(theme_root: empty_root).port).to eq(4567)
    end

    it "returns default host 127.0.0.1" do
      expect(described_class.new(theme_root: empty_root).host).to eq("127.0.0.1")
    end
  end
end
