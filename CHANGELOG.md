# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-05-03

### Added

- `TemplateAnalyzer`: Liquid AST を走査してテンプレートで参照される変数を自動検出（[ADR-0001](docs/adr/0001-template-variable-detection-strategy.md)）
- `ParameterMerger`: 自動検出した変数と `@param` メタデータをマージして `ThemeRenderer` に統合
- `FilterTypeMap` によるフィルタベースの型推論（適用されているフィルタ名から変数の型を推定）
- サイドバーにテンプレート検索窓を追加（`q` URL パラメータで画面遷移後も検索状態を保持）
- サイドバー初期表示時にアクティブなテンプレートまで自動スクロール
- 動作確認用 `example/` テーマ（`bundle exec liquidbook server -r example` で起動）
- ADR-0001: テンプレート変数検出戦略の決定記録

### Changed

- カスタム `RenderTag` を削除し公式 Liquid `render` タグ + `ThemeFileSystem` に置き換え（探索対象を `snippets/` のみに限定し、`ThemeRenderer` で `ThemeFileSystem` をキャッシュ）
- スニペットパラメータ編集フォームを GET + クエリパラメータ方式に変更し、URL でプレビュー状態をブックマーク/共有可能に（`Rendered HTML` ビューも同期）
- `example/` ディレクトリを gem パッケージから除外

### Removed

- `POST /api/render/:type/:name` および `GET /api/render/:type/:name` エンドポイント、および 1.5 秒間隔のライブリロードポーリング

## [0.1.1] - 2026-04-09

### Added

- グレースフルなサーバー停止のための PID ファイル管理と `stop` コマンド
- CD ワークフロー: タグ push 時に CHANGELOG から GitHub Release を自動生成
- CD ワークフロー: `workflow_dispatch` による RubyGems への手動公開

### Changed

- CI ワークフローのファイル名を `test.yml` から `ci.yml` にリネーム

## [0.1.0] - 2026-04-07

### Added

- モックデータをサポートする Liquid テンプレートレンダリングエンジン
- Sinatra によるブラウザベースのプレビューサーバー
- Thor による CLI コマンド (`start`, `stop`)
- Listen による自動リロード対応のファイル監視
- セクション/スニペットテンプレートのサポート
- RSpec によるユニットテストと統合テスト
- GitHub Actions による CI パイプライン (Ruby 3.2 - 4.0)
