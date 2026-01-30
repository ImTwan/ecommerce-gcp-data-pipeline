WITH calendar AS (
    SELECT
        day AS date_full
    FROM UNNEST(
        GENERATE_DATE_ARRAY('2015-01-01', '2035-12-31')
    ) AS day
), 
date_format AS(
    SELECT
        CAST(FORMAT_DATE('%Y%m%d', date_full) AS INT64) AS date_id, 
        date_full, 
        FORMAT_DATE('%A', date_full) AS day_of_week,  
        CASE
            WHEN EXTRACT(DAYOFWEEK FROM date_full) IN (1, 7)
            THEN TRUE
            ELSE FALSE
        END AS is_weekend, 
        EXTRACT(DAY FROM date_full) AS day_of_month,            
        DATE_TRUNC(date_full, MONTH) AS year_month,   
        EXTRACT(MONTH FROM date_full) AS month,       
        EXTRACT(DAYOFYEAR FROM date_full) AS day_of_year,  
        EXTRACT(WEEK FROM date_full) AS week_of_year,      
        CONCAT('Q', CAST(EXTRACT(QUARTER FROM date_full) AS STRING)) AS quarter_number,  
        DATE_TRUNC(date_full, YEAR) AS year,  
        EXTRACT(YEAR FROM date_full) AS year_number  
    FROM calendar
)
SELECT * FROM date_format ORDER BY date_full