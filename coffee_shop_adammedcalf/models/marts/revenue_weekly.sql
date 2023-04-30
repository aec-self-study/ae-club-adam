WITH order_data AS
   (
    
    SELECT
      oi.order_item_id
      , o.order_id
      , o.created_at AS order_created_date
      , p.name AS product_name
      , p.category AS product_category
      , o.customer_id
      , IF (o.created_at > c.first_order_at, 'Returning', 'New') AS customer_type
      , pp.price
    
    FROM  {{ ref('stg_order_items') }}  oi
    
    LEFT JOIN  {{ ref('stg_orders') }}  o
    ON o.order_id = oi.order_id
    
    LEFT JOIN  {{ ref('stg_products') }}  p
    ON p.product_id = oi.product_id
    
    LEFT JOIN  {{ ref('customers')}} c
    ON c.customer_id = o.customer_id
    
    LEFT JOIN  {{ ref('stg_product_prices') }}  pp
    ON pp.product_id = oi.product_id
    AND o.created_at BETWEEN pp.created_at AND pp.ended_at
    
    ORDER BY customer_id
  
  )

SELECT
  date_trunc (order_created_date, week) AS week
  , product_category
  , customer_type
  , SUM (price) AS revenue

FROM order_data

GROUP BY 1, 2, 3