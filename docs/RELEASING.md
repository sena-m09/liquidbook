# Release Process

## CI/CD ワークフロー構成

| ワークフロー | ファイル | トリガー | 内容 |
|---|---|---|---|
| CI | `ci.yml` | push (main) / PR | テスト実行 (Ruby 3.2 - 4.0) |
| GitHub Release | `github_release.yml` | `v*` タグ push | CHANGELOG から抽出 → GitHub Release 作成 |
| RubyGems 公開 | `gem_release.yml` | 手動 (`workflow_dispatch`) | RubyGems に gem push |

## リリース手順

### 1. バージョンと CHANGELOG を更新

`lib/liquidbook/version.rb` のバージョンを更新:

```ruby
VERSION = "X.Y.Z"
```

`CHANGELOG.md` に変更内容を追記（`[Unreleased]` から新バージョンのセクションへ移動）:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- ...
```

### 2. コミットしてタグを打つ

```bash
git add lib/liquidbook/version.rb CHANGELOG.md
git commit -m "chore: bump version to X.Y.Z"
git tag vX.Y.Z
git push origin main --tags
```

### 3. GitHub Release を確認

タグ push をトリガーに GitHub Release が自動作成されます。CHANGELOG から該当バージョンのノートが抽出されます。

[Actions > Create GitHub Release](https://github.com/sena-m09/liquidbook/actions/workflows/github_release.yml) で結果を確認してください。

### 4. RubyGems に公開

GitHub Release の内容を確認した後、手動で gem を公開します:

[Actions > Publish to RubyGems](https://github.com/sena-m09/liquidbook/actions/workflows/gem_release.yml) → "Run workflow" を実行

> gem push を手動トリガーにしているのは、公開前に最終確認できるようにするためです。
