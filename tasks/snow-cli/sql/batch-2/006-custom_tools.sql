CREATE OR REPLACE FUNCTION INS_CO.LOSS_CLAIMS.CLASSIFY_DOCUMENT(p_file_name VARCHAR, p_stage_name VARCHAR DEFAULT '@INS_CO.LOSS_CLAIMS.LOSS_EVIDENCE')
  RETURNS OBJECT
  LANGUAGE SQL
  AS
  $$
    WITH classification_result_cte
         AS (SELECT to_file(p_stage_name, p_file_name) AS target_file,
                    ai_extract(FILE => target_file,
                               responseFormat =>
                               ARRAY_CONSTRUCT('What type of document is this? Classify as one of: Invoice, Evidence Image, Medical Bill, Insurance Claim, Policy Document, Correspondence, Legal Document, Financial Statement, Other')
                    )                                  AS classification_data)

    SELECT OBJECT_CONSTRUCT(
                   'success', TRUE,
                   'file_name', fl_get_relative_path(classification_result_cte.target_file),
                   'classification_type', classification_data[0]:answer::STRING,
                   'description', classification_data[1]:answer::STRING,
                   'business_context', classification_data[2]:answer::STRING,
                   'document_purpose', classification_data[3]:answer::STRING,
                   'confidence_score', (classification_data[0]:score::NUMBER +
                                        classification_data[1]:score::NUMBER +
                                        classification_data[2]:score::NUMBER +
                                        classification_data[3]:score::NUMBER) / 4,
                   'classification_timestamp', CURRENT_TIMESTAMP(),
                   'full_classification_data', classification_data
           ) AS result
    FROM classification_result_cte
  $$
;

CREATE OR REPLACE FUNCTION INS_CO.LOSS_CLAIMS.PARSE_DOCUMENT_FROM_STAGE(p_file_name VARCHAR, p_stage_name VARCHAR DEFAULT '@INS_CO.LOSS_CLAIMS.LOSS_EVIDENCE')
  RETURNS VARIANT
  LANGUAGE SQL
  AS
  $$
    WITH ai_parse_doc_cte AS (SELECT to_file(p_stage_name, p_file_name)                                    AS target_file,
                                     TO_OBJECT(PARSE_JSON('{"mode": "layout", "page_split": true}'))       AS ai_parse_document_options,
                                     TO_VARIANT(ai_parse_document(target_file, ai_parse_document_options)) AS raw_text_dict)

    SELECT raw_text_dict
    FROM ai_parse_doc_cte
  $$
;

CREATE OR REPLACE FUNCTION INS_CO.LOSS_CLAIMS.GET_IMAGE_SUMMARY(p_file_name VARCHAR, p_stage_name VARCHAR DEFAULT '@INS_CO.LOSS_CLAIMS.LOSS_EVIDENCE')
  RETURNS VARIANT
  LANGUAGE SQL
  AS
  $$
    SELECT AI_COMPLETE(
                   'claude-3-5-sonnet',
                   'Summarize the key insights from the attached image in 100 words.',
                   to_file(p_stage_name, p_file_name)
           )
  $$
;

CREATE OR REPLACE PROCEDURE INS_CO.LOSS_CLAIMS.TRANSCRIBE_AUDIO_SIMPLE(p_file_name VARCHAR, p_stage_name VARCHAR DEFAULT '@INS_CO.LOSS_CLAIMS.LOSS_EVIDENCE')
  RETURNS OBJECT
  LANGUAGE SQL
  EXECUTE AS OWNER
  AS
  $$
    DECLARE
    v_obj OBJECT;
    BEGIN
      WITH transcription_query_cte AS (SELECT to_file(:p_stage_name, :p_file_name) AS target_file,
                                              ai_transcribe(f => target_file,
                                                            options => PARSE_JSON('{"timestamp_granularity": "speaker"}')
                                              )                                    AS transcription_result)

      SELECT OBJECT_CONSTRUCT(
                     'success', TRUE,
                     'file_name', fl_get_relative_path(target_file),
                     'stage_name', fl_get_stage(target_file),
                     'transcription', tq.transcription_result,
                     'transcription_timestamp', CURRENT_TIMESTAMP()
             ) into :v_obj
      FROM transcription_query_cte tq;

      RETURN v_obj;
    END;
  $$
;
