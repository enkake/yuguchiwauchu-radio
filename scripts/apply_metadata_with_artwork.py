#!/usr/bin/env python3
import yaml
import subprocess
import sys
import os

def apply_metadata_with_artwork(input_file, output_file, metadata_file):
    with open(metadata_file, 'r', encoding='utf-8') as f:
        metadata = yaml.safe_load(f)
    
    # アートワークファイルを取得
    artwork_file = metadata.pop('artwork', None)
    
    cmd = ['ffmpeg', '-i', input_file]
    
    # アートワークがある場合は追加
    if artwork_file and os.path.exists(artwork_file):
        cmd.extend(['-i', artwork_file])
        map_options = ['-map', '0:a', '-map', '1:v']
        disposition_options = ['-disposition:v:0', 'attached_pic']
    else:
        map_options = []
        disposition_options = []
    
    # メタデータを追加
    for key, value in metadata.items():
        cmd.extend(['-metadata', f'{key}={value}'])
    
    # マッピングとコーデック設定
    cmd.extend(map_options)
    cmd.extend(disposition_options)
    cmd.extend(['-codec:a', 'copy', '-codec:v', 'copy', output_file])
    
    print("実行コマンド:")
    print(' '.join(cmd))
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode == 0:
        print(f"\nメタデータとアートワークを適用しました: {output_file}")
    else:
        print(f"\nエラー: {result.stderr}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("使用方法: python apply_metadata_with_artwork.py <入力ファイル> <出力ファイル> <メタデータYAML>")
        sys.exit(1)
    
    apply_metadata_with_artwork(sys.argv[1], sys.argv[2], sys.argv[3])