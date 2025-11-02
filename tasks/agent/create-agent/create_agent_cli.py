import requests
import json
import argparse
import sys
from pathlib import Path
from typing import Dict, List, Tuple


def create_agent_via_rest_api(token, json_file_path, base_url_override=None, database_override=None, schema_override=None, agent_name_override=None):
    """
    Create or replace a Snowflake agent using the provided configuration.
    
    Args:
        token: The Bearer token for authorization
        json_file_path: Path to the JSON file containing the agent configuration
        base_url_override: Optional base URL to override the one in JSON
        database_override: Optional database name to override the one in JSON
        schema_override: Optional schema name to override the one in JSON
        agent_name_override: Optional agent name to override the one in the JSON
    
    Returns:
        Tuple of (response object, payload_data dict, constructed_url)
    """
    # Read the JSON configuration from file
    try:
        with open(json_file_path, 'r') as f:
            config = json.load(f)
    except FileNotFoundError:
        raise FileNotFoundError(f"JSON file not found at {json_file_path}")
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid JSON in file {json_file_path}: {e}")
    
    # Extract configuration values
    base_url = base_url_override or config.get('base_url')
    database = database_override or config.get('database')
    schema = schema_override or config.get('schema')
    
    if not base_url:
        raise ValueError(f"Missing 'base_url' in {json_file_path}")
    if not database:
        raise ValueError(f"Missing 'database' in {json_file_path}")
    if not schema:
        raise ValueError(f"Missing 'schema' in {json_file_path}")
    
    # Get the POST body
    payload_data = config.get('agent_create_post_body')
    if not payload_data:
        raise ValueError(f"Missing 'agent_create_post_body' in {json_file_path}")
    
    # Override agent name if provided
    if agent_name_override:
        payload_data['name'] = agent_name_override
    
    # Construct the API URL
    # Ensure base_url doesn't have https:// prefix (we'll add it)
    base_url = base_url.replace('https://', '').replace('http://', '')
    url = f"https://{base_url}/api/v2/databases/{database}/schemas/{schema}/agents?createMode=orReplace"
    
    # Convert to JSON string
    payload = json.dumps(payload_data)
    
    # Set up headers
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': f'Bearer {token}'
    }
    
    # Make the API request
    response = requests.request("POST", url, headers=headers, data=payload)
    
    return response, payload_data, url


def find_json_files(json_dir: Path) -> List[Path]:
    """
    Find all JSON files in the specified directory.
    
    Args:
        json_dir: Path to the directory containing JSON files
    
    Returns:
        List of Path objects for JSON files
    """
    if not json_dir.exists():
        return []
    
    if not json_dir.is_dir():
        return []
    
    return sorted(json_dir.glob('*.json'))


def process_single_agent(token: str, json_path: Path, verbose: bool, base_url_override: str = None, 
                         database_override: str = None, schema_override: str = None) -> Tuple[bool, Dict]:
    """
    Process a single agent creation.
    
    Returns:
        Tuple of (success boolean, result dict)
    """
    result = {
        'file': json_path.name,
        'path': str(json_path),
        'status': None,
        'agent_name': None,
        'url': None,
        'error': None
    }
    
    try:
        response, payload_data, url = create_agent_via_rest_api(
            token, json_path, base_url_override, database_override, schema_override
        )
        result['status'] = response.status_code
        result['agent_name'] = payload_data.get('name', 'Unknown')
        result['url'] = url
        
        success = response.status_code in [200, 201]
        
        if not success:
            result['error'] = response.text
        
        if verbose:
            result['response_headers'] = dict(response.headers)
            try:
                result['response_body'] = response.json()
            except json.JSONDecodeError:
                result['response_body'] = response.text
        
        return success, result
        
    except Exception as e:
        result['error'] = str(e)
        return False, result


