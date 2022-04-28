update report_info 
set report_columns = 
'stripe_type, stripe_order_number, stripe_balance_amount, stripe_grocery_rev_amt, order_id, source_created_at, delivered_at, status, customer_name, customer_id, stripe_customer_id, metro_id, store_id, store_name, requested_total, actual_total, credit, actual_subtotal, delivery_fee, service_fee, actual_tax, discount, cost, actual_tip, bag_fee, actual_deposit'
where table_name = 'grocery_revenue_workday_stg';