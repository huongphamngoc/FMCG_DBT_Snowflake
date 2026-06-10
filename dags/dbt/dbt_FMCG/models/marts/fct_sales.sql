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
dim_customer AS (
    SELECT * FROM {{ ref('dim_customers') }}
),
dim_product AS (
    SELECT * FROM {{ ref('dim_products') }}
),
dim_employee AS (  
    SELECT * FROM {{ ref('dim_employees') }}
)

SELECT
    -- ==========================================
    -- 1. TRADING INDEX (METRICS)
    -- ==========================================
    s.SalesID,
    s.TransactionNumber,       -- Used to count the number of invoices (Basket Size, AOV, Customer Segment)
    s.SalesDate,               -- The date and specific time frame for the transaction.
    EXTRACT(month FROM s.SalesDate) AS SalesMonth, -- Standard timeline for monthly trend analysis
    EXTRACT(year FROM s.SalesDate) AS SalesYear,   -- Standard timeline for yearly trend analysis

    s.Quantity,                -- Used to calculate volume, analyze profit correlation
    p.Price AS UnitPrice,
    s.Discount,
    (p.Price * s.Quantity) * (1 - s.Discount) AS NetRevenue,             -- Total actual revenue (after discount)
    (p.Price * s.Quantity) AS GrossRevenue, -- Revenue before discount (used to reference the discount rate)
    s.SalesDate_Status, -- Data quality indicator for sales date, used to filter out or analyze data issues in time-based analysis.
    -- ==========================================
    -- 2. PRODUCT DIMENSION
    -- ==========================================
    s.ProductID,
    p.ProductName,
    p.Class AS ProductClass,   -- Performance evaluation based on attribute classification.
    p.CategoryName,          -- Analysis of market share, ranking of top/bottom categories
    p.Resistant,               
    p.IsAllergic,           -- Analysis of special product groups (for customers with specific needs)
    p.VitalityDays,        -- Analysis of product lifecycle, forecasting replacement demand
    p.ModifyDate AS ProductLastModified, -- The last date the product information was updated or edited.

    -- ==========================================
    -- 3. CUSTOMER DIMENSION
    -- ==========================================
    s.CustomerID,
    -- Combine first and last names for a more concise report.
    CONCAT(c.FirstName, ' ', COALESCE(c.MiddleInitial || ' ', ''), c.LastName) AS CustomerFullName,

    -- ==========================================
    -- 4. MARKET GEOGRAPHY
    -- ==========================================
    -- Use customer addresses to assess market development strategies.
    c.CityName AS MarketCity,
    c.CountryName AS MarketCountry,

    -- ==========================================
    -- 5. EMPLOYEE DIMENSION
    -- ==========================================
    s.SalesPersonID,
    CONCAT(e.FirstName, ' ', COALESCE(e.MiddleInitial || ' ', ''), e.LastName) AS SalesPersonFullName,
    
    -- Optional: Branch/employee geography (rename to avoid duplication with Market)
    e.CityName AS SalesPersonCity,
    e.CountryName AS SalesPersonCountry, -- Geographic workforce analysis, regional performance evaluation.
    EXTRACT(year FROM e.BirthDate) AS SalesPersonBirthYear, -- Age and generation analysis of the sales force
    e.Gender AS SalesPersonGender, -- Gender analysis of the sales force
    EXTRACT(year FROM e.HireDate) AS SalesPersonHireYear -- Tenure and career stage analysis of the sales force

FROM fct_sale AS s
LEFT JOIN  dim_customer AS c ON s.CustomerID = c.CustomerID
LEFT JOIN  dim_product AS p ON s.ProductID = p.ProductID
LEFT JOIN  dim_employee AS e ON s.SalesPersonID = e.EmployeeID
