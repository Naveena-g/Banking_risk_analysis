describe table dummyloan;
describe table dummycollectionevents;
describe table dummyregionhierarchy;
describe table dummy;
describe table dummyloan;

(select count(PTP_FLAG) from dummycollectionevents where PTP_FLAG=1  group by agentid) ;

SELECT DISTINCT STATUS
FROM DUMMYLOAN
ORDER BY STATUS;

SELECT 
    LOANID,
    ORIGINATIONAMOUNT,
    CURRENTBALANCE,
    STATUS
FROM DUMMYLOAN
WHERE 
    CURRENTBALANCE > 0           -- loan closed with remaining balance
    AND WRITEOFFFLAG = 0         -- not written off
    AND STATUS NOT IN ('Active'); -- loan not active

SELECT COUNT(*) 
FROM DUMMYLOAN
WHERE STATUS = 'Closed'
  AND WRITEOFFFLAG = 0
  AND CURRENTBALANCE > 0;



describe table DUMMYCOLLATERALREGISTER;
describe table DUMMYCOLLECTIONEVENTS;
describe table DUMMYCUSTOMERMASTER;
describe table DUMMYFACTBUREAU;
describe table DUMMYFACTCOLLECTIONS;
describe table DUMMYFACTLOAN;
describe table DUMMYLOAN;
describe table DUMMYREGIONHIERARCHY;

select distinct(loanid) from DUMMYLOAN;
select * from collection_events where dpd=0 ;

SELECT 
    LOANID,
    MIN(CASE WHEN DPD > 0 THEN EVENTDATE END) AS FIRST_DELINQUENT_DATE,
    MIN(CASE WHEN DPD = 0 THEN EVENTDATE END) AS FIRST_CURE_DATE
FROM 
    DUMMYCOLLECTIONEVENTS
GROUP BY 
    LOANID
HAVING 
    MIN(CASE WHEN DPD > 0 THEN EVENTDATE END) IS NOT NULL
    AND MIN(CASE WHEN DPD = 0 THEN EVENTDATE END) IS NOT NULL
    AND MIN(CASE WHEN DPD = 0 THEN EVENTDATE END) 
        > MIN(CASE WHEN DPD > 0 THEN EVENTDATE END);


show tables;
describe table DIMCOLLATERAL_BACKUP;
describe table DIMCUSTOMER_BACKUP;
describe table DIMPRODUCT_BACKUP;
describe table DIMREGION_BACKUP;

select distinct (SEGMENT) from DIMCUSTOMER_BACKUP;