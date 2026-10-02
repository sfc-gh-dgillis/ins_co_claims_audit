#!/usr/bin/env bash
set -euo pipefail

# Renders the Streamlit app's snowflake.yml from templates/snowflake_yml_template.yml.
# Usage: ./generate-streamlit-project.sh VARIABLES_FILE OUTPUT_DIR

if [ $# -lt 2 ]; then
    echo "Usage: $0 VARIABLES_FILE OUTPUT_DIR"
    echo "Example: $0 streamlit/variables.json streamlit"
    exit 1
fi

VARIABLES_FILE="$1"
OUTPUT_DIR="$2"

if [ ! -f "$VARIABLES_FILE" ]; then
    echo "Error: variables file not found at $VARIABLES_FILE"
    exit 1
fi

python3 cmd/generate-streamlit-project.py --variables "$VARIABLES_FILE" --output-dir "$OUTPUT_DIR"

echo ""
echo "snowflake.yml generated successfully in $OUTPUT_DIR"
