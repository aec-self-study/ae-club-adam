{{ config(
    materialized='table'
 ) }}

select
   customers.customer_id,
   customers.name,
   customers.email,
   min(orders.created_at) as first_order_at,
   count(orders.order_id) as number_of_orders

from {{ ref('stg_customers') }} customers

left join {{ ref('stg_orders') }} orders on customers.customer_id = orders.customer_id 

group by 1, 2, 3

order by first_order_at