#!/usr/bin/env python3

import argparse
import json
import subprocess
import sys
from pathlib import Path


def describe_agent(connection_name: str, agent_name: str) -> dict:
    """Run DESCRIBE AGENT and return the result as a dict."""
    cmd = [
        'snow', 'sql', '-c', connection_name,
        '--query', f'DESCRIBE AGENT {agent_name}',
        '--format', 'JSON_EXT'
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    data = json.loads(result.stdout)
    
    if not data or not isinstance(data, list) or len(data) == 0:
        raise ValueError(f"No data returned for agent: {agent_name}")
    
    return data[0]


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

    # Use EXECUTE IMMEDIATE with TRY/CATCH - if agent already exists, the error is caught and ignored
    lines = [
        f"-- Add {base_name} to Snowflake Intelligence (idempotent - ignores if already added)",
        "EXECUTE IMMEDIATE",
        "$$",
        "BEGIN",
        f"  ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT ADD AGENT {full_name};",
        "EXCEPTION",
        "  WHEN OTHER THEN",
        "    -- Agent already exists in SI, ignore the error",
        "    NULL;",
        "END;",
        "$$;",
    ]

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Generate SQL files from agents.json")
    parser.add_argument("-i", "--input", default="agent/input/agents.json",
                        help="Input JSON file with array of agent names (default: agent/input/agents.json)")
    parser.add_argument("-o", "--output-dir", default="agent/output",
                        help="Output directory for SQL files (default: agent/output)")
    parser.add_argument("-c", "--connection", required=True,
                        help="Snowflake CLI connection name")
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: Input file not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    agent_names = json.loads(input_path.read_text(encoding="utf-8"))

    if not isinstance(agent_names, list):
        print("Error: Input JSON must be an array of agent names", file=sys.stderr)
        sys.exit(1)

    for agent_name in agent_names:
        if not isinstance(agent_name, str) or not agent_name.strip():
            print(f"Warning: Skipping invalid agent name: {agent_name}", file=sys.stderr)
            continue

        agent_name = agent_name.strip()
        print(f"Describing agent: {agent_name}")
        
        try:
            record = describe_agent(args.connection, agent_name)
        except subprocess.CalledProcessError as e:
            print(f"Error describing agent {agent_name}: {e.stderr}", file=sys.stderr)
            sys.exit(1)
        except ValueError as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)

        # Use lowercase for filenames
        agent_name_lower = record.get("name", agent_name).strip().lower()

        # Generate CREATE AGENT SQL file
        create_stmt = render_agent_statement(record)
        create_file = output_dir / f"{agent_name_lower}_create_agent.sql"
        create_file.write_text(create_stmt + "\n", encoding="utf-8")
        print(f"  Generated {create_file}")

        # Generate ADD AGENT to SI SQL file
        si_stmt = render_add_agent_to_si_statement(record)
        si_lines = [
            "-- Script to add agent to Snowflake Intelligence (idempotent)",
            "",
            si_stmt,
        ]
        si_file = output_dir / f"{agent_name_lower}_add_agent_to_si.sql"
        si_file.write_text("\n".join(si_lines) + "\n", encoding="utf-8")
        print(f"  Generated {si_file}")

    print(f"\nGenerated SQL files for {len(agent_names)} agent(s) in {output_dir}")


if __name__ == "__main__":
    main()
