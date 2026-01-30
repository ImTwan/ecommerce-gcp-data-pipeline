WITH source_customers AS (
    -- Select distinct customers from the staging model
    SELECT DISTINCT
        ABS(FARM_FINGERPRINT(CONCAT(user_id_db, '|', email_address))) AS customer_id,
        user_id_db,
        email_address
    FROM {{ ref('stg_customers') }}
    WHERE user_id_db IS NOT NULL
),

unknown_customer AS (
    -- Add an 'Not defined' customer for missing references
    SELECT
        -1 AS customer_id,
        -1 AS user_id_db,
        'Not defined' AS email_address
)

SELECT *
FROM source_customers

UNION ALL

SELECT *
FROM unknown_customer
