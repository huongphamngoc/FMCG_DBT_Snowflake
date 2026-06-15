WITH employees AS (
    SELECT * FROM {{ ref('stg_fmcg_employees') }}
),
locations AS (
    SELECT * FROM {{ ref('int_locations_joined') }}
)
SELECT
    e.EmployeeID AS SalesPersonID,
    CONCAT(e.FirstName, ' ', COALESCE(e.MiddleInitial || ' ', ''), e.LastName) AS SalesPersonFullName,
    EXTRACT(year FROM e.BirthDate) AS SalesPersonBirthYear, -- Age and generation analysis of the sales force
    e.Gender AS SalesPersonGender,
    EXTRACT(year FROM e.HireDate) AS SalesPersonHireYear -- Tenure and career stage analysis of the sales force
    l.CityName  AS SalesPersonCity,
    l.CountryName AS SalesPersonCountry,
    l.CountryCode AS SalesPersonCountryCode,
    l.Zipcode AS SalesPersonZipcode
FROM employees AS e
LEFT JOIN locations AS l ON e.CityID = l.CityID