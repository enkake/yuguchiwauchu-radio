# 湯口は宇宙ラジオ

Hugo を使った Podcast 番組。

- ホスティングは GitHub Pages
- GitHub Actions でビルド & パブリッシュ
- hugo.yaml に以下の情報を定義できる
  - [channel 要素の子要素に関わる情報](https://github.com/Podcast-Standards-Project/PSP-1-Podcast-RSS-Specification?tab=readme-ov-file#required-channel-elements)
  - 基軸 URL
- 記事のメタデータに以下を定義できる
  - 音声データの URL
  - サムネイルのパス
    - サムネイルはリポジトリ内に格納
    - 未設定の場合、デフォルトのサムネイルを指定
- サイト生成時、エピソードごとの [enclosure 要素の属性値](https://github.com/Podcast-Standards-Project/PSP-1-Podcast-RSS-Specification?tab=readme-ov-file#enclosure), itunes:duration については、メタデータに定義した音声データを取得・解析し、取得する
- itunes:episode は自動的にカウント
