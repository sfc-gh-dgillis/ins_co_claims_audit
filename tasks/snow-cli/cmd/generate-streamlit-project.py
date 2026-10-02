#!/usr/bin/env python3
"""
Renders the Streamlit app's snowflake.yml deployment manifest from a template.

Reads a variables config that maps Jinja-style {{ placeholder }} names to
environment variables, then renders snowflake.yml into the output directory
(normally the streamlit/ app directory, next to the artifacts it lists).

Usage:
    python3 generate-streamlit-project.py --variables <variables.json> --output-dir <dir>

The "snowflake_yml_template" path inside variables.json is
resolved relative to the variables file itself.
"""

import argparse
import json
import os
import sys
from pathlib import Path


def load_variables(variables_path: Path):
    """Load the variable config and resolve each value from the environment."""
    with open(variables_path, "r") as f:
        config = json.load(f)

    resolved = {}
    missing = []
    for key, spec in config.get("variables", {}).items():
        env_var = spec.get("env")
        default = spec.get("default")
        value = os.environ.get(env_var, default) if env_var else default
        if value is None or value == "":
            missing.append(f"{key} (env: {env_var})")
        else:
            resolved[key] = value

    if missing:
        print("Error: the following variables could not be resolved:", file=sys.stderr)
        for item in missing:
            print(f"  - {item}", file=sys.stderr)
        print("\nDid you copy .env/demo.env_template to .env/demo.env?", file=sys.stderr)
        sys.exit(1)

    return resolved, config


def substitute(text: str, variables: dict) -> str:
    """Replace {{ key }} placeholders. Tolerates both {{ key }} and {{key}}."""
    for key, value in variables.items():
        text = text.replace(f"{{{{ {key} }}}}", value)
        text = text.replace(f"{{{{{key}}}}}", value)
    return text


def render(template_path: Path, output_path: Path, variables: dict, label: str) -> None:
    if not template_path.is_file():
        print(f"Error: {label} template not found at {template_path}", file=sys.stderr)
        sys.exit(1)

    with open(template_path, "r") as f:
        content = f.read()

    rendered = substitute(content, variables)

    # Any leftover placeholder means the template references a variable that
    # variables.json does not define — fail loudly rather than deploying it.
    if "{{" in rendered and "}}" in rendered:
        leftovers = [
            line.strip()
            for line in rendered.splitlines()
            if "{{" in line and "}}" in line
        ]
        print(f"Error: unresolved placeholders remain in {label}:", file=sys.stderr)
        for line in leftovers[:10]:
            print(f"  {line}", file=sys.stderr)
        sys.exit(1)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w") as f:
        f.write(rendered)

    print(f"  Generated {label}: {output_path}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Render the Streamlit snowflake.yml")
    parser.add_argument("--variables", "-v", required=True, help="Path to variables.json")
    parser.add_argument("--output-dir", "-o", required=True, help="Output directory")
    args = parser.parse_args()

    variables_path = Path(args.variables)
    if not variables_path.is_file():
        print(f"Error: variables file not found at {variables_path}", file=sys.stderr)
        sys.exit(1)

    output_dir = Path(args.output_dir)
    variables, config = load_variables(variables_path)
    base_dir = variables_path.parent

    print(f"Rendering snowflake.yml into {output_dir}")
    print("  Resolved variables:")
    for key, value in sorted(variables.items()):
        print(f"    {key} = {value}")

    render(
        base_dir / config["snowflake_yml_template"],
        output_dir / "snowflake.yml",
        variables,
        "snowflake.yml",
    )


if __name__ == "__main__":
    main()
