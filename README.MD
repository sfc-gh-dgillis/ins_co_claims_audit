## 🛡️ Insurance Claims Agent Demo

This repository showcases a powerful insurance claims agent built using **Snowflake Cortex** services. 

It processes claims data, handles both structured and unstructured information, and allows users to gain insights through natural language.

### ✨ Key Features & Technology

This demo leverages the following Snowflake tools to deliver an intelligent claims processing solution:

* **Snowflake Cortex Analyst, Cortex Search, AISQL, and Agents:** Used for sophisticated data analysis and query generation.
* **Snowflake Intelligence:** Serves as the UI which enables users to ask complex questions about claims.
* **Multimodal Analysis:** Describes and compares claims images with the claim description to verify if **supporting evidence aligns with the reported incident**.
* **Audio Transcription:** Transcribes text from an audio or video file with optional timestamps and speaker labels.

### 🔗 Data Integration

A core capability is the ability to join **unstructured** and **structured** data, providing a complete view of each claim.

* **Structured Data:** Claims, financial transactions, and authorization records.
* **Unstructured Data:** Claim file notes, state insurance guidelines, invoices, claim photo eveidens, and audio call files.

---

<img width="1069" height="748" alt="Screenshot 2025-11-05 at 2 40 51 PM" src="https://github.com/user-attachments/assets/e92c1fb4-fe6e-42df-8cdc-96c582ad8c50" />

## 🛠️ Setup Instructions

Follow these steps to set up the environment and run the demo.

### Step 1: Initialize Database Objects

1.  Run the `setup.sql` file. This script creates the necessary database objects:
    * **Database:** `ins_co`
    * **Schema:** `loss_claims`
    * **Stage:** `loss_evidence`
    * **Tables:**
        * `Claims`
        * `Claim Lines`
        * `Financial Transactions`
        * `Authorization`
        * `Parsed_invoices`
        * `Parsed_guidelines`
        * `Parsed_claim_notes`

### Step 2: Upload Evidence Files

1.  Upload the following files to the **`loss_evidence`** stage:
    * `1899_claim_evidence1.jpeg`
    * `1899_claim_evidence2.jpeg`
    * `Claim_Notes.pdf`
    * `Guidelines.docx`
    * `invoice.png`
    * `Gemini_generated_3.jpeg`
    * `ins_co_1899_call.wav`

### Step 3: Configure Cortex Analyst

1.  The setup script automatically creates a **`Models`** stage.
2.  Upload the following `.yaml` file to the `Models` stage:
    * `CA_INS_CO 8_20_2025, 4_52 PM.yaml`
3.  **Create a Cortex Analyst** using the uploaded `.yaml` configuration file.

### Step 4: Deploy the Interface

Choose one of the following methods for deploying the user interface:

#### Option A: Streamlit in Snowflake

1.  Create a new **Streamlit application** within the `ins_co` database and `loss_claims` schema.
2.  Paste the contents of the **`streamlit.py`** file into the Streamlit in Snowflake (SIS) editor.

#### Option B: Snowflake Intelligence Agent

1.  Create an **Agent** and use it directly within Snowflake Intelligence.
2.  Run the **Tools config**.
3.  Run the **Agents config**.


### Sample Questions this demo helps answer:

Payment Processing Time: What percentage of payments were issued to the vendor within the following timeframes after invoice receipt?

3–5 calendar days

8–13 calendar days

14–29 calendar days

30+ calendar days

Reserve Rationale Presence: Was a reserve rationale documented in the claim file notes?

Reserve Rationale Sufficiency: Did the reserve rationale adequately explain the reserve figure(s) set?

Reserve Extension Timeliness: Was the reserve extension requested in a timely manner?

Payment Over Reserve: Was a payment issued in excess of the current reserve amount on an open claim?

Authority Violation (Reserves/Payments): Were the reserving or payment amounts in excess of the examiner's authority?

Authority Compliance: When the claim exceeded the examiner's authority, were all elements of authority properly handled?

Payment Compliance: Was the payment made according to the state guidelines?

Settlement Timeliness: According to the state guidelines, was the claim settled within the required timelines?


