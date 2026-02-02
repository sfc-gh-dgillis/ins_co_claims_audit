CREATE OR REPLACE MCP SERVER claims_mcp_server
  FROM SPECIFICATION $$
    tools:
      - name: "ins-co-claim-notes"
        identifier: "INS_CO.LOSS_CLAIMS.INS_CO_CLAIM_NOTES"
        type: "CORTEX_SEARCH_SERVICE_QUERY"
        description: "A tool that performs keyword and vector search over unstructured claims note data."
        title: "Claim Note Search"

      - name: "sql-execution-tool"
        type: "SYSTEM_EXECUTE_SQL"
        description: "A tool to execute SQL queries against the connected Snowflake database."
        title: "SQL Execution Tool"
$$;
