-- -----------------------------------------------------------------------
-- Runs AFTER `snow dcm deploy`.
--
-- Grants DCM does not apply. `GRANT USAGE ON COMPUTE POOL` passes analyze
-- but is silently left out of the plan, so it is applied here instead.
-- -----------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;

-- The Streamlit app owner role runs the app on this pool (created in pre_deploy.sql).
GRANT USAGE ON COMPUTE POOL INS_CO_STREAMLIT_POOL TO ROLE INS_CO_CLAIMS_RW;
