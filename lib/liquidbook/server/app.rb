# frozen_string_literal: true

require "sinatra/base"
require "json"

module Liquidbook
  module Server
    class App < Sinatra::Base
      set :views, File.expand_path("views", __dir__)
      set :public_folder, -> { File.join(Liquidbook.root, "assets") }

      before do
        @nav_sections = ThemeRenderer.new(theme_root: Liquidbook.root).sections
        @nav_snippets = ThemeRenderer.new(theme_root: Liquidbook.root).snippets
        @current_path = request.path_info
      end

      helpers do
        def renderer
          @renderer ||= ThemeRenderer.new(theme_root: Liquidbook.root)
        end

        def config
          Liquidbook.config
        end

        def h(text)
          Rack::Utils.escape_html(text.to_s)
        end

        def head_tags
          config.head_tags_html.join("\n")
        end
      end

      # Index page - list all sections and snippets
      get "/" do
        @sections = renderer.sections
        @snippets = renderer.snippets
        erb :index
      end

      # Preview a section
      get "/sections/:name" do
        name = params[:name]
        begin
          overrides = parse_overrides(params)
          @rendered = renderer.render_section(name, overrides: overrides)
          @name = name
          @type = "section"
          @schema = load_schema("sections", name)
          @params = []
          erb :preview
        rescue Liquidbook::Error => e
          status 404
          "Section not found: #{h(name)}"
        end
      end

      # Preview a snippet
      get "/snippets/:name" do
        name = params[:name]
        begin
          overrides = parse_overrides(params)
          @rendered = renderer.render_snippet(name, overrides: overrides)
          @name = name
          @type = "snippet"
          @schema = {}
          @params = renderer.snippet_params(name)
          erb :preview
        rescue Liquidbook::Error => e
          status 404
          "Snippet not found: #{h(name)}"
        end
      end

      # Serve imported files from config (CSS/JS from arbitrary paths)
      get "/__imports__/*" do
        serve_path = "/__imports__/#{params["splat"].first}"
        file_path = config.import_files[serve_path]

        if file_path && File.exist?(file_path)
          content_type mime_type(File.extname(file_path)) || "application/octet-stream"
          File.read(file_path)
        else
          status 404
          "Import not found: #{h(serve_path)}"
        end
      end

      # Serve theme assets
      get "/assets/*" do
        file_path = File.join(Liquidbook.root, "assets", params["splat"].first)
        if File.exist?(file_path)
          content_type mime_type(File.extname(file_path)) || "application/octet-stream"
          File.read(file_path)
        else
          status 404
          "Asset not found"
        end
      end

      # API: re-render with params (for live reload + param editing)
      post "/api/render/:type/:name" do
        content_type :json
        type = params[:type]
        name = params[:name]

        begin
          body = JSON.parse(request.body.read) rescue {}
          overrides = body["overrides"] || {}

          html = case type
                 when "sections" then renderer.render_section(name, overrides: overrides)
                 when "snippets" then renderer.render_snippet(name, overrides: overrides)
                 else raise Error, "Unknown type: #{type}"
                 end
          { html: html }.to_json
        rescue Liquidbook::Error => e
          status 404
          { error: e.message }.to_json
        end
      end

      # API: re-render (GET for live reload)
      get "/api/render/:type/:name" do
        content_type :json
        type = params[:type]
        name = params[:name]

        begin
          html = case type
                 when "sections" then renderer.render_section(name)
                 when "snippets" then renderer.render_snippet(name)
                 else raise Error, "Unknown type: #{type}"
                 end
          { html: html }.to_json
        rescue Liquidbook::Error => e
          status 404
          { error: e.message }.to_json
        end
      end

      private

      def load_schema(dir, name)
        path = File.join(Liquidbook.root, dir, "#{name}.liquid")
        return {} unless File.exist?(path)

        SchemaParser.new(File.read(path)).parse
      end

      def parse_overrides(params)
        overrides = {}
        params.each do |key, value|
          next if %w[name splat captures].include?(key)

          overrides[key] = value
        end
        overrides
      end
    end
  end
end
