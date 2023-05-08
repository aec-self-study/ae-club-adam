-- Get the chronologically first ever known visitor ID for a customer

WITH first_visitor_id_for_customer AS (
  SELECT customer_id, visitor_id
  FROM  {{ ref('stg_pageviews') }}
  
WHERE customer_id IS NOT NULL

  QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY timestamp) = 1 
),

-- Make a table listing all known visitor IDs for a customer, and their first one from the CTE above
all_visitor_ids_for_customer AS
(
SELECT DISTINCT page_views.customer_id,
page_views.visitor_id,
fvid.visitor_id AS first_visitor_id

FROM {{ ref('stg_pageviews') }} page_views

JOIN first_visitor_id_for_customer fvid
ON fvid.customer_id = page_views.customer_id 

WHERE page_views.customer_id IS NOT NULL
)

SELECT pv.* EXCEPT(visitor_id),
IFNULL(avids.first_visitor_id, pv.visitor_id) AS visitor_id

FROM {{ ref('stg_pageviews') }} pv

LEFT JOIN all_visitor_ids_for_customer avids
ON pv.visitor_id = avids.visitor_id

ORDER BY timestamp