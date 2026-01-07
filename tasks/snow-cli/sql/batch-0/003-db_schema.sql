USE ROLE sysadmin;

CREATE DATABASE IF NOT EXISTS ins_co
    COMMENT = 'Insurance Company Database';

CREATE SCHEMA IF NOT EXISTS ins_co.loss_claims
    COMMENT = 'Schema for loss claims data';
