{% set category_types = ['coffee beans', 'merch', 'brewing supplies'] %}

select
  date_trunc(week, month) as date_month,  

  {% for category_type in category_types %}
  sum(case when product_category = '{{ category_type | replace(" ", "_") }}' then revenue end) as {{ category_type | replace(" ", "_")  }}_amount
  {% if not loop.last %},{% endif %}
  {% endfor %}

from  {{ ref('revenue_weekly') }}

group by 1