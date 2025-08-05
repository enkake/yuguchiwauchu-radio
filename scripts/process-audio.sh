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
    local http_status=$(echo "$headers" | head -1 | awk '{print $2}')
    local file_size=$(echo "$headers" | grep -i "content-length:" | tail -1 | awk '{print $2}' | tr -d '\r')
    local content_type=$(echo "$headers" | grep -i "content-type:" | tail -1 | awk '{print $2}' | tr -d '\r')
    
    # Check if HTTP request was successful
    if [ "$http_status" != "200" ]; then
        echo "  ❌ Error: HTTP status $http_status for $audio_url" >&2
        rm -f "$temp_file"
        return 1
    fi
    
    # Check if it's actually an audio file
    if [[ ! "$content_type" =~ ^audio/ ]] && [[ ! "$content_type" =~ mpeg$ ]]; then
        echo "  ❌ Error: Invalid content type '$content_type' (expected audio/*) for $audio_url" >&2
        rm -f "$temp_file"
        return 1
    fi
    
    # Default values
    if [ -z "$file_size" ] || [ "$file_size" = "0" ]; then
        echo "  ❌ Error: Invalid file size for $audio_url" >&2
        rm -f "$temp_file"
        return 1
    fi
    
    # Try to get duration using ffprobe if available
    local duration="00:00:00"
    if command -v ffprobe >/dev/null 2>&1; then
        echo "  ffprobe is available" >&2
        
        # Try direct URL first
        local ffprobe_output=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$audio_url" 2>&1)
        local ffprobe_exit_code=$?
        
        if [ $ffprobe_exit_code -ne 0 ] || [ -z "$ffprobe_output" ]; then
            echo "  Direct URL failed, trying with curl download..." >&2
            # Download first few MB to get duration
            local temp_audio=$(mktemp)
            curl -L -s --max-filesize 5000000 -o "$temp_audio" "$audio_url" 2>/dev/null || true
            
            if [ -f "$temp_audio" ] && [ -s "$temp_audio" ]; then
                ffprobe_output=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$temp_audio" 2>&1)
                ffprobe_exit_code=$?
                rm -f "$temp_audio"
            fi
        fi
        
        echo "  ffprobe exit code: $ffprobe_exit_code" >&2
        echo "  ffprobe output: $ffprobe_output" >&2
        
        if [ $ffprobe_exit_code -eq 0 ] && [ -n "$ffprobe_output" ]; then
            local duration_seconds=$(echo "$ffprobe_output" | grep -E '^[0-9]+(\.[0-9]+)?$' | head -1)
            if [ -n "$duration_seconds" ]; then
                duration=$(format_duration ${duration_seconds%.*})
                echo "  Calculated duration: $duration" >&2
            else
                echo "  Could not parse duration from output" >&2
            fi
        else
            echo "  ffprobe failed to get duration" >&2
        fi
    else
        echo "  ffprobe is not available" >&2
    fi
    
    # Output as JSON-like format
    echo "{\"length\": $file_size, \"type\": \"$content_type\", \"duration\": \"$duration\"}"
    
    rm -f "$temp_file"
}

# Track if any errors occurred
has_errors=0

# Process each episode file
for file in content/episodes/*.md; do
    if [ -f "$file" ]; then
        # Extract audio URL from frontmatter
        audio_url=$(awk '/^audio:/ {gsub(/"/, "", $2); print $2}' "$file")
        
        if [ -n "$audio_url" ]; then
                # Get metadata
                metadata=$(get_audio_metadata "$audio_url")
                
                # Check if get_audio_metadata failed
                if [ $? -ne 0 ]; then
                    echo "❌ Failed to process: $file" >&2
                    has_errors=1
                    continue
                fi
                
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
                
                # Remove existing metadata and add new metadata to frontmatter
                awk -v file_size="$audio_length" -v file_type="$audio_type" -v file_duration="$audio_duration" '
                    BEGIN { count = 0; in_frontmatter = 0 }
                    /^---$/ { 
                        count++
                        if (count == 1) in_frontmatter = 1
                        if (count == 2) {
                            in_frontmatter = 0
                            # Add new metadata before the closing ---
                            print "audio_length: " file_size
                            print "audio_type: \"" file_type "\""
                            print "audio_duration: \"" file_duration "\""
                        }
                    }
                    # Skip existing audio metadata lines
                    in_frontmatter && /^audio_length:/ { next }
                    in_frontmatter && /^audio_type:/ { next }
                    in_frontmatter && /^audio_duration:/ { next }
                    { print }
                ' "$file" > "$tmpfile"
                
                # Replace the original file
                mv "$tmpfile" "$file"
                
                echo "Processed: $file"
                echo "  Length: $audio_length bytes"
                echo "  Type: $audio_type"
                echo "  Duration: $audio_duration"
            fi
    fi
done

# Exit with error if any files failed
if [ $has_errors -eq 1 ]; then
    echo "" >&2
    echo "❌ Some audio files could not be processed!" >&2
    exit 1
fi

echo "" >&2
echo "✅ All audio files processed successfully!" >&2