with customers AS (
    SELECT * FROM {{ ref('stg_fmcg_customers') }}
),
locations AS (
    SELECT * FROM {{ ref('int_locations_joined') }}
)
SELECT
    c.CustomerID,
    CONCAT(c.FirstName, ' ', COALESCE(c.MiddleInitial || ' ', ''), c.LastName) AS CustomerFullName,
    c.Address AS CustomerAddress,
    l.CityName AS CustomerCity,
    l.CountryName AS CustomerCountry
FROM customers c
LEFT JOIN locations l ON c.CityID = l.CityID