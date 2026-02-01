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


def render_add_agent_to_si_statement(record):
    """Generate a statement to add agent to Snowflake Intelligence if not already added."""
    db = record.get("database_name", "").strip()
    schema = record.get("schema_name", "").strip()
    base_name = record.get("name", "").strip()
    full_name = f"{db}.{schema}.{base_name}"

    lines = [
        f"-- Add {base_name} to Snowflake Intelligence if not already present",
        "DECLARE",
        "  agent_exists BOOLEAN := FALSE;",
        "BEGIN",
        "  SELECT COUNT(*) > 0 INTO :agent_exists",
        "  FROM TABLE(RESULT_SCAN(LAST_QUERY_ID(-1)))",
        "  WHERE \"name\" = UPPER('{base_name}');".format(base_name=base_name),
        "",
        "  IF (NOT agent_exists) THEN",
        f"    ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT ADD AGENT {full_name};",
        "  END IF;",
        "END;",
    ]

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Generate SQL from describe_agent_output.json")
    parser.add_argument("-i", "--input", default="tasks/agent/json/describe_agent_output.json",
                        help="Input JSON file path")
    parser.add_argument("-o", "--output", default="agents.sql",
                        help="Output SQL file path for CREATE AGENT statements")
    parser.add_argument("--si-output", default=None,
                        help="Output SQL file path for ADD AGENT to Snowflake Intelligence (default: derived from -o)")
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: Input file not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    data = json.loads(input_path.read_text(encoding="utf-8"))

    # Generate CREATE AGENT statements
    create_statements = []
    for record in data:
        stmt = render_agent_statement(record)
        create_statements.append(stmt)

    output_path = Path(args.output)
    output_path.write_text("\n\n".join(create_statements) + "\n", encoding="utf-8")
    print(f"Generated {len(create_statements)} CREATE AGENT statement(s) in {output_path}")

    # Generate ADD AGENT to Snowflake Intelligence script
    si_output_path = Path(args.si_output) if args.si_output else output_path.parent / "add_agents_to_si.sql"
    
    si_lines = [
        "-- Script to add agents to Snowflake Intelligence (idempotent)",
        "-- First, show existing agents in the SI object to check membership",
        "SHOW AGENTS IN SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;",
        "",
    ]
    
    for record in data:
        stmt = render_add_agent_to_si_statement(record)
        si_lines.append(stmt)
        si_lines.append("")

    si_output_path.write_text("\n".join(si_lines), encoding="utf-8")
    print(f"Generated ADD AGENT to SI script in {si_output_path}")


if __name__ == "__main__":
    main()
