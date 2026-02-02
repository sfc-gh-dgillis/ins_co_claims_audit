-- Script to add agent to Snowflake Intelligence (idempotent)

-- Add CLAIMS_AUDIT_AGENT to Snowflake Intelligence (idempotent - ignores if already added)
EXECUTE IMMEDIATE
$$
BEGIN
  ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT ADD AGENT INS_CO.LOSS_CLAIMS.CLAIMS_AUDIT_AGENT;
EXCEPTION
  WHEN OTHER THEN
    -- Agent already exists in SI, ignore the error
    NULL;
END;
$$;
