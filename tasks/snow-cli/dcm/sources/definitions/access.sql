-- -----------------------------------------------------------------------
-- Roles
--
-- Adopted from the former sql/batch-0/002-init_roles.sql (same names and
-- comments), so existing user grants keep working.
-- -----------------------------------------------------------------------
-- access roles
DEFINE ROLE INS_CO_CLAIMS_RW
    COMMENT = 'Access role for the ins_co database with Read and Write permissions to all objects.';

DEFINE ROLE INS_CO_CLAIMS_RO
    COMMENT = 'Access role for the ins_co database with Read Only permissions to all objects.';

-- functional roles
DEFINE ROLE INS_CO_CLAIMS_DATA_ENGINEER
    COMMENT = 'Functional role for ins_co - business function alignment is generally for Data Engineers';

DEFINE ROLE INS_CO_CLAIMS_ANALYST
    COMMENT = 'Functional role for ins_co - business function alignment is generally for Data Analysts';

DEFINE ROLE INS_CO_GA_DEV
    COMMENT = 'Functional role to be used by Github Actions Service User (development environment)';

-- -----------------------------------------------------------------------
-- Role to role / role to user grants
-- -----------------------------------------------------------------------
-- access roles to functional roles
GRANT ROLE INS_CO_CLAIMS_RW TO ROLE INS_CO_CLAIMS_DATA_ENGINEER;
GRANT ROLE INS_CO_CLAIMS_RW TO ROLE INS_CO_GA_DEV;
GRANT ROLE INS_CO_CLAIMS_RO TO ROLE INS_CO_CLAIMS_ANALYST;

-- functional roles to SYSADMIN
GRANT ROLE INS_CO_CLAIMS_DATA_ENGINEER TO ROLE SYSADMIN;
GRANT ROLE INS_CO_CLAIMS_ANALYST TO ROLE SYSADMIN;
GRANT ROLE INS_CO_GA_DEV TO ROLE SYSADMIN;

-- ins_co_ga_dev only to the Github Actions development user (and mock user)
GRANT ROLE INS_CO_GA_DEV TO USER GA_DEV;
GRANT ROLE INS_CO_GA_DEV TO USER GA_MOCK;

-- -----------------------------------------------------------------------
-- Warehouse, database, schema
-- -----------------------------------------------------------------------
GRANT USAGE ON WAREHOUSE DEMO_S_WH TO ROLE INS_CO_CLAIMS_RW;

GRANT USAGE ON DATABASE INS_CO TO ROLE INS_CO_CLAIMS_RO;
GRANT USAGE ON DATABASE INS_CO TO ROLE INS_CO_CLAIMS_RW;

GRANT USAGE ON SCHEMA INS_CO.LOSS_CLAIMS TO ROLE INS_CO_CLAIMS_RO;
GRANT USAGE ON SCHEMA INS_CO.LOSS_CLAIMS TO ROLE INS_CO_CLAIMS_RW;

-- Objects the RW role still creates imperatively (search services, MCP server,
-- agent, Streamlit app and its deploy stage, ad-hoc tables/functions).
GRANT CREATE FILE FORMAT, CREATE TABLE, CREATE STAGE, CREATE FUNCTION, CREATE PROCEDURE,
      CREATE CORTEX SEARCH SERVICE, CREATE SEMANTIC VIEW, CREATE MCP SERVER, CREATE AGENT,
      CREATE STREAMLIT
    ON SCHEMA INS_CO.LOSS_CLAIMS TO ROLE INS_CO_CLAIMS_RW;

-- -----------------------------------------------------------------------
-- Object grants
--
-- The old scripts used FUTURE grants; inherited grants cover current and
-- future objects and are what DCM recommends.
-- -----------------------------------------------------------------------
GRANT INHERITED SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA INS_CO.LOSS_CLAIMS
    TO ROLE INS_CO_CLAIMS_RW;
GRANT INHERITED SELECT ON ALL VIEWS IN SCHEMA INS_CO.LOSS_CLAIMS TO ROLE INS_CO_CLAIMS_RW;
GRANT INHERITED SELECT ON ALL TABLES IN SCHEMA INS_CO.LOSS_CLAIMS TO ROLE INS_CO_CLAIMS_RO;

-- These objects used to be created (and so owned) by the RW role; DCM now owns
-- them, so RW needs explicit access.
GRANT READ, WRITE ON STAGE INS_CO.LOSS_CLAIMS.LOSS_EVIDENCE TO ROLE INS_CO_CLAIMS_RW;

GRANT SELECT ON SEMANTIC VIEW INS_CO.LOSS_CLAIMS.CA_INS_CO TO ROLE INS_CO_CLAIMS_RW;
GRANT SELECT ON SEMANTIC VIEW INS_CO.LOSS_CLAIMS.CA_INS_CO TO ROLE INS_CO_CLAIMS_RO;

GRANT USAGE ON FUNCTION INS_CO.LOSS_CLAIMS.CLASSIFY_DOCUMENT(VARCHAR, VARCHAR) TO ROLE INS_CO_CLAIMS_RW;
GRANT USAGE ON FUNCTION INS_CO.LOSS_CLAIMS.PARSE_DOCUMENT_FROM_STAGE(VARCHAR, VARCHAR) TO ROLE INS_CO_CLAIMS_RW;
GRANT USAGE ON FUNCTION INS_CO.LOSS_CLAIMS.GET_IMAGE_SUMMARY(VARCHAR, VARCHAR) TO ROLE INS_CO_CLAIMS_RW;
GRANT USAGE ON PROCEDURE INS_CO.LOSS_CLAIMS.TRANSCRIBE_AUDIO_SIMPLE(VARCHAR, VARCHAR) TO ROLE INS_CO_CLAIMS_RW;

-- -----------------------------------------------------------------------
-- Cortex, Snowflake Intelligence, Streamlit container runtime
-- -----------------------------------------------------------------------
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE INS_CO_CLAIMS_RW;

-- USAGE: view the agents added to the Snowflake Intelligence object.
-- MODIFY: add or remove agents and change configuration values.
GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE INS_CO_CLAIMS_RW;
GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE INS_CO_CLAIMS_RO;
GRANT MODIFY ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE INS_CO_CLAIMS_RW;

-- USAGE on the Streamlit compute pool is in 001-dcm_post_deployment_grants.sql:
-- DCM accepts it at analyze but leaves it out of the plan.

-- Lets the app install pyproject.toml dependencies from Snowflake's built-in
-- PyPI mirror with no external access integration.
GRANT DATABASE ROLE SNOWFLAKE.PYPI_REPOSITORY_USER TO ROLE INS_CO_CLAIMS_RW;
