# CLAUDE.md

## コーディング方針

- コードを変更・追加するとき、設計判断の「なぜ（Why）」が自明でなければコメントを残す
  - 「何をしているか（What）」はコードで表現する。コメントにしない
  - 例: Shopify 互換性のために本来不要な処理をしている、パフォーマンス上の理由で構造を変えた、等

## プロジェクト概要

- Shopify Liquid テンプレートのプレビューサーバー（Storybook 的なツール）
- Ruby gem（Liquid 5.0 / Sinatra / Puma）

## 開発コマンド

- テスト: `bundle exec rspec`
- サーバー起動: `bundle exec liquidbook serve`
