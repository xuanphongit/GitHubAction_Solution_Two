#!/bin/bash

# Check if input file is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <input-file>"
    exit 1
fi

INPUT_FILE="$1"

# Ensure the input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File $INPUT_FILE does not exist."
    exit 1
fi

# Find all unique placeholders of the form #{value}#
# Allow any case (uppercase, lowercase, mixed) with alphanumeric and underscores
PLACEHOLDERS=$(grep -o '#{[a-zA-Z0-9_]\+}#' "$INPUT_FILE" | sed 's/#{\([^}]\+\)}#/\1/g' | sort -u)

if [ -z "$PLACEHOLDERS" ]; then
    echo "No placeholders of the form #{value}# found in $INPUT_FILE."
    exit 0
fi

# Log found placeholders
echo "Found placeholders: $PLACEHOLDERS"

# Function to replace placeholder
replace_placeholder() {
    local key="$1"
    # Convert placeholder key to uppercase to match GitHub variable
    local upper_key="${key^^}"
    local var_value="${!upper_key}"
    if [ -n "$var_value" ]; then
        # Escape special characters for sed
        escaped_value=$(echo "$var_value" | sed 's/[\/&]/\\&/g')
        # Perform replacement using original placeholder (case-sensitive)
        sed -i "s/#{$key}#/$escaped_value/g" "$INPUT_FILE"
        echo "Replaced #{$key}# with $var_value (using $upper_key)"
        # Export to GITHUB_ENV (uppercase key)
        echo "$upper_key=$var_value" >> "$GITHUB_ENV"
    else
        echo "Warning: Environment variable $upper_key is not set. Skipping #{$key}#."
    fi
}

# Replace each placeholder
for placeholder in $PLACEHOLDERS; do
    replace_placeholder "$placeholder"
done

# Log modified file (remove in production for sensitive data)
echo "Modified $INPUT_FILE:"
cat "$INPUT_FILE"