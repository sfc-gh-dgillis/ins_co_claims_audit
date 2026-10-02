-- -----------------------------------------------------------------------
-- Streamlit post-deploy
--
-- Runs AFTER `snow streamlit deploy`, because the STREAMLIT object has to
-- exist first. Run as the app owner role.
-- -----------------------------------------------------------------------
USE ROLE ins_co_claims_rw;

-- Install pyproject.toml dependencies from Snowflake's built-in PyPI mirror.
-- Attaching a repository restarts the app.
ALTER STREAMLIT ins_co.loss_claims.ins_co_claims_audit_streamlit
    SET ARTIFACT_REPOSITORIES = (snowflake.snowpark.pypi_shared_repository);

-- Confirm the runtime, compute pool, owner, and attached artifact repository.
SHOW STREAMLITS LIKE 'ins_co_claims_audit_streamlit' IN SCHEMA ins_co.loss_claims;
