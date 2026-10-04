-- -----------------------------------------------------------------------
-- Runs AFTER `snow dcm purge`.
--
-- DCM cannot DEFINE compute pools, so the Streamlit pool created in
-- 001-dcm_pre_deploy.sql is dropped here. Purge has already dropped the
-- Streamlit app that ran on it.
-- -----------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;

EXECUTE IMMEDIATE
$$
BEGIN
  ALTER COMPUTE POOL INS_CO_STREAMLIT_POOL STOP ALL;
EXCEPTION
  WHEN OTHER THEN
    NULL;
END;
$$;

DROP COMPUTE POOL IF EXISTS INS_CO_STREAMLIT_POOL;
