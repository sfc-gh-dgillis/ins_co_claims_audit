-- -----------------------------------------------------------------------
-- Runs BEFORE `snow dcm plan`.
--
-- DCM cannot DEFINE compute pools, but access.sql grants USAGE on this one,
-- so it has to exist when the plan is computed. The Streamlit app runs on it
-- (container runtime).
-- -----------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;

CREATE COMPUTE POOL IF NOT EXISTS INS_CO_STREAMLIT_POOL
    MIN_NODES = 1
    MAX_NODES = 1
    INSTANCE_FAMILY = CPU_X64_XS
    AUTO_RESUME = TRUE
    AUTO_SUSPEND_SECS = 600
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Container runtime for the INS_CO claims audit Streamlit app';
