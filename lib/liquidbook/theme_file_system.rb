# frozen_string_literal: true

module Liquidbook
  # FileSystem implementation for Liquid's render tag.
  # Resolves template names by searching snippets/ directory.
  class ThemeFileSystem
    VALID_NAME = /\A[a-zA-Z0-9_-]+\z/

    def initialize(theme_root)
      @theme_root = theme_root
    end

    def read_template_file(template_name)
      raise Liquid::FileSystemError, "Illegal template name '#{template_name}'" unless VALID_NAME.match?(template_name)

      path = full_path(template_name)
      raise Liquid::FileSystemError, "No such template '#{template_name}'" unless path

      File.read(path)
    end

    private

    def full_path(template_name)
      path = File.join(@theme_root, "snippets", "#{template_name}.liquid")
      path if File.exist?(path)
    end
  end
end
