-- -----------------------------------------------------------------------
-- Streamlit Grants
-- -----------------------------------------------------------------------
GRANT CREATE STREAMLIT ON SCHEMA ins_co.loss_claims TO ROLE ins_co_claims_rw;

-- The app runs on the container runtime, so the owning role needs USAGE on the
-- compute pool. Without it, deploy fails with
-- "COMPUTE_POOL '...' does not exist or not authorized".
GRANT USAGE ON COMPUTE POOL SYSTEM_COMPUTE_POOL_CPU TO ROLE ins_co_claims_rw;

-- Lets the app install pyproject.toml dependencies from Snowflake's built-in
-- PyPI mirror (snowflake.snowpark.pypi_shared_repository) with no external
-- access integration.
GRANT DATABASE ROLE SNOWFLAKE.PYPI_REPOSITORY_USER TO ROLE ins_co_claims_rw;
