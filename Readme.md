# Insurance Claims Audit Demo - Setup Guide

This guide provides step-by-step instructions to deploy the Insurance Claims Audit demo using the automated `demo-up` task.

## Overview

This demo showcases an insurance claims audit system built on Snowflake, featuring:

- **Snowflake Cortex Analyst** for natural language queries on claims data
- **Cortex Search** for searching guidelines and claim notes
- **Cortex AI** for document parsing, image analysis, and audio transcription
- **Cortex Agents** for intelligent claim analysis and audit workflows
- **Streamlit in Snowflake** for the web-based user interface

The system combines structured claims data with unstructured data from claim notes, state insurance guidelines, invoices, images, and call transcriptions to provide claims auditing capabilities.

## Prerequisites

Before running the demo, ensure you have:

1. **Snowflake Account** with appropriate privileges
2. **Snowflake CLI** installed and configured
3. **Task** (Go Task Runner) installed
4. **Python 3.x** installed (for utility scripts)

### Validate Prerequisites

You can validate that Snowflake CLI is installed correctly:

```bash
task validate-prerequisites:snowcli
```

## Step 1: Warehouse, Role, and Privilege Initialization

Manually run the sql scripts found at `tasks/snow-cli/sql/batch-0` to create a dedicated warehouse, roles, database and schema. The user you use to run these scripts must have the SYSADMIN, USERADMIN and SECURITYADMIN roles. If you have a Snowflake CLI connection configured that has the SYSADMIN and USERADMIN roles, you can run the scripts by running the following command:

```bash
DOTENV_FILENAME=demo_init.env task demo-init-1
```

> Note: The `demo_init.env_template` file is a template for the environment variables used by the init tasks for the demo. It is located in the `.env` directory.
> You can copy it to `demo_init.env` and fill in the required values.
> The `CLI_CONNECTION_NAME` must match a connection configured in your Snowflake CLI that has the SYSADMIN and USERADMIN roles.

## Step 2: User Initialization

The demo requires two users to be created in Snowflake. The first user is the user that will be used to run the demo using Taskfile and the Snowflake CLI. The second user is the user that will be used to run the demo in Github Actions (still using Taskfile). Both users should be setup to use rsa-keypair authentication. Setting up the users is outside the scope of this guide, but the following steps will help you get started:

### User 1 - ga_mock

For the first user (the user that will be used to run the demo using Taskfile and the Snowflake CLI):

1. Create a service user in Snowflake named `ga_mock`. This user will be given the same role as the user that will be used to run the demo in Github Actions.
2. Generate an RSA keypair for the user.
3. Set the public key for the user in Snowflake.
4. Create a new connection in the Snowflake CLI for the user.
5. Test the connection to ensure it is working.

### User 2 - ga_dev

For the second user (the user that will be used to run the demo in Github Actions):

1. Create a service user in Snowflake named `ga_dev`. This user will be the actual user that will be used to run the demo in Github Actions.
2. Generate an RSA keypair for the user.
3. Set the public key for the user in Snowflake.
4. Set the private key for the user in the Github Actions secrets as `SNOWFLAKE_PRIVATE_KEY_RAW`.
5. Create a new connection in the Snowflake CLI for the user.
6. Test the connection to ensure it is working.

Set the network policy for the `ga_dev` user to only allow access from the Github Actions IP addresses by running the following SQL commands:

```sql
SHOW NETWORK RULES IN SNOWFLAKE.NETWORK_SECURITY;

SELECT *
  FROM SNOWFLAKE.ACCOUNT_USAGE.NETWORK_RULES
  WHERE DATABASE = 'SNOWFLAKE' 
    AND SCHEMA = 'NETWORK_SECURITY'
    AND NAME = 'GITHUBACTIONS_GLOBAL';

CREATE OR REPLACE NETWORK POLICY github_actions_ingress ALLOWED_NETWORK_RULE_LIST = (
  'SNOWFLAKE.NETWORK_SECURITY.GITHUBACTIONS_GLOBAL'
);

ALTER USER ga_dev SET NETWORK_POLICY = github_actions_ingress;
```

## Step 3: Grants Initialization

Run the following command to issue the grants to the users:

```bash
DOTENV_FILENAME=demo_init.env task demo-init-2
```

