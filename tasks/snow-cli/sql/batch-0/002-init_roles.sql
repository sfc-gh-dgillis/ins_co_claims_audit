USE ROLE useradmin;

-- create access roles
CREATE ROLE IF NOT EXISTS ins_co_claims_rw
    COMMENT = 'Access role for the ins_co database with Read and Write permissions to all objects.';

CREATE ROLE IF NOT EXISTS ins_co_claims_ro
    COMMENT = 'Access role for the ins_co database with Read Only permissions to all objects.';

-- create functional roles
CREATE ROLE IF NOT EXISTS ins_co_claims_data_engineer
    COMMENT = 'Functional role for ins_co - business function alignment is generally for Data Engineers';

CREATE ROLE IF NOT EXISTS ins_co_claims_analyst
    COMMENT = 'Functional role for ins_co - business function alignment is generally for Data Analysts';

CREATE ROLE IF NOT EXISTS ins_co_ga_dev
    COMMENT = 'Functional role to be used by Github Actions Service User (development environment)';
