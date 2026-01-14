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

## Personas

This demo is designed for two distinct personas:

### Admin Persona

**Role:** Platform Administrator / Database Administrator

**Responsibilities:**

- Initial Snowflake environment setup (warehouses, roles, privileges)
- Database and schema creation
- Grant management and security configuration
- Table structure creation and data loading
- Stage creation and file uploads
- Cortex Search services configuration
- Custom functions and procedures deployment
- Infrastructure and security setup

**Handles:** Batch-0 (infrastructure), Batch-1 (grants), and Batch-2 (schema objects) SQL deployments

### AI Engineer Persona

**Role:** Application Developer / AI/ML Engineer

**Responsibilities:**

- Data population and transformation (Batch-3)
- Cortex AI services configuration
- Semantic model development
- Agent configuration and deployment
- Streamlit application development and deployment
- Testing and iterating on agent behavior
- Application-level customizations

**Handles:** Batch-3 SQL deployments (data & AI services), Agent creation, and Streamlit deployment

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

## Admin Setup (One-Time Initialization)

The following steps must be performed by the **Admin Persona** with elevated Snowflake privileges. These are one-time setup steps that create the infrastructure and security foundation for the demo.

### Step 1: Infrastructure Initialization (Batch-0)

**Persona:** Admin (requires SYSADMIN and USERADMIN roles)

This step creates the foundational Snowflake objects: warehouses, roles, database, and schema.

**Prerequisites:**

- A Snowflake user with SYSADMIN and USERADMIN roles
- A Snowflake CLI connection configured for this user

**Create the demo_init.env file:**

Create a `.env/demo_init.env` file for the initialization tasks:

```bash
# The Snowflake connection name configured in snow-cli for keypair authentication.
CLI_CONNECTION_NAME=your_admin_connection_name_here
DEMO_DATABASE_NAME=ins_co
```

**Run the infrastructure initialization:**

```bash
$ DOTENV_FILENAME=demo_init.env task demo-init-1
Snowflake CLI (snow) is installed.
task: [snow-cli:sort-and-process-sql-folder] python3 pyutil/snowclisp/snowclisp.py "sql/batch-0" "$CLI_CONNECTION_NAME"
Scanning directory: sql/batch-0                                                                                                                                                                              

Found 3 SQL file(s) with numeric prefix:
  1. [001] 001-create_warehouses.sql
  2. [002] 002-init_roles.sql
  3. [003] 003-db_schema.sql

Using Snowflake connection: your_admin_connection_name_here

============================================================
Executing 3 SQL file(s) in order:
  1. 001-create_warehouses.sql
  2. 002-init_roles.sql
  3. 003-db_schema.sql
============================================================
Running command:
  snow sql -c your_admin_connection_name_here \
    -f sql/batch-0/001-create_warehouses.sql \
    -f sql/batch-0/002-init_roles.sql \
    -f sql/batch-0/003-db_schema.sql \

USE ROLE sysadmin;
+----------------------------------+
| status                           |
|----------------------------------|
| Statement executed successfully. |
+----------------------------------+
CREATE OR REPLACE WAREHOUSE demo_s_wh
    WITH WAREHOUSE_SIZE = SMALL
    INITIALLY_SUSPENDED = TRUE;
+-------------------------------------------+
| status                                    |
|-------------------------------------------|
| Warehouse DEMO_S_WH successfully created. |
+-------------------------------------------+
...

============================================================
✓ Successfully executed all 3 SQL file(s)
============================================================
```

This executes SQL files in `sql/batch-0/`:

- Creates the `INS_CO_WH` warehouse
- Creates roles: `INS_CO_ADMIN` and `INS_CO_USER`
- Creates the `INS_CO` database
- Creates the `LOSS_CLAIMS` schema

### Step 2: Grant Configuration (Batch-1)

**Persona:** Admin (requires SYSADMIN and USERADMIN roles)

This step configures all necessary grants and permissions for the demo users and roles.

**Run the grants configuration:**

```bash
$ DOTENV_FILENAME=demo_init.env task demo-init-2
Snowflake CLI (snow) is installed.
task: [snow-cli:sort-and-process-sql-folder] python3 pyutil/snowclisp/snowclisp.py "sql/batch-1" "$CLI_CONNECTION_NAME"
Scanning directory: sql/batch-1

Found 3 SQL file(s) with numeric prefix:
  1. [001] 001-grants.sql
  2. [002] 002-grants-cortex-ai.sql
  3. [003] 003-grants_streamlit.sql

Using Snowflake connection: your_admin_connection_name_here

============================================================
Executing 3 SQL file(s) in order:
  1. 001-grants.sql
  2. 002-grants-cortex-ai.sql
  3. 003-grants_streamlit.sql
============================================================
Running command:
  snow sql -c your_admin_connection_name_here \
    -f sql/batch-1/001-grants.sql \
    -f sql/batch-1/002-grants-cortex-ai.sql \
    -f sql/batch-1/003-grants_streamlit.sql \

USE ROLE securityadmin;
+----------------------------------+
| status                           |
|----------------------------------|
| Statement executed successfully. |
+----------------------------------+
GRANT USAGE on WAREHOUSE demo_s_wh TO ROLE ins_co_claims_rw;
+----------------------------------+
| status                           |
|----------------------------------|
| Statement executed successfully. |
+----------------------------------+
...

============================================================
✓ Successfully executed all 3 SQL file(s)
============================================================
```

