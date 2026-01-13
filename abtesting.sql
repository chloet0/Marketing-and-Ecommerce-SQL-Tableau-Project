-- << A/B testing >>
-- sanity check
SELECT
    experiment_group,
    COUNT(DISTINCT session_id) AS sessions
FROM events
WHERE experiment_group IN ('Control', 'Variant_A', 'Variant_B')
GROUP BY experiment_group;

-- session to purchase conversion rate
WITH session_variants AS (
    SELECT DISTINCT
        session_id,
        experiment_group,
        customer_id
    FROM events
    WHERE experiment_group IN ('Control', 'Variant_A', 'Variant_B')
),
session_purchases AS (
    SELECT DISTINCT
        e.session_id
    FROM events e
    JOIN transactions t
        ON e.customer_id = t.customer_id
    WHERE t.refund_flag = 0
)
SELECT
    sv.experiment_group,
    COUNT(DISTINCT sv.session_id) AS total_sessions,
    COUNT(DISTINCT sp.session_id) AS converted_sessions,
    COUNT(DISTINCT sp.session_id)
        / COUNT(DISTINCT sv.session_id) AS conversion_rate
FROM session_variants sv
LEFT JOIN session_purchases sp
    ON sv.session_id = sp.session_id
GROUP BY sv.experiment_group;

-- revenue per session
WITH session_variants AS (
    SELECT DISTINCT
        session_id,
        experiment_group,
        customer_id
    FROM events
    WHERE experiment_group IN ('Control', 'Variant_A', 'Variant_B')
)
SELECT
    sv.experiment_group,
    SUM(t.gross_revenue) / COUNT(DISTINCT sv.session_id) AS revenue_per_session
FROM session_variants sv
LEFT JOIN transactions t
    ON sv.customer_id = t.customer_id
    AND t.refund_flag = 0
GROUP BY sv.experiment_group;

-- average order value by variant
SELECT
    e.experiment_group,
    SUM(t.gross_revenue) / COUNT(DISTINCT t.transaction_id) AS avg_order_value
FROM events e
JOIN transactions t
    ON e.customer_id = t.customer_id
WHERE e.experiment_group IN ('Control', 'Variant_A', 'Variant_B')
  AND t.refund_flag = 0
GROUP BY e.experiment_group;

-- conversion rate by experiement group
WITH session_level AS (
    SELECT
        e.experiment_group,
        e.session_id,
        MAX(CASE WHEN t.transaction_id IS NOT NULL THEN 1 ELSE 0 END) AS converted
    FROM events e
    LEFT JOIN transactions t
        ON e.customer_id = t.customer_id
        AND DATE(e.events_ts) = DATE(t.transaction_ts)
    WHERE e.event_type = 'view'
    GROUP BY e.experiment_group, e.session_id
)
SELECT
    experiment_group,
    COUNT(*) AS total_sessions,
    SUM(converted) AS converted_sessions,
    ROUND(SUM(converted) / COUNT(*) * 100, 2) AS conversion_rate_pct
FROM session_level
GROUP BY experiment_group
ORDER BY conversion_rate_pct DESC;

-- lift vs control
WITH conversion_rates AS (
    SELECT
        experiment_group,
        SUM(converted) / COUNT(*) AS conversion_rate
    FROM (
        SELECT
            e.experiment_group,
            e.session_id,
            MAX(CASE WHEN t.transaction_id IS NOT NULL THEN 1 ELSE 0 END) AS converted
        FROM events e
        LEFT JOIN transactions t
            ON e.customer_id = t.customer_id
            AND DATE(e.events_ts) = DATE(t.transaction_ts)
        WHERE e.event_type = 'view'
        GROUP BY e.experiment_group, e.session_id
    ) s
    GROUP BY experiment_group
),

control AS (
    SELECT conversion_rate AS control_rate
    FROM conversion_rates
    WHERE experiment_group = 'Control'
)

SELECT
    cr.experiment_group,
    ROUND(cr.conversion_rate * 100, 2) AS conversion_rate_pct,
    ROUND(
        (cr.conversion_rate - c.control_rate) / c.control_rate * 100,
        2
    ) AS lift_vs_control_pct
FROM conversion_rates cr
CROSS JOIN control c
ORDER BY lift_vs_control_pct DESC;


