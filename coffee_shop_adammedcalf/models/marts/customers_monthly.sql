select extract(year FROM first_order_at) AS year,
extract(month FROM first_order_at) AS month,
count(1) AS customers
FROM {{ ref('customers')}}
GROUP BY 1, 2