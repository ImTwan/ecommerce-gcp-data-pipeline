WITH base_location AS (
    SELECT DISTINCT
        location_id,
        REPLACE(country_name, '-', 'Not defined') AS country_name,
        REPLACE(region_name, '-', 'Not defined') AS region_name,
        REPLACE(city_name, '-', 'Not defined') AS city_name
    FROM {{ ref('stg_location') }}
), 

unknown_location AS (
    SELECT
        -1 AS location_id,
        'Not defined' AS country_name,
        'Not defined' AS region_name,
        'Not defined' AS city_name
)

SELECT
    *
FROM base_location

UNION ALL

SELECT *
FROM unknown_location
