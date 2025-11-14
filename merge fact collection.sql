MERGE INTO factcollections tgt
USING (
    SELECT
        dc.CustomerSK,                         
        dr.RegionSK,                           
        ce.DPD,                                

        CASE
            WHEN COALESCE(ce.PaymentAmount,0) > 0 THEN 'Paid'
            WHEN COALESCE(ce.PTP_Flag,0) = 1 AND COALESCE(ce.PaymentAmount,0) = 0 THEN 'Promise to Pay'
            WHEN COALESCE(ce.PaymentAmount,0) = 0 AND COALESCE(ce.PTP_Flag,0) = 0 THEN 'Not Connected'
            ELSE 'No Action'
        END AS ContactResult,

        ce.PTP_Flag AS PTP,

        ROUND(
            LEAST(
                (SUM(ce.PaymentAmount) OVER (PARTITION BY ld.CustomerID) / 
                 NULLIF(SUM(ld.CurrentBalance) OVER (PARTITION BY ld.CustomerID),0)) * 100,
                100
            ), 2
        ) AS CurePercent

    FROM collection_events ce
    LEFT JOIN loan_data ld
        ON ce.LoanID = ld.LoanID
    LEFT JOIN dimcustomer dc
        ON ld.CustomerID = dc.CustomerID
    LEFT JOIN dimregion dr
        ON ld.RegionID = dr.RegionID
) src
ON tgt.CustomerSK = src.CustomerSK
   AND tgt.RegionSK = src.RegionSK
   AND tgt.DPD = src.DPD
WHEN MATCHED THEN
    UPDATE SET
        ContactResult = src.ContactResult,
        PTP = src.PTP,
        CurePercent = src.CurePercent
WHEN NOT MATCHED THEN
    INSERT (CustomerSK, RegionSK, DPD, ContactResult, PTP, CurePercent)
    VALUES (src.CustomerSK, src.RegionSK, src.DPD, src.ContactResult, src.PTP, src.CurePercent);
