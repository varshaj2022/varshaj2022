WITH dates as ( --set dates for applicable time period
    SELECT
        ?::date AS start_date,
        ?::date AS end_date
            ),
bal_trxn as (
	SELECT DISTINCT
		bt.id as transaction_id,
		COALESCE(sch.charge_id,sr.charge_id,sd.charge_id) as charge_id,
		COALESCE(sch.customer_id,sr.customer_id,sd.customer_id) as customer_id,
		COALESCE(schm.metro,srm.metro,sdm.metro,cusmch.metro,cusmr.metro,cusmd.metro) as metro,
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
                        WHEN regexp_replace(sd.description,'[^[:digit:]]') IS NULL OR regexp_replace(bt.description,'[^[:digit:]]') ='' THEN 'No Order'
                    ELSE regexp_replace(sd.description,'[^[:digit:]]') END
            WHEN 'transfer'
                THEN
                    CASE
                        WHEN regexp_replace(schtr.description,'[^[:digit:]]') IS NULL OR regexp_replace(bt.description,'[^[:digit:]]') ='' THEN 'No Order'
  			    ELSE regexp_replace(schtr.description,'[^[:digit:]]') END
            ELSE 'No Order' END as order_number,
		COALESCE(bt.type,bt.reporting_category) as stripe_type,
		COALESCE(sch.invoice_id,sr.invoice_id,sd.invoice_id) as invoice_id,
		CASE
			WHEN bt.type = 'charge'
  			THEN bt.description
    	WHEN bt.type = 'refund'
  			THEN bt.description
    	WHEN bt.type = 'adjustment'
  			THEN sd.description
		ELSE bt.description END as description,
		COALESCE(sch.statement_descriptor,sr.statement_descriptor,sd.statement_descriptor) as statement_descriptor,
  	    --COALESCE(sch.card_bin,sr.card_bin,sd.card_bin) as card_bin,
		CASE bt.type
    	WHEN 'charge' 
  			THEN
        	CASE
        		WHEN sch.invoice_id IS NOT NULL THEN 'CHARGE_MEMBERSHIP'
    	        WHEN sch.description LIKE '%Grocery Delivery Prepaid Card Gift Membership%' THEN 'CHARGE_BHN_MEMBERSHIP'
				WHEN bt.description LIKE '%Grocery Delivery Prepaid Card Gift Membership%' THEN 'CHARGE_BHN_MEMBERSHIP'
                WHEN bt.description LIKE '%Membership%' THEN 'CHARGE_MEMBERSHIP'
				WHEN sch.description LIKE '%Membership%' THEN 'CHARGE_MEMBERSHIP'
				WHEN bt.description LIKE '%remaining membership%' THEN 'CHARGE_MEMBERSHIP'
				WHEN sch.description LIKE '%remaining membership%' THEN 'CHARGE_MEMBERSHIP'
                WHEN bt.description LIKE '%membership%' THEN 'CHARGE_MEMBERSHIP'
				WHEN sch.description LIKE '%membership%' THEN 'CHARGE_MEMBERSHIP'
				WHEN bt.description LIKE '%monthly%' THEN 'CHARGE_MEMBERSHIP'
				WHEN sch.description LIKE '%monthly%' THEN 'CHARGE_MEMBERSHIP'
				WHEN bt.description LIKE '%annual%' THEN 'CHARGE_MEMBERSHIP'
				WHEN sch.description LIKE '%annual%' THEN 'CHARGE_MEMBERSHIP'
				WHEN bt.description LIKE '%Annual Mem%' THEN 'CHARGE_MEMBERSHIP'
				WHEN sch.description LIKE '%Annual Mem%' THEN 'CHARGE_MEMBERSHIP'
				WHEN bt.description LIKE '%Annual fee%' THEN 'CHARGE_MEMBERSHIP'
				WHEN sch.description LIKE '%Annual fee%' THEN 'CHARGE_MEMBERSHIP'
				WHEN bt.description LIKE '%annual fee%' THEN 'CHARGE_MEMBERSHIP'
                WHEN sch.description LIKE '%annual fee%' THEN 'CHARGE_MEMBERSHIP'       
                WHEN bt.description LIKE '%monthly fee%' THEN 'CHARGE_MEMBERSHIP'
                WHEN sch.description LIKE '%monthly fee%' THEN 'CHARGE_MEMBERSHIP'
                WHEN bt.description LIKE '%Monthly fee%' THEN 'CHARGE_MEMBERSHIP'
                WHEN sch.description LIKE '%Monthly fee%' THEN 'CHARGE_MEMBERSHIP'
                WHEN bt.description LIKE '%Balanc%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%Balanc%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%balanc%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%balanc%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%Rem Bal%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%Rem Bal%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%Remaining%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%Remaining%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%Grocery%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%Grocery%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%grocery%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%grocery%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%Groceries%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%Groceries%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%groceries%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%groceries%' THEN 'CHARGE_GROCERY'  
                WHEN bt.description LIKE '%Gratuity%' THEN 'CHARGE_TIP'
                WHEN sch.description LIKE '%Gratuity%' THEN 'CHARGE_TIP'
                WHEN bt.description LIKE '%grat%' THEN 'CHARGE_TIP'
                WHEN sch.description LIKE '%grat%' THEN 'CHARGE_TIP'
                WHEN bt.description LIKE '%Tip%' THEN 'CHARGE_TIP'
                WHEN bt.description LIKE '%tip%' THEN 'CHARGE_TIP'
                WHEN bt.description LIKE '%TIP%' THEN 'CHARGE_TIP'
                WHEN sch.description LIKE '%Tip%' THEN 'CHARGE_TIP'
                WHEN sch.description LIKE '%tip%' THEN 'CHARGE_TIP'
                WHEN bt.description LIKE '%Order%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%Order%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%order%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%order%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%orders%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%orders%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%Orders%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%Orders%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%Remain Bal%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%Remain Bal%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%order%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%order%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%remianing bal%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%remaining bal%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%Grocery%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%Tip%' THEN 'CHARGE_TIP'
                WHEN sch.statement_descriptor LIKE '%tip%' THEN 'CHARGE_TIP'
                WHEN sch.statement_descriptor LIKE '%TIP%' THEN 'CHARGE_TIP'
                WHEN sch.statement_descriptor LIKE '%gratuity%' THEN 'CHARGE_TIP'
                WHEN sch.statement_descriptor LIKE '%Gratuity%' THEN 'CHARGE_TIP'
                WHEN sch.statement_descriptor LIKE '%grat%' THEN 'CHARGE_TIP'
                WHEN sch.statement_descriptor LIKE '%Grat%' THEN 'CHARGE_TIP'
                WHEN sch.statement_descriptor LIKE '%Order%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%order%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%ORDER%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%Membershi%' THEN 'CHARGE_MEMBERSHIP'
                WHEN sch.statement_descriptor LIKE '%membershi%' THEN 'CHARGE_MEMBERSHIP'
                WHEN bt.description LIKE '%Gift credits%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%Gift credits%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%gift credits%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%gift credits%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%Shipt Credit Purchase%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE 'Shipt*Credit*Purchase' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%RB%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%RB%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%REMAINING BALANCE%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%REMAINING BALANCE%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%Bal%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%Bal%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%RemBal%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%RemBal%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%rembal%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%rembal%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%rem bal%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%rem bal%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%ORDER%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%ORDER%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%remaining%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%remaining%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%ord%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%ord%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%Ord%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%Ord%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%Rem%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%Rem%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%delivery%' THEN 'CHARGE_DELIVERY'
                WHEN sch.description LIKE '%delivery%' THEN 'CHARGE_DELIVERY'
                WHEN bt.description LIKE '%rem. bal.%' THEN 'CHARGE_GROCERY'
                WHEN sch.description LIKE '%rem. bal.%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%Remaining balan%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%Remaining Balan%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%RemainingBalan%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%remainingbalan%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%remaining bal%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%REMAINING BALAN%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%Rem. B%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%Balanc%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%balanc%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%rembal%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%RemBal%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%RB%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%rem bal%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%GRATUITY%' THEN 'CHARGE_TIP'
                WHEN sch.statement_descriptor LIKE '%REM BAL%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%remain%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%Remain%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%grocery%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%groceries%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%Remaining Bal%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%remainingbal%' THEN 'CHARGE_GROCERY'
                WHEN sch.statement_descriptor LIKE '%rem. bal.%' THEN 'CHARGE_GROCERY'
                WHEN bt.description LIKE '%Delivery Pass Purchase%' THEN 'CHARGE_DELIVERYPASS'
                WHEN bt.description LIKE '%Shipt Pass Purchase%' THEN 'CHARGE_DELIVERYPASS'
            ELSE 'CHARGE_OTHER' END
        		WHEN 'refund' THEN 
            	CASE
              	    WHEN sr.charge_amount = sr.refund_amount THEN
                	    CASE
                  	        WHEN sr.invoice_id IS NOT NULL THEN 'FULL_REFUND_MEMBERSHIP'
                            WHEN sr.description LIKE '%Grocery Delivery Prepaid Card Gift Membership%' THEN 'FULL_REFUND_BHN_MEMBERSHIP'
							WHEN bt.description LIKE '%Grocery Delivery Prepaid Card Gift Membership%' THEN 'FULL_REFUND_BHN_MEMBERSHIP'
							WHEN bt.description LIKE '%Delivery Pass Purchase%' THEN 'FULL_REFUND_DELIVERYPASS'
							WHEN bt.description LIKE '%Shipt Pass Purchase%' THEN 'FULL_REFUND_DELIVERYPASS'
							WHEN bt.description LIKE '%Gratuity%' THEN 'FULL_REFUND_TIP'
                            WHEN bt.description LIKE '%Tip%' THEN 'FULL_REFUND_TIP'
                            WHEN bt.description LIKE '%tip%' THEN 'FULL_REFUND_TIP'
                          	WHEN bt.description LIKE '%TIP%' THEN 'FULL_REFUND_TIP'
                            WHEN bt.description LIKE '%Membership%' THEN 'FULL_REFUND_MEMBERSHIP'
                            WHEN bt.description LIKE '%Subscription%' THEN 'FULL_REFUND_MEMBERSHIP'
                            WHEN bt.description LIKE '%Remaining Balance%' THEN 'FULL_REFUND_GROCERY'
                            WHEN bt.description LIKE '%Order%' THEN 'FULL_REFUND_GROCERY'
		                    WHEN bt.description LIKE '%Gift credits%' THEN 'FULL_REFUND_CREDITS'
                            WHEN bt.description LIKE '%gift credits%' THEN 'FULL_REFUND_CREDITS'
                          	WHEN bt.description LIKE '%Shipt Credit Purchase%' THEN 'FULL_REFUND_CREDITS'
                            WHEN sr.description LIKE '%Gift credits%' THEN 'FULL_REFUND_CREDITS'
                            WHEN sr.statement_descriptor LIKE '%Membership%' THEN 'FULL_REFUND_MEMBERSHIP'
                            WHEN sr.statement_descriptor LIKE '%Order%' THEN 'FULL_REFUND_GROCERY'
                            WHEN sr.statement_descriptor LIKE '%order%' THEN 'FULL_REFUND_GROCERY'
                            WHEN sr.statement_descriptor LIKE '%Gratuity%' THEN 'FULL_REFUND_TIP'
                            WHEN sr.statement_descriptor LIKE '%Tip%' THEN 'FULL_REFUND_TIP'
                            WHEN sr.statement_descriptor like '%tip%' THEN 'FULL_REFUND_TIP'
                          	WHEN sr.statement_descriptor like '%TIP%' THEN 'FULL_REFUND_TIP'
							WHEN sr.statement_descriptor like '%Grocery%' THEN 'FULL_REFUND_GROCERY'
                  	        WHEN sr.statement_descriptor like '%grocery%' THEN 'FULL_REFUND_GROCERY'
                          	WHEN sr.statement_descriptor like '%Groceries%' THEN 'FULL_REFUND_GROCERY'
                          	WHEN sr.statement_descriptor like '%groceries%' THEN 'FULL_REFUND_GROCERY'
                          	WHEN sr.statement_descriptor like '%RemBal%' THEN 'FULL_REFUND_GROCERY'
                          	WHEN sr.statement_descriptor like '%Rem Bal%' THEN 'FULL_REFUND_GROCERY'
                          	WHEN sr.statement_descriptor like '%Balan%' THEN 'FULL_REFUND_GROCERY'
                          	WHEN sr.statement_descriptor like '%balan%' THEN 'FULL_REFUND_GROCERY'
                          	WHEN sr.statement_descriptor like '%Balan%' THEN 'FULL_REFUND_GROCERY'
                          	WHEN sr.statement_descriptor like '%membershi%' THEN 'FULL_REFUND_MEMBERSHIP'
                          	WHEN sr.statement_descriptor like '%Membershi%' THEN 'FULL_REFUND_MEMBERSHIP'
                  	        WHEN sr.statement_descriptor like '%grat%' THEN 'FULL_REFUND_TIP'
                    	ELSE 'FULL_REFUND_OTHER' END
                    WHEN sr.charge_amount <> sr.refund_amount THEN
                    CASE
              	        WHEN sr.invoice_id IS NOT NULL THEN 'PARTIAL_REFUND_MEMBERSHIP'
						WHEN sr.description LIKE '%Grocery Delivery Prepaid Card Gift Membership%' THEN 'PARTIAL_REFUND_BHN_MEMBERSHIP'
						WHEN bt.description LIKE '%Grocery Delivery Prepaid Card Gift Membership%' THEN 'PARTIAL_REFUND_BHN_MEMBERSHIP'
						WHEN bt.description LIKE '%Membership%' THEN 'PARTIAL_REFUND_MEMBERSHIP'
                        WHEN bt.description LIKE '%membership%' THEN 'PARTIAL_REFUND_MEMBERSHIP'
                        WHEN bt.description LIKE '%Grocery Order%' THEN 'PARTIAL_REFUND_GROCERY'
                        WHEN bt.description LIKE '%Remaining Balance%' THEN 'PARTIAL_REFUND_GROCERY'
                        WHEN bt.description LIKE '%Gratuity%' THEN 'PARTIAL_REFUND_TIP'
                        WHEN bt.description LIKE '%Tip%' THEN 'PARTIAL_REFUND_TIP'
                        WHEN bt.description LIKE '%tip%' THEN 'PARTIAL_REFUND_TIP'
                        WHEN bt.description LIKE '%Order%' THEN 'PARTIAL_REFUND_GROCERY'
                        WHEN bt.description LIKE '%Gift credits%' THEN 'PARTIAL_REFUND_GROCERY'
				        WHEN bt.description LIKE '%gift credits%' THEN 'PARTIAL_REFUND_GROCERY'
						WHEN bt.description LIKE '%Shipt Credit Purchase%' THEN 'PARTIAL_REFUND_GROCERY'
						WHEN sr.description LIKE '%Gift credits%' THEN 'PARTIAL_REFUND_GROCERY'
                        WHEN sr.statement_descriptor LIKE '%Membership%' THEN 'PARTIAL_REFUND_MEMBERSHIP'
                        WHEN sr.statement_descriptor LIKE '%membership%' THEN 'PARTIAL_REFUND_MEMBERSHIP'
                        WHEN sr.statement_descriptor LIKE '%Order%' THEN 'PARTIAL_REFUND_GROCERY'
                        WHEN sr.statement_descriptor LIKE '%order%' THEN 'PARTIAL_REFUND_GROCERY'
                        WHEN sr.statement_descriptor LIKE '%Gratuity%' THEN 'PARTIAL_REFUND_TIP'
                        WHEN sr.statement_descriptor LIKE '%Tip%' THEN 'PARTIAL_REFUND_TIP'
                        WHEN sr.statement_descriptor LIKE '%tip%' THEN 'PARTIAL_REFUND_TIP'
                        WHEN sr.statement_descriptor LIKE '%TIP%' THEN 'PARTIAL_REFUND_TIP'
                        WHEN sr.statement_descriptor like '%Grocery%' THEN 'PARTIAL_REFUND_GROCERY'
                        WHEN sr.statement_descriptor like '%grocery%' THEN 'PARTIAL_REFUND_GROCERY'
                        WHEN sr.statement_descriptor like '%Groceries%' THEN 'PARTIAL_REFUND_GROCERY'
                        WHEN sr.statement_descriptor like '%groceries%' THEN 'PARTIAL_REFUND_GROCERY'
                        WHEN sr.statement_descriptor like '%RemBal%' THEN 'PARTIAL_REFUND_GROCERY'
                        WHEN sr.statement_descriptor like '%Rem Bal%' THEN 'PARTIAL_REFUND_GROCERY'
                        WHEN sr.statement_descriptor like '%Balan%' THEN 'PARTIAL_REFUND_GROCERY'
                        WHEN sr.statement_descriptor like '%balan%' THEN 'PARTIAL_REFUND_GROCERY'
                        WHEN sr.statement_descriptor like '%Balan%' THEN 'PARTIAL_REFUND_GROCERY'
                        WHEN sr.statement_descriptor like '%membershi%' THEN 'PARTIAL_REFUND_MEMBERSHIP'
                        WHEN sr.statement_descriptor like '%Membershi%' THEN 'PARTIAL_REFUND_MEMBERSHIP'
                        WHEN sr.statement_descriptor like '%grat%' THEN 'PARTIAL_REFUND_TIP'
                        WHEN bt.description LIKE '%Delivery Pass Purchase%' THEN 'PARTIAL_REFUND_DELIVERYPASS'
                        WHEN bt.description LIKE '%Shipt Pass Purchase%' THEN 'PARTIAL_REFUND_DELIVERYPASS'
                	ELSE 'PARTIAL_REFUND_OTHER' END
                ELSE
                    CASE
                  	    WHEN sr.invoice_id IS NOT NULL THEN 'REFUND_MEMBERSHIP'
						WHEN sr.description LIKE '%Grocery Delivery Prepaid Card Gift Membership%' THEN 'REFUND_BHN_MEMBERSHIP'
						WHEN bt.description LIKE '%Grocery Delivery Prepaid Card Gift Membership%' THEN 'REFUND_BHN_MEMBERSHIP'
                        WHEN bt.description LIKE '%Remaining Balance%' THEN 'REFUND_GROCERY'
                        WHEN bt.description LIKE '%Gratuity%' THEN 'REFUND_TIP'
                        WHEN bt.description LIKE '%Order%' THEN 'REFUND_GROCERY'
                        WHEN bt.description LIKE '%Membership%' THEN 'REFUND_MEMBERSHIP'
                   	ELSE 'REFUND_OTHER' END
        END
            WHEN 'adjustment' THEN
          	    CASE
					WHEN bt.description LIKE 'Chargeback withdrawal%' AND sd.invoice_id IS NOT NULL THEN 'DISPUTE_DEBIT_MEMBERSHIP'
					WHEN bt.description LIKE '%Chargeback withdrawal%' AND sd.description LIKE '%Grocery Delivery Prepaid Card Gift Membership%' THEN 'DISPUTE_DEBIT_BHN_MEMBERSHIP'
					WHEN bt.description LIKE 'Chargeback withdrawal%' AND sd.description LIKE '%Membership%' THEN 'DISPUTE_DEBIT_MEMBERSHIP'
					WHEN bt.description LIKE 'Chargeback withdrawal%' AND sd.description LIKE '%membership%' THEN 'DISPUTE_DEBIT_MEMBERSHIP'
					WHEN bt.description LIKE 'Chargeback withdrawal%' AND sd.description LIKE '%Shipt Pass Purchase%' THEN 'DISPUTE_CREDIT_DELIVERYPASS'
					WHEN bt.description LIKE 'Chargeback withdrawal%' AND sd.description LIKE '%Delivery Pass Purchase%' THEN 'DISPUTE_CREDIT_DELIVERYPASS'
					WHEN bt.description LIKE 'Chargeback reversal%' AND sd.description LIKE '%Shipt Pass Purchase%' THEN 'DISPUTE_DEBIT_DELIVERYPASS'
					WHEN bt.description LIKE 'Chargeback reversal%' AND sd.description LIKE '%Delivery Pass Purchase%' THEN 'DISPUTE_DEBIT_DELIVERYPASS'
					WHEN bt.description LIKE 'Chargeback withdrawal%' AND sd.description LIKE '%Gift credits%' THEN 'DISPUTE_DEBIT_GROCERY'
					WHEN bt.description LIKE 'Chargeback withdrawal%' AND sd.description LIKE '%gift credits%' THEN 'DISPUTE_DEBIT_GROCERY'
				    WHEN bt.description LIKE 'Chargeback withdrawal%' AND sd.description LIKE '%Shipt Credit Purchase%' THEN 'DISPUTE_DEBIT_GROCERY'
				    WHEN bt.description LIKE 'Chargeback reversal%' AND sd.invoice_id IS NOT NULL THEN 'DISPUTE_CREDIT_MEMBERSHIP'
					WHEN bt.description LIKE 'Adjustment of lost dispute%' AND sd.invoice_id IS NOT NULL THEN 'DISPUTE_CREDIT_MEMBERSHIP'
					WHEN bt.description LIKE '%Chargeback reversal%' AND sd.description LIKE '%Grocery Delivery Prepaid Card Gift Membership%' THEN 'DISPUTE_CREDIT_BHN_MEMBERSHIP'		
					WHEN bt.description LIKE 'Chargeback reversal%' AND sd.description LIKE '%Membership%' THEN 'DISPUTE_CREDIT_MEMBERSHIP'
					WHEN bt.description LIKE 'Chargeback reversal%' AND sd.description LIKE '%membership%' THEN 'DISPUTE_CREDIT_MEMBERSHIP'
					WHEN bt.description LIKE 'Chargeback reversal%' AND sd.description IS NOT NULL THEN 'DISPUTE_CREDIT_GROCERY'
					WHEN bt.description LIKE 'Chargeback reversal%' AND sd.description LIKE '%Gift credits%' THEN 'DISPUTE_CREDIT_GROCERY'
					WHEN bt.description LIKE 'Chargeback reversal%' AND sd.description LIKE '%gift credits%' THEN 'DISPUTE_CREDIT_GROCERY'
					WHEN bt.description LIKE 'Chargeback reversal%' AND sd.description LIKE '%Shipt Credit Purchase%' THEN 'DISPUTE_CREDIT_GROCERY'
					WHEN bt.description LIKE 'Chargeback withdrawal%' AND sd.description LIKE '%Shipt Grocery Order%' THEN 'DISPUTE_CREDIT_GROCERY'
					WHEN bt.description LIKE 'Chargeback withdrawal%' AND sd.description LIKE '%Shipt Gratuity%' THEN 'DISPUTE_CREDIT_TIP'
					WHEN bt.description LIKE 'Chargeback withdrawal%' AND sd.description LIKE '%Shipt Tip%' THEN 'DISPUTE_CREDIT_TIP'
					WHEN bt.description LIKE 'Chargeback withdrawal%' AND sd.description LIKE '%Shipt Remaining Balance%' THEN 'DISPUTE_CREDIT_GROCERY'
					WHEN bt.description LIKE 'Chargeback withdrawal%' AND sd.description LIKE '%External Order%' THEN 'DISPUTE_CREDIT_GROCERY'
					WHEN bt.description LIKE 'Chargeback withdrawal%' THEN 'DISPUTE_DEBIT_OTHER'
					WHEN bt.description LIKE 'Chargeback reversal%' THEN 'DISPUTE_CREDIT_OTHER'
					WHEN bt.description LIKE 'Adjustment of lost dispute%' AND sd.description IS NOT NULL THEN 'DISPUTE_CREDIT_GROCERY'
					WHEN bt.description LIKE 'IC-plus%' THEN 'ADJUSTMENT_INTERCHANGE_PLUS'
              	ELSE 'ADJUSTMENT_OTHER' END
			WHEN 'transfer' THEN
          	    CASE
            	    WHEN bt.type = 'transfer' THEN 'STRIPE_CONNECT_TRNSFR'
				ELSE 'STRIPE_CONNECT_OTHER' END
        WHEN NULL THEN
            CASE 
                WHEN bt.reporting_category LIKE 'other_adjustment' THEN 'ADJUSTMENT_OTHER' else UPPER(bt.reporting_category) END
            ELSE UPPER(bt.type)
        END AS transaction_type,
		ROUND((bt.amount*.01) - COALESCE((cast(schmtipamt.included_tip as integer)*.01),0),2) as grocery_amt,
  	    round(COALESCE((cast(schmtipamt.included_tip as integer)*.01),0),2) as included_tip_amount,
  	    round(bt.amount*.01,2) as balance_amount,
  	    round(-bt.fee*.01,2) as fee_amount,
  	    round(bt.net*.01,2) as net_amount,
        to_char(convert_timezone('America/Chicago',bt.created),'YYYY-MM-DD HH:MI:SS')::date AS bal_trxn_created_at,
        to_char(convert_timezone('America/Chicago',bt.available_on),'YYYY-MM-DD HH:MI:SS')::date AS bal_trxn_available_on,
		COALESCE(sch.customer_email,sr.customer_email,sd.customer_email) as customer_email
    FROM SHARE_STRIPE.STRIPE.BALANCE_TRANSACTIONS bt
    INNER JOIN dates
        ON 1=1
	LEFT JOIN ( --DETAILED CHARGE INFORMATION
  	    SELECT 
    	    sch.id as charge_id,
			sch.balance_transaction_id as balance_transaction_id,
    	    sch.customer_id as customer_id,
    	    c.email as customer_email,
    	    sch.invoice_id as invoice_id,
        	sch.amount as charge_amount,
        	sch.description as description,
        	sch.statement_descriptor as statement_descriptor,
        	sch.card_iin as card_bin,
        	sch.status as status,
        	sch.created as created_at,
        	sch.transfer_id,
        	ca.legal_entity_business_name
  	    FROM SHARE_STRIPE.STRIPE.CHARGES sch 
        LEFT JOIN SHARE_STRIPE.STRIPE.CUSTOMERS c
    	    ON c.id = sch.customer_id 
        LEFT JOIN SHARE_STRIPE.STRIPE.CONNECTED_ACCOUNT_CHARGES cac 
    	    ON cac.source_transfer_id = sch.transfer_id
		LEFT JOIN SHARE_STRIPE.STRIPE.CONNECTED_ACCOUNTS ca
    	    ON ca.id = cac.account
                    ) AS sch 
                    ON sch.balance_transaction_id = bt.id
                    AND bt.type = 'charge'
    LEFT JOIN ( --DETAILED REFUND INFORMATION (CHARGES JOINED TO REFUNDS)
        SELECT 
            sch.id as charge_id,
  	        sr.id as refund_id,
  	        sr.balance_transaction_id as balance_transaction_id,
  	        sch.invoice_id as invoice_id,
  	        sch.customer_id as customer_id,
  	        c.email as customer_email,
  	        sch.amount as charge_amount,
  	        sr.amount as refund_amount,
  	        sch.description as description,
  	        sch.statement_descriptor as statement_descriptor,
  	        sch.card_iin as card_bin,
  	        sr.status as status, sch.created as created_at,
  	        sch.transfer_id, 
  	        ca.legal_entity_business_name
        FROM SHARE_STRIPE.STRIPE.CHARGES sch
        INNER JOIN SHARE_STRIPE.STRIPE.REFUNDS sr
  	        ON sr.charge_id = sch.id 
        LEFT JOIN SHARE_STRIPE.STRIPE.CONNECTED_ACCOUNT_CHARGES cac
  	        ON cac.source_transfer_id = sch.transfer_id 
        LEFT JOIN SHARE_STRIPE.STRIPE.CONNECTED_ACCOUNTS ca
  	        ON ca.id = cac.account
	    LEFT JOIN SHARE_STRIPE.STRIPE.CUSTOMERS c
  	        ON c.id = sch.customer_id
                    ) AS sr
					ON sr.balance_transaction_id = bt.id
                    AND bt.type IN ('refund','refund_failure')
    LEFT JOIN ( --DETAILED DISPUTES DATA (Disputes => balance trxns => charges)
        SELECT 
  	        sd.id as dispute_id,
            sch.id as charge_id,
  	        sch.balance_transaction_id as balance_transaction_id,
  	        sch.customer_id as customer_id,
  	        c.email as customer_email,
  	        sch.invoice_id as invoice_id,
  	        sch.amount as charge_amount,
            sch.status as status,
  	        bt.description as bt_description,
  	        sch.description as description,
  	        sch.statement_descriptor as statement_descriptor,
            sch.card_iin as card_bin,
  	        sch.created as created_at,
  	        sch.transfer_id,
  	        ca.legal_entity_business_name
        FROM SHARE_STRIPE.STRIPE.DISPUTES sd
        INNER JOIN SHARE_STRIPE.STRIPE.BALANCE_TRANSACTIONS bt
  	        ON bt.source_id = sd.id 
        INNER JOIN SHARE_STRIPE.STRIPE.CHARGES sch 
  	        ON sch.id = sd.charge_id
        LEFT JOIN SHARE_STRIPE.STRIPE.CONNECTED_ACCOUNT_CHARGES cac
  	        ON cac.source_transfer_id = sch.transfer_id
        LEFT JOIN SHARE_STRIPE.STRIPE.CONNECTED_ACCOUNTS ca
  	        ON ca.id = cac.account
        LEFT JOIN SHARE_STRIPE.STRIPE.CUSTOMERS c
  	        ON c.id = sch.customer_id
                    ) AS sd 
    				ON sd.dispute_id = bt.source_id
                    AND bt.type = 'adjustment'
    LEFT JOIN ( --METRO FOR CHARGES [metadata]
        SELECT
  	        schm.charge_id as charge_id,
            schm.key as key,
  	        schm.value as metro
        FROM SHARE_STRIPE.STRIPE.CHARGES_METADATA schm
        WHERE
            schm.key = 'metro_name'
                ) AS schm
				ON schm.charge_id = sch.charge_id
                AND bt.type = 'charge'
    LEFT JOIN ( --METRO FOR REFUNDS [metadata]
        SELECT
  	        srm.charge_id as charge_id,
  	        srm.key as key,
  	        srm.value as metro
        FROM SHARE_STRIPE.STRIPE.CHARGES_METADATA srm
        WHERE
            srm.key = 'metro_name'
            ) AS srm
  					ON srm.charge_id = sr.charge_id
                    AND bt.type IN ('refund','refund_failure')
    LEFT JOIN ( --METRO FOR DISPUTES [metadata]
        SELECT
  	        sdm.charge_id as charge_id,
  	        sdm.key as key,
  	        sdm.value as metro
        FROM SHARE_STRIPE.STRIPE.CHARGES_METADATA sdm
        WHERE
            sdm.key = 'metro_name'
            ) AS sdm
  					ON sdm.charge_id = sd.charge_id
                    AND bt.type = 'adjustment'
    LEFT JOIN ( --METRO FOR CHARGES V2 - [metadata]
	    SELECT
  	        cusm.customer_id as customer_id,
  	        cusm.key as key,
  	        cusm.value as metro
        FROM SHARE_STRIPE.STRIPE.CUSTOMERS_METADATA cusm
        WHERE
            cusm.key = 'metro_name'
                    ) AS cusmch 
  					ON cusmch.customer_id = sch.customer_id
                    AND bt.type = 'charge'
    LEFT JOIN ( --METRO FOR REFUNDS - [metadata]
	    SELECT
  	        cusm.customer_id as customer_id,
  	        cusm.key as key,
  	        cusm.value as metro
        FROM SHARE_STRIPE.STRIPE.CUSTOMERS_METADATA cusm
        WHERE
            cusm.key = 'metro_name'
                ) AS cusmr
  				ON cusmr.customer_id = sr.customer_id
                AND bt.type IN ('refund','refund_failure')
    LEFT JOIN ( --METRO FOR DISPUTES - [metadata]
	    SELECT
  	        cusm.customer_id as customer_id,
  	        cusm.key as key,
  	        cusm.value as metro
        FROM SHARE_STRIPE.STRIPE.CUSTOMERS_METADATA cusm
        WHERE
            cusm.key = 'metro_name'
                    ) AS cusmd
  					ON cusmd.customer_id = sd.customer_id
                    AND bt.type = 'adjustment'
    LEFT JOIN ( --FLAG FOR TIP CONSOLIDATION [metadata]
        SELECT DISTINCT
  	        schmtip.charge_id,
  	        CASE
  		        WHEN schmtip.key = 'tip_included' THEN schmtip.value
  			        ELSE NULL END as tip_included
        FROM SHARE_STRIPE.STRIPE.CHARGES_METADATA schmtip
        WHERE
            schmtip.key = 'tip_included'
                    ) AS schmtip
  					ON schmtip.charge_id = sch.charge_id
                    AND bt.type = 'charge'
    LEFT JOIN ( --TIP AMOUNT IF THERE IS TIP CONSOLIDATION [metadata]
        SELECT DISTINCT
  	        schmtipamt.charge_id,
  	        CASE
  		        WHEN schmtipamt.key = 'included_tip_amount' THEN schmtipamt.value
  			        ELSE NULL END as included_tip
        FROM SHARE_STRIPE.STRIPE.CHARGES_METADATA schmtipamt
        WHERE
            (schmtipamt.key = 'included_tip_amount'
            AND schmtipamt.value IS NOT NULL)
                    ) AS schmtipamt
         			ON schmtipamt.charge_id = sch.charge_id
         			AND bt.type = 'charge'
    LEFT JOIN ( --DETAILED INFORMATION FOR TRANSFERS (alcohol)
        SELECT DISTINCT
            schtr.id as charge_id,
  	        schtr.balance_transaction_id as balance_transaction_id,
  	        schtr.customer_id as customer_id,
  	        schtr.invoice_id as invoice_id,
  	        schtr.amount as charge_amount,
  	        schtr.description as description,
  	        schtr.statement_descriptor as statement_descriptor,
  	        schtr.status as status,
  	        schtr.created as created_at,
  	        schtr.transfer_id,
  	        ca.legal_entity_business_name
        FROM SHARE_STRIPE.STRIPE.CHARGES schtr
        LEFT JOIN SHARE_STRIPE.STRIPE.CONNECTED_ACCOUNT_CHARGES cac
  	        ON cac.source_transfer_id = schtr.transfer_id
        LEFT JOIN SHARE_STRIPE.STRIPE.CONNECTED_ACCOUNTS ca
  	        ON ca.id = cac.account
                    ) AS schtr
    				ON schtr.transfer_id = bt.source_id
                    AND bt.type IN ('transfer')
    --NAME AND/OR BUSINESSES (FALL BACK)
    LEFT JOIN SHARE_STRIPE.STRIPE.TRANSFERS t
        ON t.id = bt.source_id
    WHERE
        stripe_type NOT IN ('payout','payout_cancel','payout_failure')
        AND bal_trxn_created_at::date BETWEEN dates.start_date AND dates.end_date
        AND transaction_type LIKE '%_GROCERY'
        AND order_number <> 'No Order'
        ),
    order_data as (
        SELECT
            o.id as order_id,
	        to_char(o.created_at - interval '5 hours', 'Mon DD') as source_created_at,
	        to_char(o.delivered_at - interval '5 hours', 'Mon DD yyyy ') as delivered_at,
        	o.status as status,
	        c.name as customer_name,
	        c.id as customer_id,
            c.metro_id as customer_metro_id,
	        c.stripe_customer_id as stripe_customer_id,
	        o.metro_id AS metro_id,
            o.store_id,
	        s.name as store_name,
	        o.requested_total as requested_total,
	        o.actual_total as actual_total,
	        o.credit as credit,
	        o.actual_subtotal as actual_subtotal,
            o.delivery_fee as delivery_fee,
	        o.service_fee as service_fee,
	        o.actual_tax as actual_tax,
	        o.discount as discount,
	        o.cost as cost,
	        o.actual_tip as actual_tip,
	        o.bag_fee as bag_Fee,
	        o.actual_deposit as actual_deposit
        FROM prd_datalakehouse.og_views.orders as o
        INNER JOIN dates
            ON 1=1
        left join prd_datalakehouse.og_views.credit_card_transactions as cct on o.id = cct.order_id and cct.transaction_type = 'ordercapture'
	    left join prd_datalakehouse.og_views.refunds as r on o.id = r.order_id
	    left join prd_datalakehouse.og_views.customers as c on o.customer_id = c.id
	    left join prd_datalakehouse.og_views.stores as s on o.store_id = s.id
        where 
            convert_timezone('America/Chicago',o.delivered_at)::date
                BETWEEN dates.end_date - interval '12 months' AND dates.end_date
            and o.status in ('delivered','processed')
            and o.is_external_platform_order = 'f' --excludes platform Orders
        group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23
                    )
SELECT
	bt.stripe_type,
    try_cast(bt.order_number as bigint) as stripe_order_number,
    bt.balance_amount as stripe_balance_amount,
    coalesce(bt.grocery_amt,0) as stripe_grocery_rev_amt,
     bal_trxn_created_at,
    od.order_id,
    od.source_created_at,
    od.delivered_at,
    od.status,
    od.customer_name,
    od.customer_id,
    od.stripe_customer_id,
    od.metro_id,
    od.store_id,
    od.store_name,
    od.requested_total,
    od.actual_total,
    od.credit,
    od.actual_subtotal,
    od.delivery_fee,
    case when m.state = 'CA' and od.service_fee > 0 then 
    od.service_fee-2.99 
    else 
    od.service_fee
    end as service_fee,
    od.actual_tax,
    od.discount,
    od.cost,
    od.actual_tip,
    od.bag_Fee,
    od.actual_deposit,
    transaction_id as key_id,
    case when m.state = 'CA'  and service_fee > 0 then 
    2.99
    else 0
    end
    as prop_22_fee
FROM bal_trxn bt
LEFT JOIN order_data od
    ON od.order_id = try_cast(bt.order_number as bigint)
left join og_views.metros m on od.customer_metro_id = m.id
 ORDER BY 1