This executes SQL files in `sql/batch-1/`:

- Grants database and schema privileges to roles
- Configures Cortex AI permissions
- Sets up Cortex Search Intelligence permissions
- Configures Streamlit deployment permissions

### Step 3: User Setup

**Persona:** Admin (requires USERADMIN roles)

The demo requires service users to be created in Snowflake with RSA keypair authentication. Setting up the users is outside the scope of this guide, but the following provides an overview:

#### User 1 - Local Development User

For local development and testing:

1. Create a service user in Snowflake (e.g., `ga_mock`)
2. Generate an RSA keypair for the user
3. Set the public key for the user in Snowflake
4. Grant the `INS_CO_USER` role to the user
5. Create a new connection in the Snowflake CLI for the user
6. Test the connection to ensure it is working

#### User 2 - GitHub Actions User (Optional)

For CI/CD deployment via GitHub Actions:

1. Create a service user in Snowflake (e.g., `ga_dev`)
2. Generate an RSA keypair for the user
3. Set the public key for the user in Snowflake
4. Grant the `INS_CO_USER` role to the user
5. Set the private key in GitHub Actions secrets as `SNOWFLAKE_PRIVATE_KEY_RAW`
6. Create a new connection in the Snowflake CLI for the user

**Optional: Set network policy for GitHub Actions user:**

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

## Environment Setup for Demo Deployment

### Persona: Admin & Engineer

After completing the admin persona steps above, configure the environment for engineer persona demo deployment. This uses a different connection (the service user created in Step 3) with standard privileges.

### 1. Configure Demo Environment File

Create a `.env/demo.env` file based on the provided template. This is used by the regular demo users (not the elevated admin user):

```bash
# This is a template for the demo.env file used by the demo scripts.
# Copy this file to demo.env and fill in the required values.

# The Snowflake connection name for your service user (e.g., ga_mock)
# This should be a standard user with INS_CO_USER role, NOT the admin user
CLI_CONNECTION_NAME=your_service_user_connection_name_here

# All objects are created in this database and schema (created by admin in batch-0)
DEMO_DATABASE_NAME=INS_CO
DEMO_SCHEMA_NAME=INS_CO.LOSS_CLAIMS

# Database name used for teardown (should match DEMO_DATABASE_NAME)
DATABASE_NAME=INS_CO

# The internal named stage used to upload files for the demo
INTERNAL_NAMED_STAGE=@INS_CO.LOSS_CLAIMS.LOSS_EVIDENCE

# The task which runs the file upload and streamlit app deploy runs from the snow-cli directory
# The upload and streamlit directories are relative to that
FILE_UPLOAD_DIR="../../upload"
STREAMLIT_APP_DIR=streamlit
```

**Important Notes:**

- `CLI_CONNECTION_NAME`: Must match a connection configured in your Snowflake CLI for your service user (e.g., `ga_mock` or `ga_dev`), NOT the admin user
- This user should have the `INS_CO_USER` role granted (configured in Step 2 above)
- `DEMO_DATABASE_NAME`: The database created by the admin (e.g., `INS_CO`)
- `DEMO_SCHEMA_NAME`: Fully qualified schema name in format `database.schema` (e.g., `INS_CO.LOSS_CLAIMS`)
- `DATABASE_NAME`: Used by the teardown task (should match `DEMO_DATABASE_NAME`)
- `INTERNAL_NAMED_STAGE`: Fully qualified stage name with `@` prefix (e.g., `@INS_CO.LOSS_CLAIMS.LOSS_EVIDENCE`)
- `FILE_UPLOAD_DIR` and `STREAMLIT_APP_DIR`: These are relative paths from the `tasks/snow-cli` directory

**Note:** You can use a custom environment file by naming it differently (e.g., `custom.env`) and specifying it when running tasks:

```bash
DOTENV_FILENAME=custom.env task demo-up
```

### 3. Configure Snowflake CLI Connection

Ensure your Snowflake CLI is configured with a valid connection profile for your service user that matches `CLI_CONNECTION_NAME`:

```bash
snow connection test --connection your_service_user_connection_name
```

## Demo Deployment

**Prerequisites:** Admin setup (Steps 1-3 above) must be completed first.

After the admin has completed the one-time initialization (`demo-init-1` and `demo-init-2`), both admin and engineer personas can run the demo-up task to deploy the demo application.

### Deploy the Demo

Run the following command to deploy the entire demo (Persona: Admin & Engineer):

