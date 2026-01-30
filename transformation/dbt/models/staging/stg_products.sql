WITH source_product AS (
    SELECT *
    FROM {{ source('glamira', 'crawl_product') }}
), 

product_cleaned AS (
    SELECT
        CAST(product_id AS INT64) AS product_id
        ,COALESCE(name,'Not defined') AS product_name
        ,CASE 
            WHEN product_type IN ('-1','--_select_--') THEN 'Not defined'
            ELSE COALESCE(product_type ,'Not defined')
        END AS product_type
        ,COALESCE(category_name,'Not defined') AS category_name
        ,CASE
            WHEN collection IN ('4380,6071') THEN '3_&_5_stones'
            ELSE COALESCE(collection,'Not defined') 
        END AS collection_name
        ,CASE 
            WHEN collection = 'False' THEN 'Not defined'
            ELSE COALESCE(gender,'Not defined') 
        END AS gender
    FROM source_product
)

SELECT *
FROM product_cleaned
