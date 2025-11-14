show tables;

-- =================================== stream 1
select count(*) from collection_events;

describe table collection_events;

CREATE OR REPLACE STREAM STREAM_collection_events 
ON TABLE collection_events;

SHOW STREAMS IN SCHEMA my_schema;

SELECT count(*) FROM my_schema.STREAM_collection_events;

-- ===================================

CREATE OR REPLACE TABLE loan_accounts_audit (
    LOANID NUMBER(38,0),
    CUSTOMERID NUMBER(38,0),
    OPERATION VARCHAR(10), 
    CHANGE_TIMESTAMP TIMESTAMP,
    UPDATED_BY STRING
);


INSERT INTO loan_accounts_audit (LOANID, CUSTOMERID, OPERATION, CHANGE_TIMESTAMP, UPDATED_BY)
SELECT
    LOANID,
    CUSTOMERID,
    METADATA$ACTION,
    CURRENT_TIMESTAMP,
    CURRENT_USER
FROM loan_accounts_stream;


-- ================== extra

CREATE OR REPLACE TABLE my_schema.AUDIT_collection_events (
    EVENTID NUMBER(38,0),
    LOANID NUMBER(38,0),
    EVENTDATE DATE,
    DPD NUMBER(38,0),
    ACTIONTYPE VARCHAR(16777216),
    PTP_FLAG NUMBER(38,0),
    PAYMENTAMOUNT NUMBER(38,2),
    AGENTID NUMBER(38,0),
    DML_ACTION STRING,     
    IS_UPDATE BOOLEAN       
);

CREATE OR REPLACE TASK my_schema.collection_events_AUDIT_TASK
WAREHOUSE = COMPUTE_WH
SCHEDULE = '1 MINUTE'
AS
INSERT INTO my_schema.AUDIT_collection_events
SELECT 
    EVENTID,
    LOANID,
    EVENTDATE,
    DPD,
    ACTIONTYPE,
    PTP_FLAG,
    PAYMENTAMOUNT,
    AGENTID,
    METADATA$ACTION AS DML_ACTION,
    METADATA$ISUPDATE AS IS_UPDATE
FROM my_schema.STREAM_collection_events;

ALTER TASK my_schema.collection_events_AUDIT_TASK suspend;
SHOW TASKS IN SCHEMA my_schema;
SELECT * FROM my_schema.AUDIT_collection_events;

commit;

-- =============================================================

-- =================================== stream 2
select * from nv_laon_acc;

describe table nv_laon_acc;

CREATE OR REPLACE STREAM STREAM_loan_data
ON TABLE loan_data;

SHOW STREAMS IN SCHEMA my_schema;

SELECT * FROM my_schema.STREAM_nv_laon_acc;

