CREATE OR REPLACE PROCEDURE sp_update_factcollections()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN

    CREATE OR REPLACE TEMP TABLE stream_buffer AS
    SELECT *
    FROM collection_events_stream;

    CREATE OR REPLACE TEMP TABLE src_data AS
    SELECT *
    FROM (
        SELECT
            ce.EVENTID,
            dc.CustomerSK,
            dr.RegionSK,
            ce.DPD,
            ce.PaymentAmount,
            ce.PTP_Flag AS PTP,
            CASE
                WHEN COALESCE(ce.PaymentAmount,0) > 0 THEN 'Paid'
                WHEN COALESCE(ce.PTP_Flag,0) = 1 AND COALESCE(ce.PaymentAmount,0) = 0 THEN 'Promise to Pay'
                WHEN COALESCE(ce.PaymentAmount,0) = 0 AND COALESCE(ce.PTP_Flag,0) = 0 THEN 'Not Connected'
                ELSE 'No Action'
            END AS ContactResult,
            ROUND(
                LEAST(
                    (SUM(ce.PaymentAmount) OVER (PARTITION BY ld.CustomerID) /
                     NULLIF(SUM(ld.CurrentBalance) OVER (PARTITION BY ld.CustomerID),0)) * 100,
                    100
                ), 2
            ) AS CurePercent,
            ROW_NUMBER() OVER (PARTITION BY ce.EVENTID ORDER BY ce.EVENTDATE DESC) AS rn
        FROM stream_buffer ce
        LEFT JOIN loan_data ld ON ce.LoanID = ld.LoanID
        LEFT JOIN dimcustomer dc ON ld.CustomerID = dc.CustomerID
        LEFT JOIN dimregion dr ON ld.RegionID = dr.RegionID
    )
    WHERE rn = 1;

    MERGE INTO factcollections tgt
    USING src_data src
    ON tgt.EVENTID = src.EVENTID
    WHEN MATCHED THEN
        UPDATE SET
            DPD = src.DPD,
            ContactResult = src.ContactResult,
            PTP = src.PTP,
            CurePercent = src.CurePercent
    WHEN NOT MATCHED THEN
        INSERT (EVENTID, CustomerSK, RegionSK, DPD, ContactResult, PTP, CurePercent)
        VALUES (src.EVENTID, src.CustomerSK, src.RegionSK, src.DPD, src.ContactResult, src.PTP, src.CurePercent);

    INSERT INTO audit_log (
        audit_id,
        pipeline_name,
        run_start_time,
        run_end_time,
        total_events_processed,
        total_events_updated,
        total_events_inserted,
        status
    )
    WITH agg AS (
        SELECT
            COUNT(*) AS total_events_processed,
            SUM(CASE WHEN tgt.EVENTID IS NOT NULL THEN 1 ELSE 0 END) AS total_events_updated,
            SUM(CASE WHEN tgt.EVENTID IS NULL THEN 1 ELSE 0 END) AS total_events_inserted
        FROM stream_buffer ce
        LEFT JOIN factcollections tgt ON ce.EVENTID = tgt.EVENTID
    ),
    next_id AS (
        SELECT COALESCE(MAX(audit_id), 0) AS last_id FROM audit_log
    )
    SELECT
        last_id + 1 AS audit_id,
        'FactCollections_Update',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        total_events_processed,
        total_events_updated,
        total_events_inserted,
        'SUCCESS'
    FROM agg
    CROSS JOIN next_id;

    RETURN 'FactCollections Update Completed';
END;
$$;
