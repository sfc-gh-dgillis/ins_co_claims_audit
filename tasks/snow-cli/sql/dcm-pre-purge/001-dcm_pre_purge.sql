-- -----------------------------------------------------------------------
-- Runs BEFORE `snow dcm purge`.
--
-- Removes what demo-up registered outside the INS_CO database. The agent,
-- Streamlit app, MCP server and search services live in INS_CO and go when
-- purge drops the database.
-- -----------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;

-- Unregister the agent from Snowflake Intelligence (ignored if it was never added).
EXECUTE IMMEDIATE
$$
BEGIN
  ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT DROP AGENT INS_CO.LOSS_CLAIMS.CLAIMS_AUDIT_AGENT;
EXCEPTION
  WHEN OTHER THEN
    NULL;
END;
$$;
