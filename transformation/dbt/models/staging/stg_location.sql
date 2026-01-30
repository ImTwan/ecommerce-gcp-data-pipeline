WITH source_location AS (
    SELECT * 
    FROM  {{ source('glamira', 'ip_locations') }}
    
),
renamed_location AS(
    
    SELECT DISTINCT
        ip AS ip_address,
        country AS country_name,
        region AS region_name,
        city AS city_name
    FROM source_location
),

stg_location_gen_id AS (
    SELECT 
        CAST(
            ABS(
                FARM_FINGERPRINT(
                    CONCAT(
                        COALESCE(country_name, ''), '|',
                        COALESCE(region_name, ''), '|',
                        COALESCE(city_name, '')
                    )
                )
            ) AS INT64
        ) AS location_id,
        ip_address,
        country_name,
        region_name,
        city_name
    FROM renamed_location
),

stg_location_final AS (
    SELECT 
        location_id,
        ip_address,
        country_name,
        region_name,
        city_name
    FROM stg_location_gen_id
)

SELECT *
FROM stg_location_final