> Note: The `demo_init.env` file is a template for the environment variables used by the init tasks for the demo. It is located in the `.env` directory.
> You can copy it to `demo_init.env` and fill in the required values.
> The `CLI_CONNECTION_NAME` must match a connection configured in your Snowflake CLI that has the SYSADMIN and USERADMIN roles.

## Environment Setup

### 1. Create Environment Configuration

Create a `.env` directory in the project root:

```bash
mkdir -p .env
```

### 2. Configure Environment File

Create a `.env/demo.env` file based on the provided template. Copy and modify the following:

```bash
# This is a template for the demo.env file used by the demo scripts.
# Copy this file to demo.env and fill in the required values.

# The Snowflake connection name configured in snow-cli for keypair authentication.
CLI_CONNECTION_NAME=your_connection_name_here

# All objects are created in this database and schema.
DEMO_DATABASE_NAME=INS_CO
DEMO_SCHEMA_NAME=INS_CO.LOSS_CLAIMS

# Database name used for teardown (should match DEMO_DATABASE_NAME)
DATABASE_NAME=INS_CO

# The internal named stage used to upload files for the demo.
INTERNAL_NAMED_STAGE=@INS_CO.LOSS_CLAIMS.LOSS_EVIDENCE

# The task which runs the file upload and streamlit app deploy runs from the snow-cli directory.
# The upload and streamlit directories are relative to that.
FILE_UPLOAD_DIR="../../upload"
STREAMLIT_APP_DIR=streamlit
```

**Important Notes:**
- `CLI_CONNECTION_NAME`: Must match a connection configured in your Snowflake CLI
- `DEMO_DATABASE_NAME`: The database where all objects will be created (e.g., `INS_CO`)
- `DEMO_SCHEMA_NAME`: Fully qualified schema name in format `database.schema` (e.g., `INS_CO.LOSS_CLAIMS`)
- `DATABASE_NAME`: Used by the teardown task (should match `DEMO_DATABASE_NAME`)
- `INTERNAL_NAMED_STAGE`: Fully qualified stage name with `@` prefix (e.g., `@INS_CO.LOSS_CLAIMS.LOSS_EVIDENCE`)
- `FILE_UPLOAD_DIR` and `STREAMLIT_APP_DIR`: These are relative paths from the `tasks/snow-cli` directory

**Note:** You can use a custom environment file by naming it differently (e.g., `custom.env`) and specifying it when running tasks:

```bash
DOTENV_FILENAME=custom.env task demo-up
```

### 3. Configure Snowflake CLI Connection

Ensure your Snowflake CLI is configured with a valid connection profile that matches `CLI_CONNECTION_NAME`:

```bash
snow connection test --connection your_connection_name
```

## Deployment

### Deploy the Demo

Run the following command to deploy the entire demo:

```bash
task demo-up
```

This command executes the following steps in sequence:

1. **Validate Prerequisites** - Verify that Snowflake CLI is properly installed and configured

2. **Create Database Schema and Tables (Batch 1)** - Execute SQL files in `sql/batch-1/`:
   - Create the `INS_CO` database
   - Create the `LOSS_CLAIMS` schema
   - Create all required tables (CLAIMS, CLAIM_LINES, FINANCIAL_TRANSACTIONS, AUTHORIZATION, INVOICES, etc.)
   - Create chunk tables for notes and guidelines

3. **Upload Sample Files to Stage** - Upload all files from the `upload/` directory to the `LOSS_EVIDENCE` stage:
   - Claim evidence images (JPEG files)
   - Claim notes (PDF)
   - Guidelines (DOCX)
   - Invoices (PNG)
   - Call recordings (WAV)

4. **Create Cortex Services and Custom Tools (Batch 2)** - Execute SQL files in `sql/batch-2/`:
   - Refresh and populate the stage
   - Insert sample data into tables (DML operations)
   - Create Cortex Search services for claim notes and guidelines
   - Create custom functions for document processing, image analysis, transcription, etc.
   - Create semantic views for Cortex Analyst
   - Create MCP server configuration

5. **Create the Agent** - Deploy the Claims Audit Agent with integrated tools:
   - Cortex Analyst for SQL-based queries
   - Cortex Search for guidelines and notes
   - Custom tools for document parsing, image analysis, audio transcription, document classification, and PII redaction

6. **Deploy Streamlit App** - Deploy the web-based claims audit interface to Snowflake

### What Gets Created

The deployment creates the following Snowflake objects:

#### Database & Schema
- Database: `INS_CO`
- Schema: `LOSS_CLAIMS`

