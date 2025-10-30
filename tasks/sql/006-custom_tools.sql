CREATE OR REPLACE FUNCTION INS_CO.LOSS_CLAIMS.CLASSIFY_DOCUMENT("FILE_NAME" VARCHAR, "STAGE_NAME" VARCHAR DEFAULT '@INS_CO_DB.ANALYTICS.DOC_STAGE')
RETURNS OBJECT
LANGUAGE SQL
AS '
    WITH classification_result AS (
        SELECT AI_EXTRACT(
            TO_FILE(stage_name, file_name),
            [
                ''What type of document is this? Classify as one of: Invoice, Evidence Image, Medical Bill, Insurance Claim, Policy Document, Correspondence, Legal Document, Financial Statement, Other''
            ]
        ) as classification_data
    )
    SELECT 
        OBJECT_CONSTRUCT(
            ''success'', TRUE,
            ''file_name'', file_name,
            ''classification_type'', classification_data[0]:answer::STRING,
            ''description'', classification_data[1]:answer::STRING,
            ''business_context'', classification_data[2]:answer::STRING,
            ''document_purpose'', classification_data[3]:answer::STRING,
            ''confidence_score'', (
                classification_data[0]:score::NUMBER + 
                classification_data[1]:score::NUMBER + 
                classification_data[2]:score::NUMBER + 
                classification_data[3]:score::NUMBER
            ) / 4,
            ''classification_timestamp'', CURRENT_TIMESTAMP(),
            ''full_classification_data'', classification_data
        ) as result
    FROM classification_result
';

CREATE OR REPLACE FUNCTION INS_CO.LOSS_CLAIMS.PARSE_DOCUMENT_FROM_STAGE("FILE_NAME" VARCHAR)
RETURNS VARIANT
LANGUAGE SQL
AS '
    SELECT AI_PARSE_DOCUMENT(
        TO_FILE(''@ins_co.loss_claims.loss_evidence'', file_name),
        {
            ''mode'': ''LAYOUT'',
            ''page_split'': TRUE
        }
    )::VARIANT
';

CREATE OR REPLACE FUNCTION INS_CO.LOSS_CLAIMS.GET_IMAGE_SUMMARY("IMAGE_FILE" VARCHAR, "STAGE_NAME" VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
AS '
    SELECT SNOWFLAKE.CORTEX.COMPLETE(
        ''claude-3-5-sonnet'',
        ''Summarize the key insights from the attached image in 100 words.'',
        TO_FILE(''@'' || STAGE_NAME || ''/'' || IMAGE_FILE)
    )
';

CREATE OR REPLACE PROCEDURE INS_CO.LOSS_CLAIMS.TRANSCRIBE_AUDIO_SIMPLE("FILE_NAME" VARCHAR, "STAGE_NAME" VARCHAR DEFAULT '@loss_evidence')
RETURNS OBJECT
LANGUAGE SQL
EXECUTE AS OWNER
AS '
BEGIN
    -- This approach avoids variable scoping issues by using a different pattern
    RETURN (
        WITH transcription_query AS (
            SELECT 
                :file_name as fn,
                :stage_name as sn,
                AI_TRANSCRIBE(
                    TO_FILE(:stage_name, :file_name),
                    PARSE_JSON(''{"timestamp_granularity": "speaker"}'')
                ) as transcription_result
        )
        SELECT OBJECT_CONSTRUCT(
            ''success'', TRUE,
            ''file_name'', fn,
            ''stage_name'', sn,
            ''transcription'', transcription_result,
            ''transcription_timestamp'', CURRENT_TIMESTAMP()
        )
        FROM transcription_query
    );
EXCEPTION
    WHEN OTHER THEN
        RETURN OBJECT_CONSTRUCT(
            ''success'', FALSE,
            ''file_name'', :file_name,
            ''stage_name'', :stage_name,
            ''error_code'', SQLCODE,
            ''error_message'', SQLERRM,
            ''transcription_timestamp'', CURRENT_TIMESTAMP()
        );
END;
';
