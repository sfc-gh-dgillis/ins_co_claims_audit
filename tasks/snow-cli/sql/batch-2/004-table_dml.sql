USE DATABASE ins_co;
USE SCHEMA ins_co.loss_claims;

INSERT INTO CLAIMS (
    CLAIM_NO, LINE_OF_BUSINESS, CLAIM_STATUS, CAUSE_OF_LOSS,
    CREATED_DATE, LOSS_DATE, REPORTED_DATE, CLAIMANT_ID, PERFORMER,
    POLICY_NO, FNOL_COMPLETION_DATE, LOSS_DESCRIPTION, LOSS_STATE, LOSS_ZIP_CODE
) VALUES
('1899', 'Property', 'Open', 'Hurricane', '2025-01-06', '2025-01-06', '2025-01-06', '19', '18',
 '888', '01/06/2025', 'Damaged dwelling and fence after the tree fell', 'NJ', '8820');

INSERT INTO CLAIM_LINES (
    CLAIM_NO, LINE_NO, LOSS_DESCRIPTION, CLAIM_STATUS,
    CREATED_DATE, REPORTED_DATE, CLAIMANT_ID, PERFORMER_ID
) VALUES
('1899', 16, 'Damaged Dwelling', 'Open', '2025-01-06', '2025-01-06', '19', '171'),
('1899', 17, 'Damaged Fence', 'Open', '2025-01-06', '2025-01-06', '19', '181'),
('1899', 18, 'Damaged Lawn', 'Open', '2025-01-06', '2025-01-06', '19', '191');


INSERT INTO FINANCIAL_TRANSACTIONS (
    FXID, LINE_NO, FINANCIAL_TYPE, CURRENCY, FIN_TX_AMT, FIN_TX_POST_DT
) VALUES
('21', 16, 'RSV', 'USD', 4000.00, '2025-02-15'),
('22', 16, 'PAY', 'USD', 4000.00, '2025-06-15'), -- Mapped to Line 18 (Damaged Dwelling)
('23', 17, 'RSV', 'USD', 3000.00, '2025-03-06'), -- Mapped to Line 19 (Damaged Fence)
('24', 17, 'PAY', 'USD', 3500.00, '2025-05-05'), -- Mapped to Line 19 (Damaged Fence)
('25', 18, 'RSV', 'USD', 2000.00, '2025-02-15'), -- Mapped to Line 20 (Damaged Lawn)
('26', 18, 'PAY', 'USD', 2000.00, '2025-04-05'); -- Mapped to Line 20 (Damaged Lawn);

INSERT INTO AUTHORIZATION (PERFORMER_ID, FROM_AMT, TO_AMT, CURRENCY) VALUES
('171', 0.00, 5000.00, 'USD'),
('181', 0.00, 3000.00, 'USD'),
('191', 0.00, 2500.00, 'USD');

INSERT INTO INVOICES (INV_ID, INV_LINE_NBR, LINE_NO, DESCRIPTION, CURRENCY, INVOICE_AMOUNT, INVOICE_DATE, VENDOR) VALUES
('5', 1, 16, 'Wooden Logs', 'USD', 2500.00, '2025-05-15', 'ABC'),
('5', 2, 16, 'Hardware', 'USD', 1000.00, '2025-05-15', 'ABC'),
('5', 3, 16, 'Labor', 'USD', 500.00, '2025-05-15', 'ABC'),
('6', 1, 17, 'Fence', 'USD', 3000.00, '2025-04-20', 'LMN'),
('6', 2, 17, 'Labor', 'USD', 500.00, '2025-04-20', 'LMN'),
('7', 1, 18, 'Lawn', 'USD', 1200.00, '2025-03-18', 'XYZ'),
('7', 2, 18, 'Equipment Rental', 'USD', 200.00, '2025-03-18', 'XYZ'),
('7', 3, 18, 'Labor', 'USD', 600.00, '2025-03-18', 'XYZ');

