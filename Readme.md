## Insurance Claims Agent Demo
Using Snowflake Cortex Analyst, Cortex Search, Cortex AI SQL, Cortex Agents, and Snowflake Intelligence we are receiving claims data and allowing users to ask both predefined and free-form questions about the claims. We are also describing images and comparing them to claim descriptions to determine if the supporting evidence aligns with the description.

We are able to join unstructured and structured data by combining structured claims data with unstructured data from claim file notes, state insurance guidelines, invoices, and call transcriptions.

<img width="957" height="719" alt="Screenshot 2025-10-30 at 4 14 02 PM" src="https://github.com/user-attachments/assets/436f4dfc-6eab-48d1-b148-5c07f632cbb9" />

# Setup
1. Run the setup.sql file to create all objects needed for the demo

In the setup.sql file we create the following objects:

* database: ins_co
* schema: loss_claims
* stage: loss evidence
*  tables:
  * Claims
  * Claim Lines
  * Financial Transactions
  * Authorization
  * Parsed_invoices
  * Parsed_guidelines
  * Parsed_claim_notes

2. Upload the following files to the loss_evidence stage
   * 1899_claim_evidence1.jpeg
   * 1899_claim_evidence2.jpeg
   * Claim_Notes.pdf
   * Guidelines.docx
   * invoice.png
   * Gemini_generated_3.jpeg
   * ins_co_1899_call.wav

3. The setup script creates a 'Models' stage. Please upload the following .yaml file and create a Cortex Analyst using this .yaml file
   * CA_INS_CO 8_20_2025, 4_52 PM.yaml
4. Create a new Streamlit app in the database and schema and paste the streamlit.py file into SIS
5. Alternatively, you can create an Agent and use this in Snowflake intelligence
   6. Run Tools config
   7. Run Agents config
  
6. 




