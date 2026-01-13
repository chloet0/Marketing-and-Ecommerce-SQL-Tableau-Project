-- << transaction metrics >> 
-- total gross revenue excluding refunds
SELECT 
    ROUND(SUM(gross_revenue), 2)  AS total_gross_revenue
FROM transactions
WHERE refund_flag = 0;

-- total refunded transactions and refund rate; 2704, 0.0292
SELECT
	COUNT(*) AS refunded_transactions,
    COUNT(*) / (SELECT COUNT(*) FROM transactions) AS refund_rate
FROM transactions
WHERE refund_flag = 1; 

-- average order value AOV; 95.9196
SELECT 
	ROUND(AVG(gross_revenue), 4) AS average_order_value
FROM transactions
WHERE refund_flag = 0;

-- << product performace >> 
-- revenue by product category
SELECT 
	p.category,
    SUM(t.gross_revenue) AS category_revenue 
FROM transactions t
JOIN products p
	ON t.product_id = p.product_id
WHERE t.refund_flag = 0
GROUP BY p.category
ORDER BY category_revenue DESC;

-- top 10 products by revenue
SELECT p.product_id, ROUND(SUM(gross_revenue), 2) AS total_revenue
FROM transactions t
JOIN products p ON t.product_id = p.product_id
WHERE t.refund_flag = 0
GROUP BY t.product_id
ORDER BY total_revenue DESC
LIMIT 10;

-- premium vs non-premium revenue
SELECT p.is_premium, ROUND(SUM(t.gross_revenue), 2) AS total_revenue
FROM transactions t
JOIN products p ON p.product_id = t.product_id
WHERE t.refund_flag = 0
GROUP BY p.is_premium;

-- << customer overview metics >> 
-- customers by acquisition channel
SELECT acquisition_channel, COUNT(customer_id) AS customer_count
FROM CUSTOMERS
GROUP BY acquisition_channel
ORDER BY customer_count DESC;

-- Customers by loyalty tier
SELECT loyalty_tier, COUNT(customer_id) AS customer_count
FROM customers
GROUP BY loyalty_tier
ORDER BY customer_count DESC;

-- << event basics >> 
-- total events by event type
SELECT event_type, COUNT(event_id) AS event_count
FROM events
GROUP BY event_type
ORDER BY event_count DESC;

-- events by device type
SELECT device_type, COUNT(event_id) as event_count
FROM events
GROUP BY device_type
ORDER BY event_count DESC;

-- << campaign basics >>
-- transactions per campaign
SELECT campaign_id, COUNT(*) AS total_transactions
FROM transactions
GROUP BY campaign_id
ORDER BY total_transactions DESC;

-- revenue by campaign
SELECT campaign_id, ROUND(SUM(gross_revenue), 2) AS total_revenue
FROM transactions
WHERE refund_flag = 0
GROUP BY campaign_id
ORDER BY total_revenue DESC;


