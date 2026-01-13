-- << Customer purchase behavior >> 
-- repeat vs one time customers
SELECT 
	customer_type, 
    COUNT(*) AS customer_count
FROM (
	SELECT customer_id, 
	CASE
		WHEN COUNT(transaction_id) = 1 THEN 'one-time'
        ELSE 'repeat'
	END AS customer_type
	FROM transactions
    WHERE refund_flag = 0
    GROUP BY customer_id
    ) AS sub
    GROUP BY customer_type; 

-- average revenue per customer
SELECT SUM(gross_revenue)/COUNT(DISTINCT customer_id) as avg_revenue_per_customer, customer_id
FROM transactions
WHERE refund_flag = 0
GROUP BY customer_id;

-- Days fromsignup to first purchase
SELECT c.customer_id, DATEDIFF(DATE(t.transaction_ts), c.signup_date) AS days_to_first_purchace
FROM customers c
JOIN transactions t ON c.customer_id = t.customer_id
GROUP BY c.customer_id; 

-- revenue by campaign
SELECT c.campaign_id, c.channel, SUM(t.gross_revenue) as total_revenue
FROM campaigns c 
LEFT JOIN transactions t ON c.campaign_id = t.campaign_id AND refund_flag = 0
GROUP BY c.campaign_id, c.channel
ORDER BY total_revenue DESC;

-- transactions per campaign
SELECT campaign_id, COUNT(*) AS transaction_count
FROM transactions
GROUP BY campaign_id
ORDER BY transaction_count DESC;

-- campaign conversion rate (sessions to purchase)
SELECT
    e.campaign_id,
    COUNT(DISTINCT e.session_id) AS sessions,
    COUNT(DISTINCT t.transaction_id) AS purchases,
    COUNT(DISTINCT t.transaction_id) 
        / COUNT(DISTINCT e.session_id) AS conversion_rate
FROM events e
LEFT JOIN transactions t
    ON e.customer_id = t.customer_id
    AND DATE(e.events_ts) = DATE(t.transaction_ts)
    AND t.refund_flag = 0
WHERE e.campaign_id IS NOT NULL
GROUP BY e.campaign_id;

-- sessions by traffic source
SELECT traffic_source, COUNT(DISTINCT session_id) AS session_count
FROM events
GROUP BY traffic_source
ORDER BY session_count DESC; 

-- revenue by traffic source
SELECT e.traffic_source, SUM(t.gross_revenue) AS total_revenue
FROM events e
JOIN transactions t ON e.customer_id = t.customer_id
	AND DATE(e.events_ts) = DATE(t.transaction_ts)
WHERE t.refund_flag = 0
GROUP BY e.traffic_source
ORDER BY total_revenue DESC;

-- device performace (sessions + revenue)
SELECT e.device_type, COUNT(DISTINCT e.session_id) as sessions, SUM(t.gross_revenue) AS revenue
FROM events e
LEFT JOIN transactions t ON e.customer_id = t.customer_id
	AND DATE(e.events_ts) = DATE(t.transaction_ts)
    AND t.refund_flag = 0 
GROUP BY e.device_type;

-- product view to purchase conversion
SELECT
    e.product_id,
    COUNT(DISTINCT e.session_id) AS view_sessions,
    COUNT(DISTINCT t.transaction_id) AS purchases,
    COUNT(DISTINCT t.transaction_id) 
        / COUNT(DISTINCT e.session_id) AS conversion_rate
FROM events e
LEFT JOIN transactions t
    ON e.customer_id = t.customer_id
    AND e.product_id = t.product_id
    AND t.refund_flag = 0
WHERE e.event_type = 'view'
GROUP BY e.product_id
HAVING COUNT(DISTINCT e.session_id) > 100
ORDER BY conversion_rate DESC;

-- revenue by loyalty tier
SELECT
    c.loyalty_tier,
    SUM(t.gross_revenue) AS total_revenue,
    COUNT(DISTINCT t.customer_id) AS customers
FROM customers c
JOIN transactions t
    ON c.customer_id = t.customer_id
WHERE t.refund_flag = 0
GROUP BY c.loyalty_tier
ORDER BY total_revenue DESC;

-- discount impact
SELECT
    CASE 
        WHEN discount_applied > 0 THEN 'Discounted'
        ELSE 'No Discount'
    END AS discount_type,
    COUNT(*) AS transactions,
    SUM(gross_revenue) AS revenue
FROM transactions
WHERE refund_flag = 0
GROUP BY discount_type;




