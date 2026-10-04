#!/usr/bin/env bash
set -euo pipefail

# Mirrors the git-tracked files of this repo into a private Snowflake workspace.
#
# A temporary workaround: a git-synced workspace can only be created in
# Snowsight, so this recreates a plain workspace, uploads the files with PUT and commits them.
# The workspace is replaced on every run, so edits made in it are lost — make
# changes in the repo, not the workspace.
#
# Only files `git ls-files` lists are uploaded, so ignored files (.env/*.env,
# venvs, generated output) never leave this machine.
#
# Usage: ./sync-workspace.sh REPO_ROOT WORKSPACE_NAME

if [ $# -lt 2 ]; then
    echo "Usage: $0 REPO_ROOT WORKSPACE_NAME"
    echo "Example: $0 ../.. 'USER\$.PUBLIC.INS_CO_CLAIMS_AUDIT'"
    exit 1
fi

REPO_ROOT="$(cd "$1" && pwd)"
WORKSPACE="$2"
WS_URI="snow://workspace/${WORKSPACE}/versions/head"

echo "Syncing repo to workspace..."
echo "  Repo:       $REPO_ROOT"
echo "  Workspace:  $WORKSPACE"
echo "  Connection: $CLI_CONNECTION_NAME"
echo ""

FILES=()
while IFS= read -r f; do FILES+=("$f"); done < <(git -C "$REPO_ROOT" ls-files)

# One snow sql session for all statements: a connection per file is slow.
SQL_FILE="$(mktemp)"
trap 'rm -f "$SQL_FILE"' EXIT

# A new workspace has no live (writable) version; PUT needs one.
{
    echo "CREATE OR REPLACE WORKSPACE ${WORKSPACE};"
    echo "ALTER WORKSPACE ${WORKSPACE} ADD LIVE VERSION FROM LAST;"
} > "$SQL_FILE"
for f in "${FILES[@]}"; do
    dir="$(dirname "$f")"
    [ "$dir" = "." ] && dest="" || dest="${dir}/"
    echo "PUT 'file://${REPO_ROOT}/${f}' '${WS_URI}/${dest}' AUTO_COMPRESS=FALSE OVERWRITE=TRUE;" >> "$SQL_FILE"
done

# Publish the live version to head.
echo "ALTER WORKSPACE ${WORKSPACE} COMMIT;" >> "$SQL_FILE"

echo "==> Recreating the workspace and uploading ${#FILES[@]} files"
snow sql --connection "$CLI_CONNECTION_NAME" -f "$SQL_FILE" > /dev/null

# ---------------------------------------------------------------------------
# Verify: every tracked file should now be listed in the workspace.
# ---------------------------------------------------------------------------
echo "==> Verifying the upload"
UPLOADED="$(snow sql --connection "$CLI_CONNECTION_NAME" --format json \
    -q "LIST '${WS_URI}/'" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))")"

if [ "$UPLOADED" -ne "${#FILES[@]}" ]; then
    echo "✗ Workspace has ${UPLOADED} files, expected ${#FILES[@]}."
    exit 1
fi

echo "✓ ${UPLOADED} files in ${WORKSPACE}. Open it in Snowsight under Projects » Workspaces."
