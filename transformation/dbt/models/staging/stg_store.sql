WITH source_store AS (
    SELECT *
    FROM {{ source('glamira', 'glamira_raw') }}
    WHERE collection = 'checkout_success'
),

final_store_name AS (
    SELECT DISTINCT
        CAST(store_id AS INT64) AS store_id,
        CONCAT('Store ', CAST(store_id AS STRING)) AS store_name
    FROM source_store
)

SELECT *
FROM final_store_name
