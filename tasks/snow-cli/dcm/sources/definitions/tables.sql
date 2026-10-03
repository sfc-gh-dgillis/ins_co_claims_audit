-- -----------------------------------------------------------------------
-- Tables
-- -----------------------------------------------------------------------
DEFINE TABLE INS_CO.LOSS_CLAIMS.CLAIMS
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

DEFINE TABLE INS_CO.LOSS_CLAIMS.AUTHORIZATION
(
    performer_id VARCHAR(50) PRIMARY KEY,
    from_amt     DECIMAL(18, 2),
    to_amt       DECIMAL(18, 2),
    currency     VARCHAR(10)
);

DEFINE TABLE INS_CO.LOSS_CLAIMS.CLAIM_LINES
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

DEFINE TABLE INS_CO.LOSS_CLAIMS.FINANCIAL_TRANSACTIONS
(
    fxid           VARCHAR,
    line_no        INT,
    financial_type VARCHAR,
    currency       VARCHAR,
    fin_tx_amt     DECIMAL(18, 2),
    fin_tx_post_dt DATE
);

DEFINE TABLE INS_CO.LOSS_CLAIMS.INVOICES
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

DEFINE TABLE INS_CO.LOSS_CLAIMS.PARSED_CLAIM_NOTES
(
    filename          VARCHAR(255),
    extracted_content VARCHAR(16777216),
    parse_date        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    claim_no          VARCHAR
);

DEFINE TABLE INS_CO.LOSS_CLAIMS.PARSED_GUIDELINES
(
    filename          VARCHAR(255),
    extracted_content VARCHAR(16777216),
    parse_date        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP
);

DEFINE TABLE INS_CO.LOSS_CLAIMS.PARSED_INVOICES
(
    filename          VARCHAR(255),
    extracted_content VARCHAR(16777216),
    parse_date        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    claim_no          VARCHAR
);

DEFINE TABLE INS_CO.LOSS_CLAIMS.NOTES_CHUNK_TABLE
(
    filename VARCHAR,
    claim_no VARCHAR,
    file_url VARCHAR,
    chunk    VARCHAR,
    language VARCHAR
)
-- Source of a Cortex Search service. The service needs change tracking, and
-- only the table owner (the DCM project owner) can turn it on.
CHANGE_TRACKING = TRUE;

DEFINE TABLE INS_CO.LOSS_CLAIMS.GUIDELINES_CHUNK_TABLE
(
    filename VARCHAR,
    file_url VARCHAR,
    chunk    VARCHAR,
    language VARCHAR
)
-- Source of a Cortex Search service. The service needs change tracking, and
-- only the table owner (the DCM project owner) can turn it on.
CHANGE_TRACKING = TRUE;
