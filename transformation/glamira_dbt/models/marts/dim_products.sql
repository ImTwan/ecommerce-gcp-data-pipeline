WITH products AS (
    SELECT
        product_id,
        product_name,
        product_type,
        category_name,
        collection_name,
        gender
    FROM {{ ref('stg_products') }}
    -- remove any null product_ids at the source
    WHERE product_id IS NOT NULL
),

unknown_product AS (
    SELECT
        -1 AS product_id,
        'Not defined' AS product_name,
        'Not defined' AS product_type,
        'Not defined' AS category_name,
        'Not defined' AS collection_name,
        'Not defined' AS gender
),

all_products AS (
    SELECT * FROM products
    UNION ALL
    SELECT * FROM unknown_product
)

SELECT *
FROM all_products
WHERE product_id IS NOT NULL
