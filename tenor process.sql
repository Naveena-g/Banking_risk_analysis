
use database db;
use schema s;

select * from customer_master;
select * from collections_events;
select * from bureau_scores;
select * from region_hierachy;

select count(*) from la where tenormonths=0;

select * from collateral_register;
select * from la;
describe table region_hierachy;
describe table la;
describe table customer_master;
describe table collections_events;
describe table bureau_scores;
describe table collateral_register;

select distinct COLLATERALTYPE from collateral_register;

UPDATE la
SET TenorMonths = CASE 
        WHEN b.CollateralType = 'Property'  THEN 240
        WHEN b.CollateralType = 'Deposit'   THEN 12
        WHEN b.CollateralType = 'Equipment' THEN 60
        WHEN b.CollateralType = 'Other'     THEN 24
        WHEN b.CollateralType = 'Gold'      THEN 12
        WHEN b.CollateralType = 'Vehicle'   THEN 48
        ELSE 24
    END
FROM (
    SELECT LoanID, CollateralType
    FROM (
        SELECT
            LoanID,
            CollateralType,
            ROW_NUMBER() OVER (PARTITION BY LoanID ORDER BY Valuation DESC) AS rn
        FROM collateral_register
    ) t
    WHERE t.rn = 1
) b
WHERE la.LoanID = b.LoanID
  AND la.TenorMonths = 0;


UPDATE la
SET TenorMonths =
(
    SELECT MEDIAN(NULLIF(TenorMonths,0)) 
    FROM la AS x 
    WHERE x.RiskBand = la.RiskBand
)
WHERE TenorMonths = 0;
