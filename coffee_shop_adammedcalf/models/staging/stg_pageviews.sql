with source as (
    
    select * from {{ source('web_tracking', 'pageviews') }}
    
),

renamed as (
    
    select
        id as pageview_id,
        visitor_id,
        device_type,
        timestamp,
        page,
        customer_id

    from source

)

select * from renamed