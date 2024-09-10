#!/bin/bash

# Specify the file path
file="./azurek8s"

# Create a temporary file
temp_file=$(mktemp)

# Loop through each line in the file
while IFS= read -r line; do
    # Check if the line contains "EOT"
    if [[ $line != *"EOT"* ]]; then
        # Append the line to the temporary file
        echo "$line" >> "$temp_file"
    fi
done < "$file"

# Replace the original file with the temporary file
mv "$temp_file" "$file"