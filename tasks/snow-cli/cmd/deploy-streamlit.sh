#!/usr/bin/env bash
set -euo pipefail

# Deploys the claims audit Streamlit app to Snowflake on the container runtime.
#
# The app is deployed AS the app owner role ($DEMO_APP_OWNER_ROLE_NAME) rather
# than the connection's default role, so ownership is predictable and the
# compute pool / PyPI mirror grants from sql/batch-0/007 apply.
#
# Usage: ./deploy-streamlit.sh PROJECT_DIR

if [ $# -lt 1 ]; then
    echo "Usage: $0 PROJECT_DIR"
    echo "Example: $0 streamlit"
    exit 1
fi

PROJECT_DIR="$1"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: project directory not found at $PROJECT_DIR"
    exit 1
fi

MANIFEST="$PROJECT_DIR/snowflake.yml"
if [ ! -f "$MANIFEST" ]; then
    echo "Error: snowflake.yml not found in $PROJECT_DIR"
    echo "  Run the generate step first."
    exit 1
fi

# ---------------------------------------------------------------------------
# Pre-flight artifact check.
#
# `snow streamlit deploy` does NOT verify that every path under artifacts:
# exists. A missing file uploads as a zero-byte stage entry and the deployed app
# crashes on first load, while the deploy itself reports success.
# ---------------------------------------------------------------------------
echo "==> Pre-flight: verifying declared artifacts exist"
python3 - "$MANIFEST" <<'PY'
import sys, os, re

manifest_path = sys.argv[1]
manifest_dir = os.path.dirname(manifest_path)

try:
    import yaml
    with open(manifest_path) as fh:
        manifest = yaml.safe_load(fh)
    artifacts = []
    for entity in (manifest.get("entities") or {}).values():
        if (entity or {}).get("type") == "streamlit":
            artifacts.extend(entity.get("artifacts") or [])
except ImportError:
    # PyYAML is not guaranteed to be present; fall back to a simple scan of the
    # artifacts: block rather than skipping the check entirely.
    artifacts = []
    in_artifacts = False
    with open(manifest_path) as fh:
        for line in fh:
            if re.match(r'^\s*artifacts:\s*$', line):
                in_artifacts = True
                continue
            if in_artifacts:
                m = re.match(r'^\s*-\s*(\S+)\s*$', line)
                if m:
                    artifacts.append(m.group(1))
                elif line.strip() and not line.startswith((' ', '\t')):
                    in_artifacts = False

if not artifacts:
    print("  WARNING: no artifacts found in the manifest")
    sys.exit(0)

missing = [a for a in artifacts if not os.path.exists(os.path.join(manifest_dir, a))]
if missing:
    print("  MISSING artifacts (deploy would silently break the app):")
    for a in missing:
        print(f"    - {a}")
    sys.exit(1)

for a in artifacts:
    print(f"  ok: {a}")
PY

echo ""
echo "Deploying the claims audit Streamlit app..."
echo "  Project:    $PROJECT_DIR"
echo "  Connection: $CLI_CONNECTION_NAME"
echo "  Owner role: $DEMO_APP_OWNER_ROLE_NAME"
echo ""

snow streamlit deploy ins_co_claims_audit_streamlit \
    --project "$PROJECT_DIR" \
    --connection "$CLI_CONNECTION_NAME" \
    --role "$DEMO_APP_OWNER_ROLE_NAME" \
    --replace \
    --prune

# ---------------------------------------------------------------------------
# Post-deploy verification.
#
# A clean exit from `snow streamlit deploy` is not proof the object exists, so
# confirm it, and confirm the owner is the app owner role.
# ---------------------------------------------------------------------------
echo ""
echo "==> Verifying the deployed app"

STREAMLIT_NAME="${DEMO_STREAMLIT_NAME:-ins_co_claims_audit_streamlit}"
SCHEMA_NAME="${DEMO_SCHEMA_ONLY_NAME:-loss_claims}"

DEPLOY_INFO="$(snow sql \
    --connection "$CLI_CONNECTION_NAME" \
    --role "$DEMO_APP_OWNER_ROLE_NAME" \
    --format json \
    -q "SHOW STREAMLITS LIKE '${STREAMLIT_NAME}' IN SCHEMA ${DEMO_DATABASE_NAME}.${SCHEMA_NAME}" 2>/dev/null)"

ACTUAL_OWNER="$(printf '%s' "$DEPLOY_INFO" | python3 -c "
import sys, json
try:
    rows = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if rows:
    print(rows[0].get('owner', ''))
" 2>/dev/null || true)"

if [ -z "$ACTUAL_OWNER" ]; then
    echo "✗ SHOW STREAMLITS returned no rows — the deploy silently failed."
    exit 1
fi

echo "✓ Streamlit '${STREAMLIT_NAME}' exists in ${DEMO_DATABASE_NAME}.${SCHEMA_NAME}"

# Snowflake reports role names in upper case.
if [ "$(printf '%s' "$ACTUAL_OWNER" | tr '[:lower:]' '[:upper:]')" = "$(printf '%s' "$DEMO_APP_OWNER_ROLE_NAME" | tr '[:lower:]' '[:upper:]')" ]; then
    echo "✓ Owned by '${ACTUAL_OWNER}'."
else
    echo "✗ Owned by '${ACTUAL_OWNER}', expected '${DEMO_APP_OWNER_ROLE_NAME}'."
    echo ""
    echo "  Correct ownership with:"
    echo ""
    echo "    GRANT OWNERSHIP ON STREAMLIT ${DEMO_DATABASE_NAME}.${SCHEMA_NAME}.${STREAMLIT_NAME}"
    echo "      TO ROLE ${DEMO_APP_OWNER_ROLE_NAME} COPY CURRENT GRANTS;"
    exit 1
fi
