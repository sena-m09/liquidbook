# frozen_string_literal: true

require "spec_helper"

RSpec.describe Liquidbook::Server::App, type: :integration do
  before(:all) do
    Liquidbook::Server::App.set :environment, :test
  end

  def app
    Liquidbook::Server::App
  end

  # GET / — セクション/スニペット一覧
  describe "GET /" do
    it "returns 200 and lists sections and snippets" do
      get "/"
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include("hero")
      expect(last_response.body).to include("card")
    end
  end

  # GET /sections/:name — セクションプレビュー
  describe "GET /sections/:name" do
    context "with an existing section" do
      it "returns 200 with rendered content" do
        get "/sections/hero"
        expect(last_response.status).to eq(200)
        expect(last_response.body).to include("Welcome")
      end
    end

    context "with a missing section" do
      it "returns 404" do
        get "/sections/does_not_exist"
        expect(last_response.status).to eq(404)
      end
    end
  end

  # GET /snippets/:name — スニペットプレビュー
  describe "GET /snippets/:name" do
    context "with an existing snippet" do
      it "returns 200 with rendered snippet using @param defaults" do
        get "/snippets/card"
        expect(last_response.status).to eq(200)
        expect(last_response.body).to include("My Card")
        expect(last_response.body).to include("¥1980")
      end
    end

    context "with a missing snippet" do
      it "returns 404" do
        get "/snippets/does_not_exist"
        expect(last_response.status).to eq(404)
      end
    end
  end

  # POST /api/render/:type/:name — 再レンダリング
  describe "POST /api/render/:type/:name" do
    it "returns JSON with rendered html for a section" do
      payload = { overrides: {} }.to_json
      post "/api/render/sections/hero", payload, "CONTENT_TYPE" => "application/json"
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body).to have_key("html")
      expect(body["html"]).to include("hero")
    end

    it "applies overrides to snippet rendering" do
      payload = { overrides: { "title" => "API Title" } }.to_json
      post "/api/render/snippets/card", payload, "CONTENT_TYPE" => "application/json"
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body["html"]).to include("API Title")
    end

    it "returns 404 for unknown type" do
      post "/api/render/layouts/base", "{}", "CONTENT_TYPE" => "application/json"
      expect(last_response.status).to eq(404)
      body = JSON.parse(last_response.body)
      expect(body).to have_key("error")
    end

    it "returns 404 for missing template" do
      post "/api/render/sections/ghost", "{}", "CONTENT_TYPE" => "application/json"
      expect(last_response.status).to eq(404)
      body = JSON.parse(last_response.body)
      expect(body["error"]).to include("ghost")
    end
  end

  # GET /__imports__/* — config で宣言されたファイルの配信
  describe "GET /__imports__/*" do
    # Config のロジックから実際の serve path を取得（再実装を避ける）
    let(:serve_path) do
      Liquidbook::Config.new.import_files.keys.first
    end

    it "serves the file when the import path exists" do
      get serve_path
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include("fixture")
    end

    it "returns 404 for an unknown import path" do
      get "/__imports__/nonexistent_file.css"
      expect(last_response.status).to eq(404)
    end
  end
end
