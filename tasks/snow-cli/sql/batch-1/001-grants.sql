USE ROLE securityadmin;
-- -----------------------------------------------------------------------
-- Warehouse Usage Grants
-- -----------------------------------------------------------------------
GRANT USAGE on WAREHOUSE demo_s_wh TO ROLE ins_co_claims_rw;

-- -----------------------------------------------------------------------
-- Database Usage Grants
-- -----------------------------------------------------------------------
GRANT USAGE ON DATABASE ins_co TO ROLE ins_co_claims_ro;
GRANT USAGE ON DATABASE ins_co TO ROLE ins_co_claims_rw;

-- -----------------------------------------------------------------------
-- Schema Usage Grants
-- -----------------------------------------------------------------------
GRANT USAGE ON SCHEMA ins_co.loss_claims TO ROLE ins_co_claims_ro;
GRANT USAGE ON SCHEMA ins_co.loss_claims TO ROLE ins_co_claims_rw;

GRANT USAGE ON FUTURE STAGES IN SCHEMA ins_co.loss_claims TO ROLE ins_co_claims_rw;

-- -----------------------------------------------------------------------
-- LOSS_CLAIMS Schema-Level Read/Write Grants
-- -----------------------------------------------------------------------
GRANT CREATE FILE FORMAT ON SCHEMA ins_co.loss_claims TO ROLE ins_co_claims_rw;
GRANT CREATE TABLE ON SCHEMA ins_co.loss_claims TO ROLE ins_co_claims_rw;
GRANT CREATE STAGE ON SCHEMA ins_co.loss_claims TO ROLE ins_co_claims_rw;
GRANT SELECT, INSERT, UPDATE, DELETE ON FUTURE TABLES IN SCHEMA ins_co.loss_claims TO ROLE ins_co_claims_rw;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA ins_co.loss_claims TO ROLE ins_co_claims_rw;

-- -----------------------------------------------------------------------
-- LOSS_CLAIMS Schema-Level Read Only Grants
-- -----------------------------------------------------------------------
GRANT SELECT ON FUTURE TABLES IN SCHEMA ins_co.loss_claims TO ROLE ins_co_claims_ro;

-- -----------------------------------------------------------------------
-- LOSS_CLAIMS Schema-Level Procedure and Function Grants
-- -----------------------------------------------------------------------
-- Grant required privileges to create functions
GRANT CREATE FUNCTION ON SCHEMA ins_co.loss_claims TO ROLE ins_co_claims_rw;
GRANT CREATE PROCEDURE ON SCHEMA ins_co.loss_claims TO ROLE ins_co_claims_rw;

-- If function uses an internal stage
-- GRANT READ ON STAGE my_database.my_schema.my_stage TO ROLE ins_co_claims_rw;

-- -----------------------------------------------------------------------
-- LOSS_CLAIMS Schema-Level Cortex Grants
-- -----------------------------------------------------------------------
-- Grant CREATE schema-level privileges
GRANT CREATE CORTEX SEARCH SERVICE ON SCHEMA ins_co.loss_claims TO ROLE ins_co_claims_rw;
GRANT CREATE SEMANTIC VIEW ON SCHEMA ins_co.loss_claims TO ROLE ins_co_claims_rw;
GRANT CREATE MCP SERVER ON SCHEMA ins_co.loss_claims TO ROLE ins_co_claims_rw;
GRANT CREATE AGENT ON SCHEMA ins_co.loss_claims TO ROLE ins_co_claims_rw;

-- Grant Cortex database role
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE ins_co_claims_rw;

-- -- For Cortex Search Service tool
-- GRANT USAGE ON CORTEX SEARCH SERVICE my_database.my_schema.my_search_service TO ROLE my_role;
--
-- -- For Cortex Analyst tool
-- GRANT SELECT ON SEMANTIC VIEW my_database.my_schema.my_semantic_view TO ROLE my_role;
--
-- -- For Cortex Agent tool
-- GRANT USAGE ON AGENT my_database.my_schema.my_agent TO ROLE my_role;
--
-- -- For Custom tool (UDF/stored procedure)
-- GRANT USAGE ON FUNCTION my_database.my_schema.my_udf(NUMBER) TO ROLE my_role;

-- -----------------------------------------------------------------------
-- ROLE to ROLE Grants
-- -----------------------------------------------------------------------
-- grant access roles to functional roles
GRANT ROLE ins_co_claims_rw TO ROLE ins_co_claims_data_engineer;
GRANT ROLE ins_co_claims_rw TO ROLE ins_co_ga_dev;
GRANT ROLE ins_co_claims_ro TO ROLE ins_co_claims_analyst;

-- grant functional roles to SYSADMIN
GRANT ROLE ins_co_claims_data_engineer TO ROLE sysadmin;
GRANT ROLE ins_co_claims_analyst TO ROLE sysadmin;
GRANT ROLE ins_co_ga_dev TO ROLE sysadmin;

-- -----------------------------------------------------------------------
-- ROLE to USER Grants
-- -----------------------------------------------------------------------
-- grant functional roles to specific users
-- grant ins_co_ga_dev only to the Github Actions Development User (and mock user)
GRANT ROLE ins_co_ga_dev to USER ga_dev;
GRANT ROLE ins_co_ga_dev to USER ga_mock;
