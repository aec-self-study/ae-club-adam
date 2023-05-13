WITH first_order_per_customer AS
   (
    SELECT
      customer_id
      , CAST (first_order_at AS DATE) AS first_order_at
    FROM {{ ref('customers')}}
  )
  , all_dates AS
   (-- all the potential dates customers may have had orders for, 2021-01-01 is the first order
    SELECT
      DATE
    
    FROM UNNEST (generate_date_array ('2021-01-01', CURRENT_DATE(), interval 1 DAY)) AS DATE
  
  )
  , all_dates_per_customer AS -- this should be all the dates from the customer's first order until today
   (
    SELECT
      c.customer_id
      , c.first_order_at
      , d.date
      , CAST (floor (DATE_DIFF (d.date, c.first_order_at, DAY) / 7) AS int64) AS week
    FROM first_order_per_customer c
    
    CROSS JOIN all_dates d
    
    WHERE d.date >= c.first_order_at
  
  )
  , revenue_per_customer_per_week AS -- allocate the revenue each customer provided each week, summing up multiple orders in the same week if necessary
  
   (
    
    SELECT
      c.customer_id
      , c.week
      , SUM (IFNULL (o.total, 0)) AS revenue
    
    FROM all_dates_per_customer c
    
    LEFT JOIN {{ ref('stg_orders')}} o
      ON o.customer_id = c.customer_id
      AND CAST (o.created_at AS DATE) = c.date
    
    GROUP BY 1, 2
  
  )
  , cumulative_revenue_per_customer_per_week AS -- add a cumulative measure of revenue
   (
    
    SELECT
      *
      , SUM (revenue) OVER
                            (
                             PARTITION BY customer_id
                             ORDER BY week
                           )
      AS cumulative_revenue
    
    FROM revenue_per_customer_per_week
  )

SELECT * FROM cumulative_revenue_per_customer_per_week

