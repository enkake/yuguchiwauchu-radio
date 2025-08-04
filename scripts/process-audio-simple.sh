#!/bin/bash
# Simple script to add placeholder audio metadata to episodes
# In production, this would fetch and analyze actual audio files

for file in content/episodes/*.md; do
    if [ -f "$file" ]; then
        # Check if audio metadata already exists
        if ! grep -q "audio_length:" "$file"; then
            # Create a temporary file
            tmpfile=$(mktemp)
            
            # Process the file
            awk '
                BEGIN { in_frontmatter = 0; count = 0 }
                /^---$/ { 
                    count++
                    if (count == 2) {
                        # Add metadata before the closing ---
                        print "audio_length: 10485760"
                        print "audio_type: \"audio/mpeg\""
                        print "audio_duration: \"00:30:00\""
                    }
                }
                { print }
            ' "$file" > "$tmpfile"
            
            # Replace the original file
            mv "$tmpfile" "$file"
        fi
    fi
done