INSERT INTO parsed_claim_notes (filename, extracted_content, claim_no)
WITH claim_notes_cte AS (SELECT relative_path                                                         AS file_name,
                                to_file('@ins_co.loss_claims.loss_evidence', relative_path)           AS staged_file,
                                TO_OBJECT(PARSE_JSON('{"mode": "ocr", "page_split": false}'))         AS ai_parse_document_options,
                                TO_VARIANT(ai_parse_document(staged_file, ai_parse_document_options)) AS raw_text_dict,
                                raw_text_dict:content                                                 AS extracted_content
                         FROM directory('@ins_co.loss_claims.loss_evidence'))

SELECT file_name                       AS filename,
       extracted_content               AS extracted_content,
       flattened.value:answer::VARCHAR AS claim_no
FROM claim_notes_cte c,
     LATERAL FLATTEN(INPUT =>
                     snowflake.cortex.extract_answer(c.extracted_content, 'What is the claim number?')) AS flattened
WHERE flattened.value:score::NUMBER >= 0.5
  AND file_name ILIKE '%claim_note%';

INSERT INTO parsed_guidelines (FILENAME, EXTRACTED_CONTENT)
WITH claim_notes_cte AS (SELECT relative_path                                                         AS file_name,
                                to_file('@ins_co.loss_claims.loss_evidence', relative_path)           AS staged_file,
                                TO_OBJECT(PARSE_JSON('{"mode": "ocr", "page_split": false}'))         AS ai_parse_document_options,
                                TO_VARIANT(ai_parse_document(staged_file, ai_parse_document_options)) AS raw_text_dict,
                                raw_text_dict:content                                                 AS extracted_content
                         FROM directory('@ins_co.loss_claims.loss_evidence'))

SELECT file_name                       AS filename,
       extracted_content               AS extracted_content
FROM claim_notes_cte c
WHERE file_name ILIKE '%guideline%';

INSERT INTO parsed_invoices (filename, extracted_content, claim_no)
WITH claim_notes_cte AS (SELECT relative_path                                                         AS file_name,
                                to_file('@ins_co.loss_claims.loss_evidence', relative_path)           AS staged_file,
                                TO_OBJECT(PARSE_JSON('{"mode": "ocr", "page_split": false}'))         AS ai_parse_document_options,
                                TO_VARIANT(ai_parse_document(staged_file, ai_parse_document_options)) AS raw_text_dict,
                                raw_text_dict:content                                                 AS extracted_content
                         FROM directory('@ins_co.loss_claims.loss_evidence'))

SELECT file_name                       AS filename,
       extracted_content               AS extracted_content,
       flattened.value:answer::VARCHAR AS claim_no
FROM claim_notes_cte c,
     LATERAL FLATTEN(INPUT =>
                     snowflake.cortex.extract_answer(c.extracted_content, 'What is the claim no?')) AS flattened
WHERE flattened.value:score::NUMBER >= 0.5
  AND file_name ILIKE '%invoice%';


INSERT INTO notes_chunk_table
SELECT filename                                                             AS filename,
       claim_no                                                             AS claim_no, -- Add this line to include the claim number
       build_scoped_file_url('@ins_co.loss_claims.loss_evidence', filename) AS file_url,
       CONCAT(filename, ': ', c.value::TEXT)                                AS chunk,
       'English'                                                            AS language
FROM parsed_claim_notes,
     LATERAL FLATTEN(snowflake.cortex.split_text_recursive_character(
             extracted_content,
             'markdown',
             200, -- chunks of 200 characters
             30)) c; -- 30 character overlap


INSERT INTO guidelines_chunk_table
SELECT filename,
       build_scoped_file_url('@INS_CO.loss_claims.loss_evidence', filename) AS file_url,
       CONCAT(filename, ': ', c.value::TEXT)                                AS chunk,
       'English'                                                            AS language
FROM parsed_guidelines,
     LATERAL FLATTEN(snowflake.cortex.split_text_recursive_character(
             extracted_content,
             'markdown',
             200, -- chunks of 2000 characters
             30 -- 300 character overlap
                     )) c;
