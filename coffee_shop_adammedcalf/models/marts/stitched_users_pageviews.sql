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
),


-- Replace all visitor_ids for a customer with the first one they used

stitched_user_pageviews AS (

SELECT pv.* EXCEPT(visitor_id),
IFNULL(avids.first_visitor_id, pv.visitor_id) AS visitor_id

FROM {{ ref('stg_pageviews') }} pv

LEFT JOIN all_visitor_ids_for_customer avids
ON pv.visitor_id = avids.visitor_id

),

-- mark which records correspond to a session start
mark_session_starts AS (

SELECT *,

CASE 
  WHEN LAG(timestamp, 1) OVER (PARTITION BY visitor_id ORDER BY timestamp) IS NULL THEN 1 -- first visit for a user 
  WHEN TIMESTAMP_DIFF(timestamp, LAG(timestamp, 1) OVER (PARTITION BY visitor_id ORDER BY timestamp) , MINUTE) > 30 THEN 1 -- has been a gap of at least 30 minutes since last visit
  ELSE 0 -- must be a continuation of a previous session 
END AS new_session_start

FROM stitched_user_pageviews

)

-- add a session ID based on the session starts

SELECT * EXCEPT(new_session_start),
SUM(new_session_start) OVER (PARTITION BY visitor_id ORDER BY timestamp) AS session_id

FROM mark_session_starts

ORDER BY visitor_id, timestamp