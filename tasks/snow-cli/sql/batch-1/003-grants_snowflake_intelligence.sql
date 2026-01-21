USE ROLE accountadmin;

-- -----------------------------------------------------------------------
-- Account-Level Snowflake Intelligence Grants
-- -----------------------------------------------------------------------
-- Create a default Snowflake Intelligence object at the account level
-- This would typically be done once per account by the role that manages Cortex tools.
CREATE SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;

-- Grant CREATE Snowflake Intelligence at the account level
-- This would typically be done once per account by the role that manages Cortex tools.
-- I am including it here for completeness.
-- GRANT CREATE SNOWFLAKE INTELLIGENCE ON ACCOUNT TO ROLE ins_co_claims_rw;

-- Grant USAGE on the default Snowflake Intelligence object to the functional roles
-- USAGE: Object-level privilege that allows users to view the list of agents added to the Snowflake Intelligence object
-- and see configuration values.
GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE ins_co_claims_rw;
GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE ins_co_claims_ro;

-- `ALTER` (MODIFY) is an object-level privilege that allows users to add or remove agents from the Snowflake Intelligence object
-- and change configuration values. Account administrators have this privilege by default.

-- To grant this privilege, run the following command:
GRANT MODIFY ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE ins_co_claims_rw;

