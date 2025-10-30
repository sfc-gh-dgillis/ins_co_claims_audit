#!/usr/bin/env bash
set -euo pipefail

# Usage: ./tasks/cmd/upload_to_s3.sh <bucket-name-or-s3-uri> [optional/prefix]
# Uploads contents of the `upload` directory located at the project root.

# Resolve project root as the current working directory (assumes script is executed from project root)
project_root="$(pwd)"
upload_dir="$project_root/tasks/upload"

# Check for AWS CLI
if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI not found. Install and configure AWS CLI first." >&2
  exit 1
fi

# Check if upload directory exists at project root
if [ ! -d "$upload_dir" ]; then
  echo "Directory \`$upload_dir\` not found." >&2
  exit 1
fi

# Validate input parameters
if [ $# -lt 1 ]; then
  echo "Usage: $0 <bucket-name-or-s3-uri> [optional/prefix]" >&2
  exit 1
fi

# set bucket and optional prefix variables
bucket="$1"
prefix="${2:-}"

# Normalize bucket URI to start with s3://
if [[ "$bucket" != s3://* ]]; then
  bucket="s3://$bucket"
fi

# Ensure trailing slash on source to copy contents, not the directory itself
src="$upload_dir/"

# Build destination (allow optional prefix)
if [ -n "$prefix" ]; then
  prefix="${prefix#/}"
  prefix="${prefix%/}"
  dest="$bucket/$prefix/"
else
  dest="$bucket/"
fi

echo "Uploading \`$src\` to \`$dest\` ..."
aws s3 sync --exact-timestamps --acl private --no-progress "$src" "$dest"
echo "Upload complete."
