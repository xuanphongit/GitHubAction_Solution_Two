#!/bin/bash

# Check if input file is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <input-file>"
    exit 1
fi

INPUT_FILE=$1

# Ensure the input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File $INPUT_FILE does not exist."
    exit 1
fi

# Find all placeholders of the form #{value}#
# Use grep with -o to extract matches, and extract 'value' part
PLACEHOLDERS=$(grep -o '#{[a-zA-Z0-9_]\+}#' "$INPUT_FILE" | sed 's/#{\([^}]\+\)}#/\1/g' | sort -u)

if [ -z "$PLACEHOLDERS" ]; then
    echo "No placeholders of the form #{value}# found in $INPUT_FILE."
    exit 0
fi

# Function to replace placeholder and log
replace_placeholder() {
    local key=$1
    local var_value=${!key}
    if [ -n "$var_value" ]; then
        # Escape special characters in the value for sed
        escaped_value=$(echo "$var_value" | sed 's/[\/&]/\\&/g')
        sed -i "s/#{$key}#/$escaped_value/g" "$INPUT_FILE"
        echo "Replaced #{$key}# with $var_value"
        # Export to GITHUB_ENV (uppercase key)
        echo "${key^^}=$var_value" >> $GITHUB_ENV
    else
        echo "Warning: $key is not set. Skipping #{$key}#."
    fi
}

# Process each placeholder
echo "Found placeholders: $PLACEHOLDERS"
for placeholder in $PLACEHOLDERS; do
    replace_placeholder "$placeholder"
done

# Verify changes
echo "Modified $INPUT_FILE:"
cat "$INPUT_FILE"