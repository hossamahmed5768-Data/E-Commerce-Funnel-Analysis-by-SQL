select *
from user_events;

-- define sales funnel
with funnel_stages as (
select count(distinct case when event_type = 'page_view' then user_id end) as page_view_stage,
count(distinct case when event_type = 'add_to_cart' then user_id end) as add_to_cart_stage,
count(distinct case when event_type = 'checkout_start' then user_id end) as checkout_start_stage,
count(distinct case when event_type = 'payment_info' then user_id end) as payment_info_stage,
count(distinct case when event_type = 'purchase' then user_id end) as purchase_stage

from user_events
)

select *
from funnel_stages;

-- conversion rates through funnels
with funnel_stages as (
select count(distinct case when event_type = 'page_view' then user_id end) as page_view_stage,
count(distinct case when event_type = 'add_to_cart' then user_id end) as add_to_cart_stage,
count(distinct case when event_type = 'checkout_start' then user_id end) as checkout_start_stage,
count(distinct case when event_type = 'payment_info' then user_id end) as payment_info_stage,
count(distinct case when event_type = 'purchase' then user_id end) as purchase_stage

from user_events
)

select 
page_view_stage, 
add_to_cart_stage,
round(add_to_cart_stage * 100 / page_view_stage) as view_to_cart_rate,

checkout_start_stage,
round(checkout_start_stage * 100 / add_to_cart_stage) as cart_to_checkout_rate,

payment_info_stage,
round(payment_info_stage * 100 / checkout_start_stage) as checkout_to_payment_rate,

purchase_stage,
round(purchase_stage * 100 / payment_info_stage) as payment_to_purchase_rate,

round(purchase_stage * 100 / page_view_stage) as overall_conversion_rate

from funnel_stages;

-- funnel by source

with source_funnel as (
select
traffic_source,
count(distinct case when event_type = 'page_view' then user_id end) as views,
count(distinct case when event_type = 'add_to_cart' then user_id end) as carts,
count(distinct case when event_type = 'purchase' then user_id end) as purchases

from user_events
group by traffic_source
)

select traffic_source,
views, carts, purchases,  
round(carts * 100 / views) as cart_conversion_rate,
round(purchases * 100 / carts) as purchase_conversion_rate,
round(purchases * 100 / views) as overall_conversion_rate
from source_funnel 
order by purchases desc;


-- time to conversion analysis

with user_journey as (
select
user_id,
min(case when event_type = 'page_view' then event_date end) as view_time,
min(case when event_type = 'add_to_cart' then event_date end) as cart_time,
min(case when event_type = 'purchase' then event_date end) as purchase_time

from user_events
group by user_id
having min(case when event_type = 'purchase' then event_date end) is not null
)

select count(*) as converted_users,
ROUND(AVG(TIMESTAMPDIFF(MINUTE, view_time, cart_time)),2) as avg_view_to_cart_time,
ROUND(AVG(TIMESTAMPDIFF(MINUTE, cart_time, purchase_time)),2) as avg_cart_to_purchase_time,
ROUND(AVG(TIMESTAMPDIFF(MINUTE, view_time, purchase_time)),2) as avg_view_to_purchase_time
from user_journey;


-- revenue funnel analysis

with funnel_revenue as (
select
count(distinct case when event_type = 'page_view' then user_id end) as total_visitors,
count(distinct case when event_type = 'purchase' then user_id end) as total_buyers,
sum(case when event_type = 'purchase' then amount end) as total_revenue,
count(case when event_type = 'purchase' then 1 end) as total_orders

from user_events
)
select total_visitors, total_buyers, total_revenue, total_orders,
total_revenue / total_orders as avg_order_value,
total_revenue / total_buyers as revenue_per_buyer,
total_revenue / total_visitors as revenue_per_visitor
from funnel_revenue