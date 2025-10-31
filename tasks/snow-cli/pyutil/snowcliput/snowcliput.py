#!/usr/bin/env python3
"""
upload_to_snowflake.py - Upload files to Snowflake internal stage using PUT command

Uploads all files from the snow-cli/upload directory to a Snowflake internal stage
using the Snowflake CLI and PUT command.
"""

import subprocess
import sys
from pathlib import Path
from typing import List, Tuple


def get_upload_files(upload_dir: Path) -> List[Path]:
    """
    Get all files from the upload directory.
    
    Args:
        upload_dir: Path to the upload directory
        
    Returns:
        List of file paths to upload
    """
    if not upload_dir.exists():
        raise FileNotFoundError(f"Upload directory not found: {upload_dir}")
    
    if not upload_dir.is_dir():
        raise NotADirectoryError(f"Path is not a directory: {upload_dir}")
    
    files = [f for f in upload_dir.iterdir() if f.is_file()]
    
    if not files:
        print(f"Warning: No files found in {upload_dir}")
        return []
    
    return sorted(files)


def upload_file_to_stage(
    connection_name: str,
    file_path: Path,
    stage_name: str,
    auto_compress: bool = True,
    overwrite: bool = True,
    verbose: bool = True
) -> Tuple[bool, str]:
    """
    Upload a single file to Snowflake internal stage using PUT command.
    
    Args:
        connection_name: Snowflake CLI connection name
        file_path: Path to the file to upload
        stage_name: Snowflake stage name (e.g., '@my_stage' or 'my_stage')
        auto_compress: Auto-compress file during upload
        overwrite: Overwrite existing files
        verbose: Print execution details
        
    Returns:
        Tuple of (success: bool, message: str)
    """
    # Ensure stage name starts with @
    if not stage_name.startswith('@'):
        stage_name = f'@{stage_name}'
    
    # Build the PUT command
    auto_compress_str = 'TRUE' if auto_compress else 'FALSE'
    overwrite_str = 'TRUE' if overwrite else 'FALSE'
    
    put_query = (
        f"PUT 'file://{file_path.absolute()}' {stage_name} "
        f"AUTO_COMPRESS={auto_compress_str} OVERWRITE={overwrite_str}"
    )
    
    cmd = ['snow', 'sql', '-c', connection_name, '-q', put_query]
    
    if verbose:
        print(f"  Uploading: {file_path.name}...", end=' ', flush=True)
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True
        )
        
        if verbose:
            print("✓")
        
        return True, result.stdout
        
    except subprocess.CalledProcessError as e:
        error_msg = f"Failed to upload {file_path.name}"
        if verbose:
            print("✗")
            print(f"    Error: {error_msg}", file=sys.stderr)
            if e.stderr:
                print(f"    Details: {e.stderr}", file=sys.stderr)
        
        return False, error_msg


def upload_directory_to_stage(
    connection_name: str,
    upload_dir: Path,
    stage_name: str,
    auto_compress: bool = True,
    overwrite: bool = True,
    verbose: bool = True
) -> Tuple[int, int, List[str]]:
    """
    Upload all files from a directory to Snowflake internal stage.
    
    Args:
        connection_name: Snowflake CLI connection name
        upload_dir: Path to the directory containing files to upload
        stage_name: Snowflake stage name
        auto_compress: Auto-compress files during upload
        overwrite: Overwrite existing files
        verbose: Print execution details
        
    Returns:
        Tuple of (successful_count, failed_count, error_messages)
    """
    files = get_upload_files(upload_dir)
    
    if not files:
        return 0, 0, []
    
    if verbose:
        print(f"\n{'='*60}")
        print(f"Uploading {len(files)} file(s) to stage: {stage_name}")
        print(f"Connection: {connection_name}")
        print(f"Source directory: {upload_dir}")
        print(f"{'='*60}\n")
    
    successful = 0
    failed = 0
    error_messages = []
    
    for file_path in files:
        success, message = upload_file_to_stage(
            connection_name,
            file_path,
            stage_name,
            auto_compress,
            overwrite,
            verbose
        )
        
        if success:
            successful += 1
        else:
            failed += 1
            error_messages.append(message)
    
    if verbose:
        print(f"\n{'='*60}")
        print(f"Upload Summary:")
        print(f"  Successful: {successful}/{len(files)}")
        print(f"  Failed:     {failed}/{len(files)}")
        print(f"{'='*60}")
    
    return successful, failed, error_messages


def main():
    """
    Main entry point for command-line execution.
    
    Usage:
        python upload_to_snowflake.py <connection_name> <stage_name> [upload_directory]
    
    Example:
        python upload_to_snowflake.py my_connection loss_evidence
        python upload_to_snowflake.py my_connection @loss_evidence ./custom_upload_dir
    """
    if len(sys.argv) < 3:
        print("Error: Missing required arguments", file=sys.stderr)
        print("\nUsage: python upload_to_snowflake.py <connection_name> <stage_name> [upload_directory]")
        print("\nArguments:")
        print("  connection_name   : Snowflake CLI connection name")
        print("  stage_name        : Snowflake internal stage name (with or without @ prefix)")
        print("  upload_directory  : Optional. Path to upload directory (default: ./tasks/snow-cli/upload)")
        print("\nExample:")
        print("  python upload_to_snowflake.py my_connection loss_evidence")
        print("  python upload_to_snowflake.py my_connection @loss_evidence ./data")
        sys.exit(1)
    
    connection_name = sys.argv[1]
    stage_name = sys.argv[2]
    
    # Determine upload directory
    if len(sys.argv) >= 4:
        upload_dir = Path(sys.argv[3])
    else:
        # Default to snow-cli/upload directory relative to script location
        script_dir = Path(__file__).parent
        project_root = script_dir.parent.parent.parent if 'tasks' in script_dir.parts else script_dir
        upload_dir = project_root / 'tasks' / 'snow-cli' / 'upload'
    
    # Validate inputs
    if not connection_name or not connection_name.strip():
        print("Error: Connection name cannot be empty", file=sys.stderr)
        sys.exit(1)
    
    if not stage_name or not stage_name.strip():
        print("Error: Stage name cannot be empty", file=sys.stderr)
        sys.exit(1)
    
    try:
        successful, failed, error_messages = upload_directory_to_stage(
            connection_name=connection_name,
            upload_dir=upload_dir,
            stage_name=stage_name,
            auto_compress=True,
            overwrite=True,
            verbose=True
        )
        
        if failed > 0:
            print(f"\n⚠️  {failed} file(s) failed to upload:", file=sys.stderr)
            for msg in error_messages:
                print(f"  - {msg}", file=sys.stderr)
            sys.exit(1)
        
        if successful == 0:
            print("\n⚠️  No files were uploaded.")
            sys.exit(0)
        
        print(f"\n✓ Successfully uploaded {successful} file(s) to {stage_name}")
        sys.exit(0)
        
    except FileNotFoundError as e:
        print(f"\nERROR: {e}", file=sys.stderr)
        sys.exit(1)
    except NotADirectoryError as e:
        print(f"\nERROR: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"\nERROR: Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()