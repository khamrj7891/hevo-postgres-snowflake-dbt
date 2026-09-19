{{ config(materialized='table') }}

with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

payments as (
    select * from {{ ref('stg_payments') }}
),

order_stats as (
    select
        customer_id,
        min(order_date) as first_order,
        max(order_date) as most_recent_order,
        count(order_id) as number_of_orders
    from orders
    group by customer_id
),

payment_stats as (
    select
        o.customer_id,
        sum(p.amount) as customer_lifetime_value
    from payments p
    left join orders o on p.order_id = o.order_id
    group by o.customer_id
)

select
    c.customer_id,
    c.first_name,
    c.last_name,
    os.first_order,
    os.most_recent_order,
    os.number_of_orders,
    coalesce(ps.customer_lifetime_value, 0) as customer_lifetime_value
from customers c
left join order_stats os on c.customer_id = os.customer_id
left join payment_stats ps on c.customer_id = ps.customer_id
