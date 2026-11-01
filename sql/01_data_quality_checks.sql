-- 01_data_quality_checks.sql
-- Business question: Can we trust the raw tables before we calculate any metric?
-- Each row is one validation rule. An issue_count above 0 means the rule found problems.

SELECT 'duplicate_events' AS check_name,
       COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT user_id, event_name, event_timestamp FROM events)) AS issue_count
FROM events

UNION ALL
SELECT 'orphan_events (user_id not in users)',
       COUNT(*)
FROM events e
LEFT JOIN users u ON u.user_id = e.user_id
WHERE u.user_id IS NULL

UNION ALL
SELECT 'events_before_signup',
       COUNT(*)
FROM events e
JOIN users u ON u.user_id = e.user_id
WHERE DATE(e.event_timestamp) < u.signup_date

UNION ALL
SELECT 'users_missing_country',
       COUNT(*)
FROM users
WHERE country IS NULL OR TRIM(country) = ''

UNION ALL
SELECT 'users_with_nonstandard_platform_value',
       COUNT(*)
FROM users
WHERE platform NOT IN ('iOS', 'Android')

UNION ALL
SELECT 'users_without_experiment_assignment',
       COUNT(*)
FROM users u
LEFT JOIN experiment_assignments a ON a.user_id = u.user_id
WHERE a.user_id IS NULL

UNION ALL
SELECT 'purchase_events_without_subscription_row',
       COUNT(DISTINCT e.user_id)
FROM events_clean e
LEFT JOIN subscriptions s ON s.user_id = e.user_id
WHERE e.event_name = 'purchase' AND s.user_id IS NULL

UNION ALL
SELECT 'subscriptions_without_purchase_event',
       COUNT(*)
FROM subscriptions s
WHERE NOT EXISTS (
    SELECT 1 FROM events_clean e
    WHERE e.user_id = s.user_id AND e.event_name = 'purchase'
);
