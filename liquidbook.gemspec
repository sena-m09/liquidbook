# frozen_string_literal: true

require_relative "lib/liquidbook/version"

Gem::Specification.new do |spec|
  spec.name = "liquidbook"
  spec.version = Liquidbook::VERSION
  spec.authors = ["sena-m09"]
  spec.email = ["sena-murakami@gaji.jp"]

  spec.summary = "Storybook-like preview server for Shopify Liquid sections and snippets"
  spec.description = "A development tool that renders Shopify Liquid templates locally with mock data, " \
                     "providing a browser-based preview for sections and snippets."
  spec.homepage = "https://github.com/sena-m09/liquidbook"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "liquid", "~> 5.0"
  spec.add_dependency "sinatra", "~> 4.0"
  spec.add_dependency "rackup", "~> 2.0"
  spec.add_dependency "puma", "~> 6.0"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "listen", "~> 3.9"
end
