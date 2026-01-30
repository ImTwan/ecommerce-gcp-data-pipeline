{{ 
  config(
    materialized = 'incremental',
    unique_key = 'SK_Fact_Sales',
    incremental_strategy = 'merge'
  ) 
}}

WITH base_order AS (

    SELECT *
    FROM {{ ref('stg_sales_order') }}

    {% if is_incremental() %}
      -- Only load new or updated records
      WHERE local_time > (
          SELECT COALESCE(MAX(local_time), '1900-01-01 00:00:00') 
          FROM {{ this }}
      )
    {% endif %}

),

order_final AS (
    SELECT 
        CAST(
            ABS(
                FARM_FINGERPRINT(
                    CONCAT(
                        bo.order_id, '|',
                        bo.product_id
                    )
                )
            ) AS INT64
        ) AS SK_Fact_Sales,
        COALESCE(bo.order_id, -1) AS order_id,
        COALESCE(bo.product_id, -1) AS product_id,
        bo.date_id,
        COALESCE(l.location_id, -1) AS location_id,
        bo.ip_address,
        COALESCE(dc.customer_id, -1) AS customer_id,
        COALESCE(bo.store_id, -1) AS store_id, 
        bo.local_time,
        bo.quantity,
        bo.currency_code,
        bo.price,
        bo.revenue

        FROM base_order bo

    LEFT JOIN {{ ref('dim_products') }} dp
        ON bo.product_id = dp.product_id

    LEFT JOIN {{ ref('dim_customers') }} dc
        ON bo.user_id_db = dc.user_id_db
       AND bo.email_address = dc.email_address

    LEFT JOIN {{ ref('dim_store') }} ds
        ON bo.store_id = ds.store_id

    LEFT JOIN {{ ref('stg_location') }} l
        ON bo.ip_address = l.ip_address

)

SELECT * FROM order_final