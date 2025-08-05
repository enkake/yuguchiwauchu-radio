# 湯口は宇宙ラジオ

Hugo-based podcast website with automatic RSS feed generation.

## Features

- Podcast RSS feed generation compliant with iTunes/Apple Podcasts
- GitHub Pages hosting via GitHub Actions
- Automatic episode numbering
- Audio metadata extraction (duration, file size) during build

## ローカル開発環境のセットアップ

### 必要なツール

- Git
- Go (1.18以上)
- Hugo

### Hugo のインストール

#### macOS (Homebrew を使用)
```bash
brew install hugo
```

#### Go を使用したインストール
```bash
go install github.com/gohugoio/hugo@latest
```

#### その他のプラットフォーム
[Hugo公式サイト](https://gohugo.io/installation/)を参照してください。

### プロジェクトのセットアップ

1. リポジトリをクローン
   ```bash
   git clone https://github.com/enkake/yuguchiwauchu-radio.git
   cd yuguchiwauchu-radio
   ```

2. Hugo の動作確認
   ```bash
   hugo version
   ```

## ビルド方法

### 開発サーバーの起動

ドラフト記事を含めて開発サーバーを起動:
```bash
hugo server -D
```

ドラフトを除外して起動:
```bash
hugo server
```

開発サーバーは `http://localhost:1313/` でアクセスできます。
ファイルの変更は自動的に反映されます。

### 本番用ビルド

#### 基本的なビルド
```bash
hugo
```

ビルド結果は `public/` ディレクトリに生成されます。

#### 最適化されたビルド（minify）
```bash
hugo --minify
```

#### ベースURLを指定してビルド
```bash
hugo --baseURL https://yourdomain.com/
```

### ビルド前の音声メタデータ処理

エピソードの音声ファイルのメタデータを追加:
```bash
./scripts/process-audio-simple.sh
```

### RSS フィードの確認

ビルド後、以下のファイルでPodcast RSSフィードを確認できます:
```
public/podcast.xml
```

## エピソードの作成

新しいエピソードを作成:
```bash
hugo new content episodes/002-episode-title.md
```

エピソードファイルの例 (`content/episodes/002-episode-title.md`):
```yaml
---
title: "第2回: エピソードタイトル"
date: 2024-01-22T10:00:00+09:00
draft: false
audio: "https://example.com/episodes/002.mp3"
thumbnail: "/images/episodes/002-thumbnail.jpg"
description: "エピソードの説明文"
audio_length: 10485760  # 音声ファイルのサイズ（バイト）
audio_type: "audio/mpeg"
audio_duration: "00:30:00"  # 再生時間（HH:MM:SS）
---

エピソードの内容をMarkdownで記述...
```

## デプロイ

### GitHub Pages へのデプロイ

1. GitHub リポジトリの Settings > Pages で Source を "GitHub Actions" に設定
2. main または master ブランチにプッシュすると自動的にデプロイされます

```bash
git add .
git commit -m "Add new episode"
git push origin main
```

## 設定

`hugo.yaml` で以下の項目を設定できます:

- `baseURL`: サイトのベースURL
- `title`: サイトタイトル
- `params.description`: Podcast の説明
- `params.itunes`: iTunes/Apple Podcasts 用メタデータ
- `params.defaultThumbnail`: デフォルトのサムネイル画像パス

## GitHub Actions の設定

### Personal Access Token (PAT) の設定（必須）

音声メタデータの自動更新PRを作成するために、Personal Access Token の設定が必要です：

1. **GitHub で Personal Access Token を作成**
   - GitHub の Settings > Developer settings > Personal access tokens > Tokens (classic)
   - "Generate new token" をクリック
   - 以下のスコープを選択:
     - `repo` (すべてのリポジトリ権限)
   - トークンをコピー（この画面を離れると二度と表示されません）
   
2. **リポジトリに Secret を追加**
   - リポジトリの Settings > Secrets and variables > Actions
   - "New repository secret" をクリック
   - Name: `GH_PAT`
   - Secret: コピーしたトークンを貼り付け
   - "Add secret" をクリック

これで、エピソードファイルがプッシュされると自動的に音声メタデータを取得し、更新PRが作成されます。