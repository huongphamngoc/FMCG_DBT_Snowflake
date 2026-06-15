{{
    config(
        materialized = 'table',
        description = 'One Big Table (OBT) contains all flattened transaction data with full analytical dimensions (Products, Customers, Personnel, Geography) for BI reporting.',
        unique_key = 'SalesID'
    )
}}

WITH fct_sale AS (
    SELECT * FROM {{ ref('stg_fmcg_sales') }}
),
dim_product AS (
    SELECT * FROM {{ ref('dim_products') }}
)

SELECT
    s.SalesID,
    s.ProductID,
    s.CustomerID,
    s.SalesPersonID,
    s.TransactionNumber,       -- Used to count the number of invoices (Basket Size, AOV, Customer Segment)
    
    s.Quantity,                -- Used to calculate volume, analyze profit correlation
    p.Price AS UnitPrice,
    s.Discount,
    (p.Price * s.Quantity) * (1 - s.Discount) AS NetRevenue,             -- Total actual revenue (after discount)
    (p.Price * s.Quantity) AS GrossRevenue, -- Revenue before discount (used to reference the discount rate)

    s.SALES_DATE AS SalesDate,               -- The date and specific time frame for the transaction.
    s.SALES_TIME AS SalesTime,               -- The time of day for the transaction, used for time-based analysis (e.g., peak hours).
    s.SalesMonth, -- Standard timeline for monthly trend analysis
    s.SalesYear,   -- Standard timeline for yearly trend analysis
    s.SalesDate_Status -- Data quality indicator for sales date, used to filter out or analyze data issues in time-based analysis.

FROM fct_sale AS s
LEFT JOIN  dim_product AS p ON s.ProductID = p.ProductID
