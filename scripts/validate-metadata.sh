#!/bin/bash
# Script to validate episode metadata

set -e

validation_failed=0
missing_metadata_files=""

echo "Validating episode metadata..."

for file in content/episodes/*.md; do
    if [ -f "$file" ]; then
        echo "Checking: $file"
        
        # Check for required fields
        has_audio=$(grep -E "^audio:" "$file" || echo "")
        has_audio_length=$(grep -E "^audio_length:" "$file" || echo "")
        has_audio_type=$(grep -E "^audio_type:" "$file" || echo "")
        has_audio_duration=$(grep -E "^audio_duration:" "$file" || echo "")
        
        missing_fields=""
        
        if [ -z "$has_audio" ]; then
            missing_fields="${missing_fields}audio, "
        fi
        
        if [ -z "$has_audio_length" ]; then
            missing_fields="${missing_fields}audio_length, "
        fi
        
        if [ -z "$has_audio_type" ]; then
            missing_fields="${missing_fields}audio_type, "
        fi
        
        if [ -z "$has_audio_duration" ]; then
            missing_fields="${missing_fields}audio_duration, "
        fi
        
        if [ -n "$missing_fields" ]; then
            echo "  ❌ Missing fields: ${missing_fields%, }"
            validation_failed=1
            missing_metadata_files="${missing_metadata_files}$(basename "$file"), "
        else
            # Validate field values
            audio_length=$(grep -E "^audio_length:" "$file" | awk '{print $2}')
            audio_duration=$(grep -E "^audio_duration:" "$file" | awk '{print $2}' | tr -d '"')
            
            if [ "$audio_length" -eq 0 ] 2>/dev/null || [ -z "$audio_length" ]; then
                echo "  ❌ Invalid audio_length: $audio_length"
                validation_failed=1
            fi
            
            if [ "$audio_duration" = "00:00:00" ] || [ -z "$audio_duration" ]; then
                echo "  ❌ Invalid audio_duration: $audio_duration"
                validation_failed=1
            fi
            
            if [ $validation_failed -eq 0 ]; then
                echo "  ✅ All metadata valid"
            fi
        fi
    fi
done

if [ $validation_failed -eq 1 ]; then
    echo ""
    echo "❌ Metadata validation failed!"
    if [ -n "$missing_metadata_files" ]; then
        echo "Files with missing metadata: ${missing_metadata_files%, }"
        echo ""
        echo "Please run: ./scripts/process-audio.sh"
    fi
    exit 1
else
    echo ""
    echo "✅ All episode metadata is valid!"
    exit 0
fi