-- -----------------------------------------------------------------------
-- Warehouse, database, schema, stage
-- -----------------------------------------------------------------------
DEFINE WAREHOUSE DEMO_S_WH
    WITH WAREHOUSE_SIZE = SMALL
    INITIALLY_SUSPENDED = TRUE;

DEFINE DATABASE INS_CO
    COMMENT = 'Insurance Company Database';

DEFINE SCHEMA INS_CO.LOSS_CLAIMS
    COMMENT = 'Schema for loss claims data';

-- Claim evidence (notes, guidelines, invoices, images, audio). Files are
-- uploaded outside DCM by the upload-files-to-internal-named-stage task.
DEFINE STAGE INS_CO.LOSS_CLAIMS.LOSS_EVIDENCE
    DIRECTORY = ( ENABLE = TRUE )
    ENCRYPTION = ( TYPE = 'SNOWFLAKE_SSE' );
