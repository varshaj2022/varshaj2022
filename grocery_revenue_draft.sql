 
 with stripe_txn as (
 
 select bt.type as stripe_type,
             CASE bt.type
            WHEN 'charge'
                THEN 
                    CASE
                        WHEN regexp_replace(bt.description,'[^[:digit:]]') IS NULL OR regexp_replace(bt.description,'[^[:digit:]]') ='' THEN 'No Order'
                    ELSE regexp_replace(bt.description,'[^[:digit:]]') END
	        WHEN 'refund'
                THEN
                    CASE
			            WHEN regexp_replace(bt.description,'[^[:digit:]]') IS NULL OR regexp_replace(bt.description,'[^[:digit:]]') ='' THEN 'No Order'
                        ELSE regexp_replace(bt.description,'[^[:digit:]]') END
	        WHEN 'adjustment'
                THEN
                    CASE
                        WHEN  regexp_replace(bt.description,'[^[:digit:]]') ='' THEN 'No Order'
                    ELSE regexp_replace(bt.description,'[^[:digit:]]') END
            WHEN 'transfer'
                THEN
                    CASE
                        WHEN regexp_replace(schtr.description,'[^[:digit:]]') IS NULL OR regexp_replace(bt.description,'[^[:digit:]]') ='' THEN 'No Order'
  			    ELSE regexp_replace(schtr.description,'[^[:digit:]]') END
            ELSE 'No Order' END as order_number,round(bt.amount*.01,2) as balance_amount,
            CASE
  		        WHEN sm.key = 'included_tip_amount' THEN sm.value
  			        ELSE NULL END as included_tip
           from 
            SHARE_STRIPE.STRIPE.BALANCE_TRANSACTIONS bt
            LEFT JOIN
            SHARE_STRIPE.STRIPE.CHARGES sch
                   ON 
                   bt.id = sch.balance_transaction_id
           LEFT JOIN
            SHARE_STRIPE.STRIPE.CHARGES schtr
            ON
            schtr.transfer_id = bt.source_id
         LEFT JOIN 
                SHARE_STRIPE.STRIPE.CHARGES_METADATA sm
                ON sm.Charge_id = sch.id 
                and bt.type = 'charge')
  
   
    
   
   select * from stripe_txn limit 100;
   
   --DETAILS FOR CHARGES ND GROCERY
   
   
   SHARE_STRIPE.STRIPE.CHARGES sch
            ;
