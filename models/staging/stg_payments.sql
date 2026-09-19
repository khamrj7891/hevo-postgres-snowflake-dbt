select
    ID as payment_id,
    ORDER_ID as order_id,
    PAYMENT_METHOD as payment_method,
    AMOUNT as amount
from {{ source('raw', 'RAW_PAYMENTS') }}
