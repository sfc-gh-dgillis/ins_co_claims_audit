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

-- For Cortex Search Service tool
-- GRANT USAGE ON CORTEX SEARCH SERVICE my_database.my_schema.my_search_service TO ROLE my_role;
--
-- For Cortex Analyst tool
-- GRANT SELECT ON SEMANTIC VIEW my_database.my_schema.my_semantic_view TO ROLE my_role;
--
-- For Cortex Agent tool
-- GRANT USAGE ON AGENT my_database.my_schema.my_agent TO ROLE my_role;
--
-- For Custom tool (UDF/stored procedure)
-- GRANT USAGE ON FUNCTION my_database.my_schema.my_udf(NUMBER) TO ROLE my_role;
