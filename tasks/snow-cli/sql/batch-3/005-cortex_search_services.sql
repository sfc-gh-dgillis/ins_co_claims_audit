USE DATABASE ins_co;
USE SCHEMA ins_co.loss_claims;

CREATE OR REPLACE CORTEX SEARCH SERVICE ins_co_claim_notes
  ON chunk
  -- NOTE_CONTENT
  -- ATTRIBUTES claim_no, note_date, note_id
  WAREHOUSE = demo_s_wh
  TARGET_LAG = '1 hour'
  EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
AS (
  SELECT
      chunk -- note_content, claim_no, note_date, note_id
  FROM NOTES_CHUNK_TABLE
);

CREATE OR REPLACE CORTEX SEARCH SERVICE ins_co_guidelines
  ON chunk
  -- ATTRIBUTES claim_no, note_date, note_id
  WAREHOUSE = demo_s_wh
  TARGET_LAG = '1 hour'
  EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
AS (
  SELECT
      chunk
  FROM GUIDELINES_CHUNK_TABLE
);
