#!/usr/bin/env python3
import os
import sys
import yaml
import json
import urllib.request
import urllib.parse
from mutagen.mp3 import MP3
from mutagen.mp4 import MP4
from mutagen.oggvorbis import OggVorbis
import tempfile
import frontmatter
from pathlib import Path

def get_audio_info(audio_url):
    """Download audio file and extract metadata"""
    try:
        # Create temporary file
        with tempfile.NamedTemporaryFile(suffix='.audio', delete=False) as tmp_file:
            # Download audio file
            print(f"Downloading: {audio_url}")
            with urllib.request.urlopen(audio_url) as response:
                tmp_file.write(response.read())
                file_size = response.headers.get('Content-Length', 0)
                content_type = response.headers.get('Content-Type', 'audio/mpeg')
            
            tmp_path = tmp_file.name
        
        # Analyze audio file
        duration = 0
        if audio_url.endswith('.mp3') or 'audio/mpeg' in content_type:
            audio = MP3(tmp_path)
            duration = int(audio.info.length)
        elif audio_url.endswith('.m4a') or 'audio/mp4' in content_type:
            audio = MP4(tmp_path)
            duration = int(audio.info.length)
        elif audio_url.endswith('.ogg') or 'audio/ogg' in content_type:
            audio = OggVorbis(tmp_path)
            duration = int(audio.info.length)
        
        # Format duration as HH:MM:SS
        hours = duration // 3600
        minutes = (duration % 3600) // 60
        seconds = duration % 60
        duration_str = f"{hours:02d}:{minutes:02d}:{seconds:02d}"
        
        # Clean up
        os.unlink(tmp_path)
        
        return {
            'length': int(file_size),
            'type': content_type,
            'duration': duration_str
        }
    except Exception as e:
        print(f"Error processing {audio_url}: {e}")
        return {
            'length': 0,
            'type': 'audio/mpeg',
            'duration': '00:00:00'
        }

def process_episodes(content_dir):
    """Process all episode files and update with audio metadata"""
    episodes_dir = Path(content_dir) / 'episodes'
    
    if not episodes_dir.exists():
        print(f"Episodes directory not found: {episodes_dir}")
        return
    
    audio_cache = {}
    cache_file = Path('.audio-cache.json')
    
    # Load cache if exists
    if cache_file.exists():
        with open(cache_file, 'r') as f:
            audio_cache = json.load(f)
    
    # Process each markdown file
    for md_file in episodes_dir.glob('*.md'):
        print(f"Processing: {md_file}")
        
        # Read frontmatter
        with open(md_file, 'r', encoding='utf-8') as f:
            post = frontmatter.load(f)
        
        if 'audio' in post.metadata:
            audio_url = post.metadata['audio']
            
            # Check cache
            if audio_url not in audio_cache:
                audio_cache[audio_url] = get_audio_info(audio_url)
            
            # Update metadata
            audio_info = audio_cache[audio_url]
            post.metadata['audio_length'] = audio_info['length']
            post.metadata['audio_type'] = audio_info['type']
            post.metadata['audio_duration'] = audio_info['duration']
            
            # Write back
            with open(md_file, 'w', encoding='utf-8') as f:
                f.write(frontmatter.dumps(post))
            
            print(f"  Duration: {audio_info['duration']}")
            print(f"  Size: {audio_info['length']} bytes")
    
    # Save cache
    with open(cache_file, 'w') as f:
        json.dump(audio_cache, f, indent=2)

if __name__ == '__main__':
    content_dir = sys.argv[1] if len(sys.argv) > 1 else 'content'
    process_episodes(content_dir)