def main():
    parser = argparse.ArgumentParser(
        description='Create or replace Snowflake agent(s) via API. Configuration is read from JSON files.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Process all JSON files in the json/ directory (uses base_url, database, schema from each JSON)
  python create_agent_cli.py --token "eyJraWQiOiI0MDY2OTA1MTc2NjY1MCIsImFsZyI6IkVTMjU2In0..."

  # Process a specific JSON file
  python create_agent_cli.py -t <token> -j claims-audit-agent.json

  # Override base URL for all files
  python create_agent_cli.py -t <token> --base-url myinstance.snowflakecomputing.com

  # Override database and schema for all files
  python create_agent_cli.py -t <token> --database my_db --schema my_schema

  # Process with verbose output
  python create_agent_cli.py -t <token> -v

JSON File Structure:
  Each JSON file should contain:
  - base_url: Snowflake instance URL
  - database: Target database name
  - schema: Target schema name
  - agent_create_post_body: Agent configuration object
        """
    )
    
    parser.add_argument(
        '-t', '--token',
        required=True,
        help='Bearer token for authorization'
    )
    
    parser.add_argument(
        '-j', '--json',
        required=False,
        help='Path to a specific JSON file. If not provided, will process all JSON files in the json/ subdirectory'
    )
    
    parser.add_argument(
        '-d', '--json-dir',
        required=False,
        default='json',
        help='Directory containing JSON files (default: json/). Only used if --json is not specified'
    )
    
    parser.add_argument(
        '--base-url',
        required=False,
        help='Override the base_url from JSON files (e.g., myinstance.snowflakecomputing.com)'
    )
    
    parser.add_argument(
        '--database',
        required=False,
        help='Override the database from JSON files'
    )
    
    parser.add_argument(
        '--schema',
        required=False,
        help='Override the schema from JSON files'
    )
    
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Print detailed response information'
    )
    
    args = parser.parse_args()
    
    script_dir = Path(__file__).parent
    json_files = []
    
    # Determine which JSON files to process
    if args.json:
        # Process a specific file
        json_path = Path(args.json)
        if not json_path.is_absolute():
            json_path = script_dir / json_path
        
        if not json_path.exists():
            print(f"Error: JSON file not found at {json_path}")
            sys.exit(1)
        
        json_files = [json_path]
        print(f"Processing single file: {json_path}")
    else:
        # Process all files in the json directory
        json_dir = Path(args.json_dir)
        if not json_dir.is_absolute():
            json_dir = script_dir / json_dir
        
        json_files = find_json_files(json_dir)
        
        if not json_files:
            print(f"Error: No JSON files found in {json_dir}")
            print(f"Hint: Create the directory or specify a file with --json")
            sys.exit(1)
        
        print(f"Found {len(json_files)} JSON file(s) in {json_dir}")
    
    # Display override information if any
    overrides = []
    if args.base_url:
        overrides.append(f"Base URL: {args.base_url}")
    if args.database:
        overrides.append(f"Database: {args.database}")
    if args.schema:
        overrides.append(f"Schema: {args.schema}")
    
    if overrides:
        print(f"Overrides applied: {', '.join(overrides)}")
    
    print("=" * 80)
    
    # Process each JSON file
    results = []
    success_count = 0
    failure_count = 0
    
    for json_file in json_files:
        print(f"\nProcessing: {json_file.name}")
        print("-" * 80)
        
        success, result = process_single_agent(
            args.token, 
            json_file, 
            args.verbose,
            args.base_url,
            args.database,
            args.schema
        )
        results.append(result)
        
        if success:
            success_count += 1
            print(f"✓ SUCCESS - Agent '{result['agent_name']}' created/updated (Status: {result['status']})")
            if args.verbose or args.base_url or args.database or args.schema:
                print(f"  URL: {result['url']}")
        else:
            failure_count += 1
            print(f"✗ FAILED - Status: {result.get('status', 'N/A')}")
            if result['error']:
                # Print first 200 chars of error, or full error if shorter
                error_text = result['error']
                if len(error_text) > 200:
                    print(f"  Error: {error_text[:200]}...")
                else:
                    print(f"  Error: {error_text}")
        
        if args.verbose and 'response_body' in result:
            print("\nDetailed Response:")
            if isinstance(result['response_body'], dict):
                print(json.dumps(result['response_body'], indent=2))
            else:
                print(result['response_body'])
    
    # Print summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Total files processed: {len(json_files)}")
    print(f"Successful: {success_count}")
    print(f"Failed: {failure_count}")
    
    if failure_count > 0:
        print("\nFailed agents:")
        for result in results:
            if result['status'] not in [200, 201, None]:
                print(f"  - {result['file']} (Agent: {result.get('agent_name', 'Unknown')})")
            elif result['status'] is None and result['error']:
                print(f"  - {result['file']} (Error: Configuration issue)")
    
    # Exit with appropriate code
    sys.exit(0 if failure_count == 0 else 1)


if __name__ == "__main__":
    main()
