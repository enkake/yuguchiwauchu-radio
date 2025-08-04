#!/bin/bash
# Script to fetch and analyze audio files to extract metadata

# Function to format seconds to HH:MM:SS
format_duration() {
    local total_seconds=$1
    local hours=$((total_seconds / 3600))
    local minutes=$(((total_seconds % 3600) / 60))
    local seconds=$((total_seconds % 60))
    printf "%02d:%02d:%02d" $hours $minutes $seconds
}

# Function to get audio metadata
get_audio_metadata() {
    local audio_url="$1"
    local temp_file=$(mktemp)
    
    echo "Fetching metadata for: $audio_url" >&2
    
    # Get file size and content type using curl HEAD request (follow redirects)
    local headers=$(curl -sI -L "$audio_url")
    local file_size=$(echo "$headers" | grep -i "content-length:" | tail -1 | awk '{print $2}' | tr -d '\r')
    local content_type=$(echo "$headers" | grep -i "content-type:" | tail -1 | awk '{print $2}' | tr -d '\r')
    
    # Default values
    if [ -z "$file_size" ]; then
        file_size="0"
    fi
    if [ -z "$content_type" ]; then
        content_type="audio/mpeg"
    fi
    
    # Try to get duration using ffprobe if available
    local duration="00:00:00"
    if command -v ffprobe >/dev/null 2>&1; then
        # Get duration without downloading entire file
        # First get the final URL after redirects
        local final_url=$(curl -sI -L -o /dev/null -w '%{url_effective}' "$audio_url")
        local duration_seconds=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$final_url" 2>/dev/null)
        if [ -n "$duration_seconds" ]; then
            duration=$(format_duration ${duration_seconds%.*})
        fi
    fi
    
    # Output as JSON-like format
    echo "{\"length\": $file_size, \"type\": \"$content_type\", \"duration\": \"$duration\"}"
    
    rm -f "$temp_file"
}

# Process each episode file
for file in content/episodes/*.md; do
    if [ -f "$file" ]; then
        # Check if audio metadata already exists
        if ! grep -q "audio_length:" "$file"; then
            # Extract audio URL from frontmatter
            audio_url=$(awk '/^audio:/ {gsub(/"/, "", $2); print $2}' "$file")
            
            if [ -n "$audio_url" ]; then
                # Get metadata
                metadata=$(get_audio_metadata "$audio_url")
                
                echo "Raw metadata: $metadata" >&2
                
                # Parse metadata
                audio_length=$(echo "$metadata" | grep -o '"length": [0-9]*' | cut -d: -f2 | tr -d ' ')
                audio_type=$(echo "$metadata" | grep -o '"type": "[^"]*"' | cut -d'"' -f4)
                audio_duration=$(echo "$metadata" | grep -o '"duration": "[^"]*"' | cut -d'"' -f4)
                
                echo "Parsed values:" >&2
                echo "  Length: $audio_length" >&2
                echo "  Type: $audio_type" >&2
                echo "  Duration: $audio_duration" >&2
                
                # Create temporary file
                tmpfile=$(mktemp)
                
                # Add metadata to frontmatter
                awk -v file_size="$audio_length" -v file_type="$audio_type" -v file_duration="$audio_duration" '
                    BEGIN { count = 0 }
                    /^---$/ { 
                        count++
                        if (count == 2) {
                            # Add metadata before the closing ---
                            print "audio_length: " file_size
                            print "audio_type: \"" file_type "\""
                            print "audio_duration: \"" file_duration "\""
                        }
                    }
                    { print }
                ' "$file" > "$tmpfile"
                
                # Replace the original file
                mv "$tmpfile" "$file"
                
                echo "Processed: $file"
                echo "  Length: $audio_length bytes"
                echo "  Type: $audio_type"
                echo "  Duration: $audio_duration"
            fi
        else
            echo "Skipping $file (already has metadata)"
        fi
    fi
done