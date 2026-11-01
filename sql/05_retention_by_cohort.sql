-- 05_retention_by_cohort.sql
-- Business question: What share of each weekly signup cohort comes back on day 1 and day 7?
-- "Active" = at least one event on that calendar day.
-- Signups run from 2026-01-01 to 2026-03-01 and events until 2026-03-31, so day 7 is observable for every cohort.
-- The first cohort week (starting 2025-12-29) is partial: it only contains signups from Jan 1 to Jan 4.

WITH activity AS (
    SELECT DISTINCT user_id, DATE(event_timestamp) AS active_date
    FROM events_clean
),
cohort AS (
    SELECT user_id,
           signup_date,
           -- Monday of the signup week (strftime %w: 0 = Sunday)
           DATE(signup_date, '-' || ((CAST(strftime('%w', signup_date) AS INTEGER) + 6) % 7) || ' days') AS cohort_week
    FROM users_clean
)
SELECT c.cohort_week,
       COUNT(*)                                                     AS cohort_users,
       ROUND(100.0 * COUNT(DISTINCT d1.user_id) / COUNT(*), 1)      AS d1_retention_pct,
       ROUND(100.0 * COUNT(DISTINCT d7.user_id) / COUNT(*), 1)      AS d7_retention_pct
FROM cohort c
LEFT JOIN activity d1 ON d1.user_id = c.user_id AND d1.active_date = DATE(c.signup_date, '+1 day')
LEFT JOIN activity d7 ON d7.user_id = c.user_id AND d7.active_date = DATE(c.signup_date, '+7 day')
GROUP BY c.cohort_week
ORDER BY c.cohort_week;
