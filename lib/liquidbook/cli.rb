# frozen_string_literal: true

require "thor"

module Liquidbook
  class CLI < Thor
    default_command :server

    desc "server", "Start the preview server"
    option :port, type: :numeric, default: 4567, aliases: "-p", desc: "Port number"
    option :host, type: :string, default: "127.0.0.1", aliases: "-H", desc: "Host to bind"
    option :root, type: :string, default: ".", aliases: "-r", desc: "Theme root directory"
    def server
      theme_root = File.expand_path(options[:root])
      Liquidbook.root = theme_root

      puts "Liquidbook v#{VERSION}"
      puts "Theme root: #{theme_root}"
      puts "Server: http://#{options[:host]}:#{options[:port]}"
      puts ""

      sections = Dir.glob(File.join(theme_root, "sections", "*.liquid")).size
      snippets = Dir.glob(File.join(theme_root, "snippets", "*.liquid")).size
      puts "Found #{sections} sections, #{snippets} snippets"
      puts ""

      Server::App.set :port, options[:port]
      Server::App.set :bind, options[:host]
      Server::App.run!
    end

    desc "render TEMPLATE", "Render a single template to stdout"
    option :root, type: :string, default: ".", aliases: "-r", desc: "Theme root directory"
    def render(template)
      theme_root = File.expand_path(options[:root])
      Liquidbook.root = theme_root

      renderer = ThemeRenderer.new(theme_root: theme_root)

      if template.start_with?("sections/") || template.start_with?("snippets/")
        dir, name = template.split("/", 2)
        name = name.sub(/\.liquid$/, "")
        html = dir == "sections" ? renderer.render_section(name) : renderer.render_snippet(name)
      else
        html = renderer.render_section(template.sub(/\.liquid$/, ""))
      end

      puts html
    rescue Liquidbook::Error => e
      warn "Error: #{e.message}"
      exit 1
    end

    desc "version", "Show version"
    def version
      puts "liquidbook #{VERSION}"
    end
  end
end
