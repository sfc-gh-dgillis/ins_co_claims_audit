#!/usr/bin/env python3

import argparse
import json
from pathlib import Path
import sys


def render_agent_statement(record):
    """Generate a CREATE OR REPLACE AGENT statement from a record."""
    db = record.get("database_name", "").strip()
    schema = record.get("schema_name", "").strip()
    base_name = record.get("name", "").strip()
    full_name = f"{db}.{schema}.{base_name}"

    comment = record.get("comment")
    profile_raw = record.get("profile")
    spec_raw = record.get("agent_spec")

    # Parse and pretty-print the agent_spec JSON
    spec_text = ""
    if spec_raw:
        try:
            spec_obj = json.loads(spec_raw)
            spec_text = json.dumps(spec_obj, indent=2, ensure_ascii=False)
        except json.JSONDecodeError:
            spec_text = spec_raw

    # Parse profile JSON and format as compact string
    profile_text = None
    if profile_raw:
        try:
            profile_obj = json.loads(profile_raw)
            profile_text = json.dumps(profile_obj, separators=(",", ":"), ensure_ascii=False)
        except json.JSONDecodeError:
            profile_text = profile_raw
        profile_text = profile_text.replace("'", "''")

    # Escape single quotes in comment
    comment_escaped = comment.replace("'", "''") if comment else None

    # Build the statement
    lines = [f"CREATE OR REPLACE AGENT {full_name}"]
    if comment_escaped:
        lines.append(f"  COMMENT = '{comment_escaped}'")
    if profile_text:
        lines.append(f"  PROFILE = '{profile_text}'")
    lines.append("  FROM SPECIFICATION")
    lines.append("  $$")
    lines.append(spec_text)
    lines.append("  $$;")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Generate SQL from describe_agent_output.json")
    parser.add_argument("-i", "--input", default="tasks/agent/json/describe_agent_output.json",
                        help="Input JSON file path")
    parser.add_argument("-o", "--output", default="agents.sql",
                        help="Output SQL file path")
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: Input file not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    data = json.loads(input_path.read_text(encoding="utf-8"))

    statements = []
    for record in data:
        stmt = render_agent_statement(record)
        statements.append(stmt)

    output_path = Path(args.output)
    output_path.write_text("\n\n".join(statements) + "\n", encoding="utf-8")
    print(f"Generated {len(statements)} statement(s) in {output_path}")


if __name__ == "__main__":
    main()
