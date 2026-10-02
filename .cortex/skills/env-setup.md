# Environment Setup Skill

This skill needs WORK.

## Description

Guide users through setting up environment files for the Insurance Claims Audit demo and optionally running the demo tasks. Supports configuring demo_admin.env (for initialization tasks requiring admin privileges) and demo.env (for running the demo).

## Triggers

- setup env, setup environment, configure env, configure environment
- demo setup, initialize demo, init demo
- create env file, env file setup
- demo_admin.env, demo.env
- run demo, start demo, deploy demo
- run demo-init, run demo-up

## Instructions

### Step 1: Determine Which Environment Files Are Needed

Ask the user which environment file(s) they need to set up:

**demo_admin.env** - Required for `task demo-init`

- Creates warehouses, roles, database, schema, and grants
- Requires user with SYSADMIN, USERADMIN, and SECURITYADMIN roles
- Only needs CLI_CONNECTION_NAME and DEMO_DATABASE_NAME

**demo.env** - Required for `task demo-up`

- Runs the actual demo (creates tables, uploads files, deploys agent and Streamlit app)
- Requires more configuration variables
- Can be run by users with the demo-specific role after demo-init completes

### Step 2: Gather Configuration Values

#### For demo_admin.env:

1. **CLI_CONNECTION_NAME** - The Snowflake CLI connection name configured for keypair authentication
   - User can run `snow connection list` to see available connections
2. **DEMO_DATABASE_NAME** - The database name to create (default: `ins_co`)

#### For demo.env:

1. **CLI_CONNECTION_NAME** - The Snowflake CLI connection name
2. **DEMO_DATABASE_NAME** - The database name (default: `ins_co`)
3. **DEMO_SCHEMA_NAME** - Fully qualified schema name (default: `ins_co.loss_claims`)
4. **INTERNAL_NAMED_STAGE** - The internal stage for file uploads (default: `@ins_co.loss_claims.loss_evidence`)
5. **FILE_UPLOAD_DIR** - Path to upload directory (default: `../../upload`)
6. **STREAMLIT_APP_DIR** - Path to Streamlit app (default: `streamlit`)

### Step 3: Create the Environment Files

**Template locations:**

- `.env/demo_admin.env_template` → `.env/demo_admin.env`
- `.env/demo.env_template` → `.env/demo.env`

### Step 4: Validate Setup

After creating the files:

1. Check that the Snowflake connection is valid: `snow connection test -c <connection_name>`
2. Verify the user has required roles for the chosen task

### Step 5: Run the Demo Tasks

After environment files are created, ask if the user wants to run the tasks:

#### Running demo-init (requires demo_admin.env)

```bash
DOTENV_FILENAME=demo_admin.env task demo-init
```

This task:

- Creates warehouses (batch-0/001-create_warehouses.sql)
- Initializes roles (batch-0/002-init_roles.sql)
- Creates database and schema (batch-0/003-db_schema.sql)
- Sets up grants (batch-0/004-007 grant files)

**Prerequisites:** User must have SYSADMIN, USERADMIN, and SECURITYADMIN roles.

#### Running demo-up (requires demo.env)

```bash
task demo-up
```

This task:

- Runs SQL scripts in batch-1 (creates tables, etc.)
- Uploads files to internal stage
- Runs SQL scripts in batch-2 (creates Cortex Search services, semantic views, etc.)
- Creates the Cortex Agent
- Deploys the Streamlit app

**Prerequisites:** demo-init must have been run first (or infrastructure must already exist).

### Step 6: Verify Deployment

After running demo-up, verify:

1. Agent exists: `DESCRIBE AGENT <database>.<schema>.<agent_name>`
2. Streamlit app is deployed: Check Snowsight or run `snow streamlit list`

### Example Workflow

```bash
# 1. First-time setup (admin): Initialize the demo infrastructure
DOTENV_FILENAME=demo_admin.env task demo-init

# 2. Run the demo (can be different user with demo role)
task demo-up

# 3. Teardown when done
task demo-down
```

### Questions to Ask User

Use the ask_user_question tool with these questions:

**Question 1: Which env file(s)?**

- Options: "demo_admin.env only", "demo.env only", "Both"

**Question 2: Connection name**

- Type: text
- Default: First available connection from `snow connection list`

**Question 3: Database name**

- Type: text
- Default: ins_co

**For demo.env additionally ask:**

**Question 4: Schema name**

- Type: text
- Default: loss_claims

**Question 5: Stage name**

- Type: text
- Default: files

**After env file creation, ask:**

**Question 6: Run tasks now?**

- Options based on which env files were created:
  - If demo_admin.env: "Run demo-init now", "Skip for now"
  - If demo.env: "Run demo-up now", "Skip for now"
  - If both: "Run demo-init only", "Run demo-init then demo-up", "Skip for now"

### Red Flags

- User doesn't have a Snowflake CLI connection configured
- User lacks required admin roles for demo-init
- Database name conflicts with existing database
- Stage path doesn't follow the pattern @database.schema.stage
- demo-up fails because demo-init was not run first
- Task runner (go-task) is not installed

### Running Tasks

When executing tasks, use the Bash tool from the project root directory:

```bash
# For demo-init
cd /path/to/ins_co_claims_audit && DOTENV_FILENAME=demo_admin.env task demo-init

# For demo-up  
cd /path/to/ins_co_claims_audit && task demo-up

# For demo-down (cleanup)
cd /path/to/ins_co_claims_audit && task demo-down
```

**Important:** These tasks can take several minutes to complete. Monitor output for errors.