#### Tables
- `CLAIMS` - Main claims data with policy details and loss information
- `CLAIM_LINES` - Individual line items for each claim
- `FINANCIAL_TRANSACTIONS` - Payment and reserve transactions
- `AUTHORIZATION` - Performer authorization limits
- `INVOICES` - Vendor invoices and line items
- `PARSED_CLAIM_NOTES` - Extracted content from claim notes
- `PARSED_GUIDELINES` - Extracted content from insurance guidelines
- `PARSED_INVOICES` - Extracted content from invoice documents
- `NOTES_CHUNK_TABLE` - Chunked claim notes for search
- `GUIDELINES_CHUNK_TABLE` - Chunked guidelines for search

#### Stages
- `LOSS_EVIDENCE` - Internal stage for claim evidence files (images, documents, audio)

#### Cortex Services
- **Cortex Search Services:**
  - `INS_CO_CLAIM_NOTES` - Search service for claim notes
  - `INS_CO_GUIDELINES` - Search service for insurance guidelines

- **Semantic Model:**
  - `CA_INS_CO` - Cortex Analyst semantic model for the claims database

#### Custom Functions & Procedures
- `CLASSIFY_DOCUMENT` - AI-powered document classification
- `PARSE_DOCUMENT_FROM_STAGE` - Extract text from documents
- `GET_IMAGE_SUMMARY` - Generate AI summaries of images
- `TRANSCRIBE_AUDIO_SIMPLE` - Transcribe audio/video files
- `REDACT_CLAIM_EMAIL_PII` - Redact PII from emails

#### Agent
- `CLAIMS_AUDIT_AGENT` - Intelligent agent with access to all tools and data

#### Streamlit Application
- Claims audit web interface with natural language query capabilities

## Using the Demo

### Sample Files

The demo includes sample files in the `upload/` directory:

- `1899_claim_evidence1.jpeg` - Claim evidence photo
- `1899_claim_evidence2.jpeg` - Additional claim evidence
- `Claim_Notes.pdf` - Claim documentation
- `Gemini_Generated3.jpeg` - Sample generated image
- `Guidelines.docx` - Insurance guidelines document
- `ins_co_1899_call.wav` - Customer service call recording
- `invoice.png` - Invoice image

These files are uploaded to the `LOSS_EVIDENCE` stage during deployment.

### Sample Questions

Once deployed, you can ask the Claims Audit Agent questions like:

- "Based on the state of New Jersey's insurance claims guidelines, have any of my claims been outside of the mandated settlement window?"
- "Was there a reserve rationale in the file notes?"
- "Was a payment made in excess of the reserve amount for claim 1899?"
- "Can you transcribe the media file 'ins_co_1899_call.wav' stored in '@ins_co.loss_claims.loss_evidence'?"
- "What is the caller's intent?"
- "Can you give me a summary of 1899_claim_evidence1.jpeg image please?"
- "What is the similarity score between the summary of the claim evidence and the claim description for claim 1899?"
- "Does the file Gemini_Generated3.jpeg appear to be tampered with?"
- "Is claim 1899 complete?"

### Access the Streamlit App

After deployment, the Streamlit app will automatically open in your browser. You can also access it through:

1. Snowsight UI → Streamlit Apps
2. Navigate to the `INS_CO.LOSS_CLAIMS` schema
3. Find and open the deployed Streamlit app

### Access the Agent

The agent can be accessed through:

1. **Snowflake Intelligence** - Use the Claims Audit Agent in conversational mode
2. **SQL Interface** - Call the agent programmatically via SQL
3. **Streamlit App** - Interact through the web interface

## Teardown

### Remove the Demo

To completely remove the demo and all created objects:

```bash
task demo-down
```

This will drop the database specified in `DATABASE_NAME` (configured in your `.env/demo.env` file) and all its contents (schemas, tables, stages, functions, agents, etc.).

## Advanced Usage

### Running Individual Tasks

You can run specific parts of the deployment individually:

#### Create Database and Tables Only
```bash
task snow-cli:sort-and-process-sql-folder \
  SQL_SORT_PROCESS_DIR=sql/batch-1 \
  CLI_CONNECTION_NAME=$CLI_CONNECTION_NAME
```

