WITH source_order AS (
    -- Lấy tất cả checkout_success events
    SELECT *
    FROM {{ source('glamira', 'glamira_raw') }}
    WHERE collection = 'checkout_success'
),

stg_order_unnest AS (
    -- Flatten cart_products
    SELECT
        CAST(CAST(order_id AS FLOAT64) AS INT64) AS order_id,
        SAFE_CAST(user_id_db AS INT64) AS user_id_db,
        LOWER(email_address) AS email_address,
        CAST(CAST(store_id AS FLOAT64) AS INT64) AS store_id,
        ip AS ip_address,
        CAST(FORMAT_DATE('%Y%m%d', DATE(TIMESTAMP_SECONDS(time_stamp))) AS INT64) AS date_id,
        PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', local_time) AS local_time,
        CAST(cp.product_id AS INT64) AS product_id,
        
        -- Normalize currency_code
        CASE TRIM(REGEXP_REPLACE(cp.currency, CONCAT('[', CHR(8206), CHR(8207), CHR(1564), ']'), ''))
            WHEN '€' THEN 'EUR'
            WHEN '£' THEN 'GBP'
            WHEN 'CHF' THEN 'CHF'
            WHEN 'kr' THEN 'SEK'
            WHEN '₺' THEN 'TRY'
            WHEN '￥' THEN 'JPY'
            WHEN 'R$' THEN 'BRL'
            WHEN 'AU $' THEN 'AUD'
            WHEN 'SGD $' THEN 'SGD'
            WHEN 'CAD $' THEN 'CAD'
            WHEN '$' THEN 'USD'
            WHEN 'Kč' THEN 'CZK'
            WHEN 'Ft' THEN 'HUF'
            WHEN 'HKD $' THEN 'HKD'
            WHEN 'zł' THEN 'PLN'
            WHEN 'din.' THEN 'RSD'
            WHEN '₫' THEN 'VND'
            WHEN 'kn' THEN 'HRK'
            WHEN 'NZD $' THEN 'NZD'
            WHEN 'MXN $' THEN 'MXN'
            WHEN '₹' THEN 'INR'
            WHEN 'лв.' THEN 'BGN'
            WHEN 'BOB Bs' THEN 'BOB'
            WHEN 'COP $' THEN 'COP'
            WHEN 'CRC ₡' THEN 'CRC'
            WHEN 'USD $' THEN 'USD'
            WHEN 'GTQ Q' THEN 'GTQ'
            WHEN 'PEN S/.' THEN 'PEN'
            WHEN 'DOP $' THEN 'DOP'
            WHEN 'CLP' THEN 'CLP'
            WHEN '₱' THEN 'PHP'
            WHEN 'Lei' THEN 'RON'
            WHEN 'UYU' THEN 'UYU'
            WHEN '₲' THEN 'PYG'
            WHEN 'د.ك.' THEN 'KWD'
            WHEN '' THEN 'USD'
            ELSE COALESCE(cp.currency,'USD')
        END AS currency_code,
        REGEXP_REPLACE(cp.price, r'[^\x20-\x7E]', '') AS raw_price,
        CAST(cp.amount AS INT64) AS quantity
    FROM source_order so
    CROSS JOIN UNNEST(so.cart_products) AS cp
),

price_normalized AS (
    -- Normalize price string
    SELECT
        COALESCE(sou.user_id_db, -1) AS user_id_db,
        sou.email_address,
        sou.ip_address,
        sou.date_id,
        sou.store_id,
        sou.product_id,
        sou.order_id,
        sou.local_time,
        sou.currency_code,
        sou.raw_price,
        sou.quantity,
        CAST(
            CASE
                WHEN TRIM(sou.raw_price) = '' THEN NULL
                WHEN REGEXP_CONTAINS(raw_price, r',\d{2}$') THEN REPLACE(REGEXP_REPLACE(sou.raw_price, r"[.\' ]", ''),',', '.')
                WHEN REGEXP_CONTAINS(sou.raw_price, r'\.\d{2}$') THEN REGEXP_REPLACE(sou.raw_price, r"[,\']", '')
            END AS NUMERIC
        ) AS raw_price_num,
        fx.rate_to_usd
    FROM stg_order_unnest sou
    LEFT JOIN {{ ref('dim_fx_rate') }} fx
        ON sou.currency_code = fx.currency_code
),



customer_per_order AS (
    -- Dedup customer per order
    SELECT
        order_id,
        user_id_db,
        email_address,
        store_id,
        ip_address,
        date_id,
        local_time,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY local_time
        ) AS rn
    FROM price_normalized
),

order_per_customer AS (
    -- order per customer after dedup
    SELECT
        order_id,
        user_id_db,
        email_address,
        store_id,
        ip_address,
        date_id,
        local_time
    FROM customer_per_order
    WHERE rn = 1
),

product_metrics AS (
    -- Final metrics per product per order
    SELECT
        order_id,
        product_id,
        currency_code,
        SUM(ROUND(COALESCE(raw_price_num,0) * rate_to_usd, 2) * quantity) / SUM(quantity) AS avg_raw_price,
        SUM(quantity) AS total_quantity,
        SUM(ROUND(COALESCE(raw_price_num,0) * rate_to_usd, 2) * quantity) AS total_amount
    FROM price_normalized
    GROUP BY order_id, product_id, currency_code
)

-- Final table: order × product
SELECT
    oc.order_id,
    oc.date_id,
    oc.user_id_db,
    oc.email_address,
    oc.store_id,
    oc.ip_address,
    oc.local_time,
    pm.product_id,
    pm.currency_code,
    pm.total_quantity AS quantity,
    pm.avg_raw_price AS price,
    pm.total_amount AS revenue
FROM product_metrics pm 
JOIN order_per_customer oc
    ON pm.order_id = oc.order_id