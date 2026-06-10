WITH source AS (
    SELECT * FROM {{ source('FMCG', 'Sales') }}
)
SELECT 
    "SalesID" AS SalesID,
    "SalesPersonID" AS SalesPersonID,
    "CustomerID" AS CustomerID,
    "ProductID" AS ProductID,
    "Quantity" AS Quantity,
    "Discount" AS Discount,
    "TotalPrice" AS TotalPrice,
    COALESCE("SalesDate", '1200-01-01 00:00:00.000'::TIMESTAMP_NTZ) AS SalesDate,
    CAST(SalesDate AS DATE) AS SALES_DATE,
    CAST(SalesDate AS TIME) AS SALES_TIME,
    CASE 
        WHEN "SalesDate" IS NULL THEN 'Data_Error' 
        ELSE 'Valid' 
    END AS SalesDate_Status,
    "TransactionNumber" AS TransactionNumber
FROM source