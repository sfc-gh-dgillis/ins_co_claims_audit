USE DATABASE ins_co;
USE SCHEMA ins_co.loss_claims;

CREATE TABLE IF NOT EXISTS claims
(
    claim_no             VARCHAR,
    line_of_business     VARCHAR,
    claim_status         VARCHAR,
    cause_of_loss        VARCHAR,
    created_date         DATE,
    loss_date            DATE,
    reported_date        DATE,
    claimant_id          VARCHAR,
    performer            VARCHAR,
    policy_no            VARCHAR,
    fnol_completion_date DATE,
    loss_description     VARCHAR,
    loss_state           VARCHAR,
    loss_zip_code        VARCHAR
);

CREATE TABLE IF NOT EXISTS authorization
(
    performer_id VARCHAR(50) PRIMARY KEY,
    from_amt     DECIMAL(18, 2),
    to_amt       DECIMAL(18, 2),
    currency     VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS claim_lines
(
    claim_no         VARCHAR,
    line_no          INT,
    loss_description VARCHAR,
    claim_status     VARCHAR,
    created_date     DATE,
    reported_date    DATE,
    claimant_id      VARCHAR,
    performer_id     VARCHAR
);

CREATE TABLE IF NOT EXISTS financial_transactions
(
    fxid           VARCHAR,
    line_no        INT,
    financial_type VARCHAR,
    currency       VARCHAR,
    fin_tx_amt     DECIMAL(18, 2),
    fin_tx_post_dt DATE
);

CREATE TABLE IF NOT EXISTS invoices
(
    inv_id         VARCHAR,
    inv_line_nbr   VARCHAR,
    line_no        VARCHAR,
    description    VARCHAR,
    currency       VARCHAR(10),
    invoice_amount DECIMAL(18, 2),
    invoice_date   DATE,
    vendor         VARCHAR
);

CREATE TABLE IF NOT EXISTS
    parsed_claim_notes
(
    filename          VARCHAR(255),
    extracted_content VARCHAR(16777216),
    parse_date        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    claim_no          VARCHAR
);

CREATE TABLE IF NOT EXISTS parsed_guidelines
(
    filename          VARCHAR(255),
    extracted_content VARCHAR(16777216),
    parse_date        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS parsed_invoices
(
    filename          VARCHAR(255),
    extracted_content VARCHAR(16777216),
    parse_date        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    claim_no          VARCHAR
);

CREATE OR REPLACE TABLE notes_chunk_table_def
(
    filename     VARCHAR,
    claim_no     VARCHAR,
    file_url     VARCHAR,
    chunk        VARCHAR,
    language_tag VARCHAR COMMENT 'The BCP 47 Language Tag which identifies a language both spoken and written.'
);

CREATE OR REPLACE TABLE guidelines_chunk_table_def
(
    filename VARCHAR COMMENT 'Source file name for the guideline',
    file_url VARCHAR COMMENT 'Scoped URL to the uploaded guideline file in the loss_evidence stage',
    chunk    VARCHAR COMMENT 'Text chunk extracted from the guideline',
    language VARCHAR COMMENT 'Language of the guideline chunk'
);

CREATE TABLE IF NOT EXISTS loss_claims.notes_chunk_table
(
    filename VARCHAR,
    claim_no VARCHAR,
    file_url VARCHAR,
    chunk    VARCHAR,
    language VARCHAR
);

CREATE TABLE IF NOT EXISTS loss_claims.guidelines_chunk_table
(
    filename VARCHAR,
    file_url VARCHAR,
    chunk    VARCHAR,
    language VARCHAR
);
