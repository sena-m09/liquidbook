# frozen_string_literal: true

require "liquid"
require_relative "liquidbook/version"
require_relative "liquidbook/config"
require_relative "liquidbook/schema_parser"
require_relative "liquidbook/param_parser"
require_relative "liquidbook/mock_data"
require_relative "liquidbook/filters/shopify_filters"
require_relative "liquidbook/tags/section_tag"
require_relative "liquidbook/tags/render_tag"
require_relative "liquidbook/pid_manager"
require_relative "liquidbook/theme_renderer"
require_relative "liquidbook/server/app"

module Liquidbook
  class Error < StandardError; end

  class << self
    def root
      @root || Dir.pwd
    end

    attr_writer :root

    def environment
      @environment ||= build_environment
    end

    def config
      @config ||= Config.new(theme_root: root)
    end

    # Reset (useful when reloading)
    def reset!
      @environment = nil
      @config = nil
    end

    private

    def build_environment
      Liquid::Environment.build do |e|
        e.register_filter(Filters::ShopifyFilters)
        e.register_tag("section", Tags::SectionTag)
        e.register_tag("render", Tags::RenderTag)
      end
    end
  end
end