```bash
task demo-up
```

This command executes the following steps in sequence:

**Admin Responsibilities (Batch-2):**

1. **Validate Prerequisites** - Verify that Snowflake CLI is properly installed and configured

2. **Create Tables and Stages (Batch-2)** - Execute SQL files in `sql/batch-2/`:
   - Create all required tables (CLAIMS, CLAIM_LINES, FINANCIAL_TRANSACTIONS, AUTHORIZATION, INVOICES, etc.)
   - Create chunk tables for notes and guidelines
   - Create the `LOSS_EVIDENCE` internal stage for file storage

3. **Upload Sample Files to Stage** - Upload all files from the `upload/` directory to the `LOSS_EVIDENCE` stage:
   - Claim evidence images (JPEG files)
   - Claim notes (PDF)
   - Guidelines (DOCX)
   - Invoices (PNG)
   - Call recordings (WAV)

**Engineer Responsibilities (Batch-3 + Applications):**

1. **Create Cortex Services and Data (Batch-3)** - Execute SQL files in `sql/batch-3/`:
   - Refresh and populate the stage
   - Insert sample data into tables (DML operations)
   - Create Cortex Search services for claim notes and guidelines
   - Create custom functions for document processing, image analysis, transcription, etc.
   - Create semantic views for Cortex Analyst
   - Create MCP server configuration

2. **Create the Agent** - Deploy the Claims Audit Agent with integrated tools:
   - Cortex Analyst for SQL-based queries
   - Cortex Search for guidelines and notes
   - Custom tools for document parsing, image analysis, audio transcription, document classification, and PII redaction

3. **Deploy Streamlit App** - Deploy the web-based claims audit interface to Snowflake

### Deployment Summary by Persona

| Step | Batch   | Persona  | Task                    | Frequency                      |
|------|---------|----------|-------------------------|--------------------------------|
| 1    | Batch-0 | Admin    | Infrastructure setup    | One-time (elevated privileges) |
| 2    | Batch-1 | Admin    | Grants configuration    | One-time (elevated privileges) |
| 3    | N/A     | Admin    | User creation           | One-time (manual)              |
| 4    | Batch-2 | Admin    | Tables & Stages         | Per deployment                 |
| 5    | Batch-3 | Engineer | Data & Cortex services  | Per deployment                 |
| 6    | N/A     | Engineer | Agent & Streamlit       | Per deployment                 |

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

You can run specific parts of the deployment individually based on your persona:

#### Admin Tasks (Infrastructure & Security)

##### Initialize Infrastructure (Batch 0 - Warehouses, Roles, Database)

```bash
DOTENV_FILENAME=demo_init.env task demo-init-1
```

Note: This requires SYSADMIN and USERADMIN roles

##### Configure Grants (Batch 1 - Permissions)

```bash
DOTENV_FILENAME=demo_init.env task demo-init-2
```

##### Create Tables and Stages (Batch 2)

```bash
task snow-cli:sort-and-process-sql-folder \
  SQL_SORT_PROCESS_DIR=sql/batch-2 \
  CLI_CONNECTION_NAME=$CLI_CONNECTION_NAME
```

##### Upload Files to Stage

```bash
task snow-cli:upload-files-to-internal-named-stage \
  FILE_UPLOAD_DIR=$FILE_UPLOAD_DIR \
  CLI_CONNECTION_NAME=$CLI_CONNECTION_NAME \
  INTERNAL_NAMED_STAGE=$INTERNAL_NAMED_STAGE
```

#### Engineer Tasks (Data & AI Services)

##### Process Data and Create Cortex Services (Batch 3)

```bash
task snow-cli:sort-and-process-sql-folder \
  SQL_SORT_PROCESS_DIR=sql/batch-3 \
  CLI_CONNECTION_NAME=$CLI_CONNECTION_NAME
```

##### Create Agent Only

```bash
task snow-cli:create-agent
```

##### Deploy Streamlit App Only

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

```text
.
├── Taskfile.yml                          # Main task definitions
├── .env/                                 # Environment configurations
│   ├── demo.env                         # Demo environment variables
│   └── demo_init.env                    # Initialization environment variables
├── tasks/
│   ├── snow-cli/
│   │   ├── snowcli-tasks.yml           # Snowflake CLI task definitions
│   │   ├── sql/
│   │   │   ├── batch-0/                # Infrastructure: warehouses, roles, db/schema (Admin)
│   │   │   ├── batch-1/                # Security: grants and permissions (Admin)
│   │   │   ├── batch-2/                # Schema: tables and stages (Admin)
│   │   │   └── batch-3/                # Data & AI: DML, Cortex services, functions (Engineer)
│   │   ├── agent/
│   │   │   └── sql/
│   │   │       └── create_agents.sql   # Agent configuration (Engineer)
│   │   ├── streamlit/
│   │   │   ├── streamlit_app.py        # Streamlit application (Engineer)
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
