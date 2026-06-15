WITH products AS (
    SELECT * FROM {{ ref('stg_fmcg_products') }}
),
categories AS (
    SELECT * FROM {{ ref('stg_fmcg_categories') }}
)
SELECT
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    p.Price,
    p.Class AS ProductClass,   -- Performance evaluation based on attribute classification.
    p.ModifyDate AS ProductLastModified, -- The last date the product information was updated or edited.
    p.Resistant,
    p.IsAllergic,
    p.VitalityDays
FROM products p
LEFT JOIN categories c ON p.CategoryID = c.CategoryID