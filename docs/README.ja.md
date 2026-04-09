# Liquidbook

Shopify Liquid テンプレートのローカルプレビューサーバー。Storybook のように、sections や snippets をブラウザ上で即座に確認できます。

## 特徴

- `sections/` や `snippets/` 内の `.liquid` ファイルを自動検出してプレビュー
- `{% schema %}` ブロックからデフォルト設定値を自動生成
- Shopify 互換フィルター・タグ (`section`, `render`) をサポート
- `.liquid-preview/config.yml` で外部 CSS/JS の読み込みに対応
- ファイル変更の自動検知（live reload）

## インストール

Gemfile に追加:

```ruby
gem "liquidbook"
```

または直接インストール:

```bash
gem install liquidbook
```

## 使い方

### プレビューサーバーの起動

Shopify テーマのルートディレクトリで実行:

```bash
liquidbook server
```

ブラウザで `http://127.0.0.1:4567` を開くと、sections / snippets の一覧とプレビューが表示されます。

#### オプション

| オプション | 短縮 | デフォルト | 説明 |
|---|---|---|---|
| `--port` | `-p` | `4567` | ポート番号 |
| `--host` | `-H` | `127.0.0.1` | バインドするホスト |
| `--root` | `-r` | `.` | テーマのルートディレクトリ |

### 単一テンプレートのレンダリング

```bash
liquidbook render sections/header.liquid
```

標準出力に HTML が出力されます。

## 設定

テーマルートに `.liquid-preview/config.yml` を作成すると、プレビューに外部アセットを読み込めます。

```yaml
head:
  - <script src="https://cdn.tailwindcss.com"></script>
  - ../src/styles/main.css
  - ./src/components.js

port: 4567
host: 127.0.0.1
```

`head` エントリには生の HTML タグまたはファイルパスを指定できます。ファイルパスはテーマルートからの相対パスで解決されます。

## 開発

```bash
git clone https://github.com/sena-m09/liquidbook.git
cd liquidbook
bin/setup
```

新しいバージョンのリリース方法は [Release Process](RELEASING.md) を参照してください。

## ライセンス

[MIT License](https://opensource.org/licenses/MIT)
