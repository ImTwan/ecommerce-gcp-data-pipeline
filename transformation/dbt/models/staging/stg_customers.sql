WITH source_customers AS (
    SELECT *
    FROM {{ source('glamira', 'glamira_raw') }}
    WHERE collection = 'checkout_success'
),

customer_cast AS (
    SELECT 
       SAFE_CAST(user_id_db AS INT64) AS user_id_db,
       LOWER(email_address) AS email_address
    FROM source_customers
),

unknown_value AS(
    SELECT 
        user_id_db, 
        COALESCE(email_address,'Not defined') AS email_address
    FROM customer_cast
)

SELECT *
FROM unknown_value