#### Upload Files to Stage
```bash
task snow-cli:upload-files-to-internal-named-stage \
  FILE_UPLOAD_DIR=$FILE_UPLOAD_DIR \
  CLI_CONNECTION_NAME=$CLI_CONNECTION_NAME \
  INTERNAL_NAMED_STAGE=$INTERNAL_NAMED_STAGE
```

#### Process Additional SQL Files
```bash
task snow-cli:sort-and-process-sql-folder \
  SQL_SORT_PROCESS_DIR=sql/batch-2 \
  CLI_CONNECTION_NAME=$CLI_CONNECTION_NAME
```

#### Create Agent Only
```bash
task snow-cli:create-agent
```

#### Deploy Streamlit App Only
```bash
task snow-cli:deploy-streamlit-app \
  STREAMLIT_APP_DIR=$STREAMLIT_APP_DIR \
  CLI_CONNECTION_NAME=$CLI_CONNECTION_NAME
```

### Customizing the Agent

The agent configuration is stored in `tasks/snow-cli/agent/sql/create_agents.sql`. To modify:

1. Make changes to the agent specification
2. Run: `task snow-cli:create-agent`

### Updating the Streamlit App

To update the Streamlit app after making changes:

```bash
task snow-cli:deploy-streamlit-app \
  STREAMLIT_APP_DIR=tasks/snow-cli/streamlit \
  CLI_CONNECTION_NAME=$CLI_CONNECTION_NAME
```

The `--replace` flag ensures the existing app is updated.

## Architecture

### Data Flow

1. **Structured Data** → Claims tables → Cortex Analyst (SQL queries)
2. **Unstructured Data** → Document parsing → Chunking → Cortex Search
3. **Media Files** → AI processing (transcription, image analysis) → Analysis results
4. **User Query** → Agent → Tool selection → Result synthesis

### Tool Integration

The Claims Audit Agent integrates multiple Cortex AI capabilities:

- **TEXT2SQL** - Converts natural language to SQL queries
- **SEARCH_GUIDELINES** - Searches insurance guidelines documents
- **SEARCH_CLAIM_NOTES** - Searches claim-specific notes
- **CLASSIFY_FUNCTION** - Classifies document types
- **Parse_document** - Extracts text from documents
- **Image_summary** - Generates image descriptions
- **TRANSCRIBE_CALLS** - Converts audio to text
- **REDACT_EMAIL** - Removes PII from emails

## Troubleshooting

### Connection Issues

If you encounter connection errors:

1. Verify your Snowflake CLI connection:
   ```bash
   snow connection test --connection your_connection_name
   ```

2. Check your `.env/demo.env` file has correct values

3. Ensure you have necessary privileges in Snowflake

### Deployment Failures

If the deployment fails:

1. Check the task output for specific error messages
2. Verify all prerequisites are met
3. Try running individual tasks to isolate the issue
4. Run teardown and retry: `task demo-down && task demo-up`

### Streamlit App Issues

If the Streamlit app doesn't deploy:

1. Check that the `STREAMLIT_APP_DIR` path is correct
2. Verify `streamlit_app.py` and `environment.yml` exist in the directory
3. Check Snowflake privileges for deploying Streamlit apps

## Project Structure

```
.
├── Taskfile.yml                          # Main task definitions
├── .env/                                 # Environment configurations
│   └── demo.env                         # Demo environment variables
├── tasks/
│   ├── snow-cli/
│   │   ├── snowcli-tasks.yml           # Snowflake CLI task definitions
│   │   ├── sql/
│   │   │   ├── batch-1/                # Initial setup SQL files
│   │   │   └── batch-2/                # Secondary setup SQL files
│   │   ├── agent/
│   │   │   └── sql/
│   │   │       └── create_agents.sql   # Agent configuration
│   │   ├── streamlit/
│   │   │   ├── streamlit_app.py        # Streamlit application
│   │   │   └── environment.yml         # Python dependencies
│   │   └── pyutil/                     # Python utility scripts
│   └── validate-prerequisites/         # Prerequisite validation tasks
└── upload/                              # Sample claim evidence files
```

## Support and Documentation

For more information:

- [Snowflake Cortex Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex)
- [Snowflake CLI Documentation](https://docs.snowflake.com/en/developer-guide/snowflake-cli/index)
- [Streamlit in Snowflake Documentation](https://docs.snowflake.com/en/developer-guide/streamlit/about-streamlit)
- [Task Runner Documentation](https://taskfile.dev/)

## License

See project license file for details.
