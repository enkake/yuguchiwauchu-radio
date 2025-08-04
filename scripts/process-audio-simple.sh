#!/bin/bash
# Simple script to add placeholder audio metadata to episodes
# In production, this would fetch and analyze actual audio files

for file in content/episodes/*.md; do
    if [ -f "$file" ]; then
        # Check if audio metadata already exists
        if ! grep -q "audio_length:" "$file"; then
            # Add placeholder metadata before the last ---
            sed -i.bak '/^---$/,/^---$/{
                /^---$/{
                    i\
audio_length: 10485760\
audio_type: "audio/mpeg"\
audio_duration: "00:30:00"
                }
            }' "$file"
            
            # Remove backup file
            rm "${file}.bak" 2>/dev/null || true
        fi
    fi
done