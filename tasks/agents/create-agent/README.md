# Agent Creation CLI Tool

This directory contains a Python script to create or update Snowflake agents via API. The script can process a single JSON file or batch-process multiple JSON files. Configuration including the Snowflake instance URL, database, and schema are stored in each JSON file.

## Directory Structure

```text
create-agent/
├── create_agent_cli.py     # Main CLI script
├── create_agent.py          # Original template (deprecated)
├── json/                    # JSON configuration files for agents
│   └── claims-audit-agent.json
└── README.md
```

## Prerequisites

- Python 3.7+
- `requests` library: `pip install requests`

## JSON File Structure

Each JSON file must contain the following top-level fields:

```json
{
  "base_url": "yourinstance.snowflakecomputing.com",
  "database": "your_database",
  "schema": "your_schema",
  "agent_create_post_body": {
    "name": "AGENT_NAME",
    "comment": "Agent description",
    "profile": { ... },
    "models": { ... },
    "instructions": { ... },
    "tools": [ ... ],
    "tool_resources": { ... }
  }
}
```

- **base_url**: Your Snowflake instance URL (without https://)
- **database**: Target database name
- **schema**: Target schema name  
- **agent_create_post_body**: The complete agent configuration object

See `json/claims-audit-agent.json` for a complete example.

## Usage

### Batch Process All JSON Files

Process all JSON files in the `json/` directory (uses configuration from each file):

```bash
python create_agent_cli.py --token "YOUR_BEARER_TOKEN"
```

### Process a Specific JSON File

Process a single JSON file:

```bash
python create_agent_cli.py \
  --token "YOUR_BEARER_TOKEN" \
  --json json/claims-audit-agent.json
```

### Override Configuration Values

Override base URL, database, or schema for all files:

```bash
# Override base URL
python create_agent_cli.py \
  --token "YOUR_BEARER_TOKEN" \
  --base-url myinstance.snowflakecomputing.com

# Override database and schema
python create_agent_cli.py \
  --token "YOUR_BEARER_TOKEN" \
  --database my_database \
  --schema my_schema

# Override all three
python create_agent_cli.py \
  --token "YOUR_BEARER_TOKEN" \
  --base-url myinstance.snowflakecomputing.com \
  --database my_database \
  --schema my_schema
```

### Use Custom JSON Directory

Specify a different directory containing JSON files:

```bash
python create_agent_cli.py \
  --token "YOUR_BEARER_TOKEN" \
  --json-dir /path/to/json/files
```

### Verbose Output

Get detailed response information and see the constructed URLs:

```bash
python create_agent_cli.py -t "YOUR_BEARER_TOKEN" -v
```

## Command-Line Arguments

| Argument | Short | Required | Description |
|----------|-------|----------|-------------|
| `--token` | `-t` | Yes | Bearer token for authorization |
| `--json` | `-j` | No | Path to specific JSON file. If not provided, processes all files in json directory |
| `--json-dir` | `-d` | No | Directory containing JSON files (default: `json/`) |
| `--base-url` | | No | Override base_url from JSON files |
| `--database` | | No | Override database from JSON files |
| `--schema` | | No | Override schema from JSON files |
| `--verbose` | `-v` | No | Print detailed response information including URLs |

## Output

The script provides:

- Progress updates for each file being processed
- Success/failure status with agent names
- Constructed API URLs (in verbose mode or when using overrides)
- Summary statistics (total processed, successful, failed)
- Error messages for failed operations
- Detailed responses in verbose mode

### Example Output

```text
Found 2 JSON file(s) in /path/to/create-agent/json
================================================================================

Processing: claims-audit-agent.json
--------------------------------------------------------------------------------
✓ SUCCESS - Agent 'CLAIMS_AUDIT_AGENT' created/updated (Status: 200)

Processing: another-agent.json
--------------------------------------------------------------------------------
✓ SUCCESS - Agent 'ANOTHER_AGENT' created/updated (Status: 200)

================================================================================
SUMMARY
================================================================================
Total files processed: 2
Successful: 2
Failed: 0
```

### With Overrides

```text
Found 1 JSON file(s) in /path/to/create-agent/json
Overrides applied: Base URL: myinstance.snowflakecomputing.com, Database: prod_db
================================================================================

Processing: claims-audit-agent.json
--------------------------------------------------------------------------------
✓ SUCCESS - Agent 'CLAIMS_AUDIT_AGENT' created/updated (Status: 200)
  URL: https://myinstance.snowflakecomputing.com/api/v2/databases/prod_db/schemas/agents/agents?createMode=orReplace
```

## Getting a Bearer Token

To get a bearer token for authentication:

1. Use Snowflake OAuth or JWT authentication
2. Or use Snowflake CLI: `snow connection token --connection <connection_name>`
3. The token should be used in the `Authorization: Bearer <token>` header

## Error Handling

The script includes comprehensive error handling:

- Missing configuration fields (base_url, database, schema, agent_create_post_body)
- File not found errors
- Invalid JSON syntax errors
- API request failures
- Network issues

Exit codes:

- `0`: All operations successful
- `1`: One or more operations failed

## Adding New Agents

1. Create a new JSON file in the `json/` directory
2. Include all required fields: `base_url`, `database`, `schema`, `agent_create_post_body`
3. Run the script to create all agents in one batch

Example minimal JSON:

```json
{
  "base_url": "myinstance.snowflakecomputing.com",
  "database": "my_database",
  "schema": "my_schema",
  "agent_create_post_body": {
    "name": "MY_AGENT",
    "comment": "My agent description",
    "models": {
      "orchestration": "claude-4-sonnet"
    },
    "tools": [],
    "tool_resources": {}
  }
}
```

## Tips

- Store bearer tokens securely (use environment variables or secure vaults)
- Test with a single file first using `--json` flag
- Use `--verbose` to see constructed URLs and troubleshoot issues
- Use override flags (`--base-url`, `--database`, `--schema`) when deploying to different environments
- The script automatically adds `createMode=orReplace` to update existing agents
- Each JSON file can target different databases/schemas by having different values
