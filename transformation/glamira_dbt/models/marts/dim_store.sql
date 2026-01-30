WITH source_store AS (
    SELECT DISTINCT
        store_id,
        store_name
    FROM {{ ref('stg_store') }}
    WHERE store_id IS NOT NULL
),

unknown_store AS (
    SELECT
        -1 AS store_id,
        'Not defined' AS store_name
)

SELECT DISTINCT *
FROM source_store

UNION ALL

SELECT * 
FROM unknown_store
