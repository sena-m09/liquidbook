# Liquidbook

[![CI](https://github.com/sena-m09/liquidbook/actions/workflows/test.yml/badge.svg)](https://github.com/sena-m09/liquidbook/actions/workflows/test.yml)

A Storybook-like local preview server for Shopify Liquid templates. Browse and preview your sections and snippets in the browser instantly.

## Features

- Auto-discovers `.liquid` files in `sections/` and `snippets/`
- Generates default setting values from `{% schema %}` blocks
- Supports Shopify-compatible filters and tags (`section`, `render`)
- Load external CSS/JS via `.liquid-preview/config.yml`
- File watching with live reload

## Installation

Add to your Gemfile:

```ruby
gem "liquidbook"
```

Or install directly:

```bash
gem install liquidbook
```

## Usage

### Start the preview server

Run from your Shopify theme root:

```bash
liquidbook server
```

Open `http://127.0.0.1:4567` in your browser to see a list of sections and snippets with live previews.

#### Options

| Option | Short | Default | Description |
|---|---|---|---|
| `--port` | `-p` | `4567` | Port number |
| `--host` | `-H` | `127.0.0.1` | Host to bind |
| `--root` | `-r` | `.` | Theme root directory |

### Render a single template

```bash
liquidbook render sections/header.liquid
```

Outputs the rendered HTML to stdout.

## Configuration

Create `.liquid-preview/config.yml` in your theme root to load external assets into the preview:

```yaml
head:
  - <script src="https://cdn.tailwindcss.com"></script>
  - ../src/styles/main.css
  - ./src/components.js

port: 4567
host: 127.0.0.1
```

`head` entries accept raw HTML tags or file paths. File paths are resolved relative to the theme root.

## Development

```bash
git clone https://github.com/sena-m09/liquidbook.git
cd liquidbook
bin/setup
```

## License

[MIT License](https://opensource.org/licenses/MIT)
