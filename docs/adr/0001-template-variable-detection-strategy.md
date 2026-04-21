# ADR-0001: テンプレート変数検出の戦略

- **Status**: Accepted
- **Date**: 2026-04-21
- **Deciders**: @sena-m09

## Context

Liquidbook はテンプレートのプレビューに必要な変数（パラメータ）を知る必要がある。
現在は2つの方法で宣言的に定義している:

- **sections**: `{% schema %}` ブロック内の JSON で `settings` / `blocks` を定義（Shopify 公式仕様）
- **snippets**: `@param` JSDoc 風コメントで型・デフォルト値・説明を記述

この方式には以下の課題がある:

1. `@param` を書かない snippet は変数が一切検出されず、プレビューフォームが空になる
2. 宣言と実際のテンプレート使用が乖離しても検知できない（書き忘れ、削除忘れ）
3. Storybook のような別ファイル方式（`.stories.yml`）の導入も検討したが、Liquid テンプレートの規模感では管理コストが過剰

## Decision

**Liquid AST からの変数自動検出を基盤とし、`@param` / `{% schema %}` を補足情報として重ねる方式（方式2）を採用する。**

### 具体的な構成

```
TemplateAnalyzer (AST 変数抽出)
       |
       v
自動検出された変数: [title, price, featured]
       |
       v
ParamParser / SchemaParser (型・デフォルト値・説明をマージ)
       |
       v
最終結果: [title: String "My Card", price: Number 1980, featured: Boolean false]
```

- `TemplateAnalyzer` が `Liquid::Template.parse` の AST を走査し、外部依存変数を抽出する
- ループ変数（`for item in ...` の `item`）や `assign` のローカル変数は自動除外する
- `section.settings.*` / `section.blocks` は schema 由来として分類する
- `@param` が存在する変数には型・デフォルト値・説明を上書きマージする
- `@param` がない変数も「unknown 型」としてプレビューフォームに表示する

## Alternatives Considered

### 方式1: 自動検出のみ（宣言ファイル不要）

- メリット: 何も書かなくていい
- デメリット: 型推論に限界がある（`title` が String か Number かは AST からは判断できない）、デフォルト値や説明を付けられない
- 判断: 自動検出だけでは UI の品質が不十分

### 方式3: 別ファイル（Storybook 式 `.stories.yml`）

- メリット: テンプレートが汚れない、variants を複数定義できる
- デメリット: ファイル管理コスト、テンプレートとの sync 切れリスク
- 判断: コンポーネント数が数百規模のプロジェクト向け。Liquid テンプレートの規模感では過剰

### 方式2 から方式3 への移行可能性

方式3 に移行する場合でも、TemplateAnalyzer は「`.stories.yml` に書き忘れた変数を警告する」用途でそのまま活用できる。TemplateAnalyzer の実装は無駄にならない。

## Consequences

- `TemplateAnalyzer` を新規作成する（Liquid AST 走査）
- `ParamParser` は TemplateAnalyzer の結果に型情報をマージする役割に変わる
- `@param` なしの snippet でもプレビューフォームが自動生成される
- 将来的に `@param` の文法拡張（複合型など）を行う場合、ParamParser の書き換えが必要になるが、TemplateAnalyzer とは独立している
