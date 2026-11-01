-- 04_funnel_by_segment.sql
-- Business question: Which acquisition channels and platforms convert best through the funnel?
-- Step 1: one row per user with 0/1 flags. Step 2: aggregate by segment.

WITH user_flags AS (
    SELECT u.user_id,
           u.acquisition_channel AS channel,
           u.platform,
           MAX(CASE WHEN e.event_name = 'onboarding_complete' THEN 1 ELSE 0 END) AS completed_onboarding,
           MAX(CASE WHEN e.event_name = 'paywall_view'        THEN 1 ELSE 0 END) AS saw_paywall,
           MAX(CASE WHEN e.event_name = 'trial_start'         THEN 1 ELSE 0 END) AS started_trial,
           MAX(CASE WHEN e.event_name = 'purchase'            THEN 1 ELSE 0 END) AS purchased
    FROM users_clean u
    LEFT JOIN events_clean e ON e.user_id = u.user_id
    GROUP BY u.user_id, u.acquisition_channel, u.platform
)
-- 4a. By acquisition channel
SELECT channel,
       COUNT(*)                                                         AS users,
       ROUND(100.0 * SUM(completed_onboarding) / COUNT(*), 1)           AS onboarding_complete_pct,
       ROUND(100.0 * SUM(started_trial) / NULLIF(SUM(saw_paywall), 0), 1) AS paywall_to_trial_pct,
       ROUND(100.0 * SUM(purchased) / NULLIF(SUM(started_trial), 0), 1)   AS trial_to_purchase_pct,
       ROUND(100.0 * SUM(purchased) / COUNT(*), 2)                      AS overall_conversion_pct
FROM user_flags
GROUP BY channel
ORDER BY overall_conversion_pct DESC;

-- 4b. By platform (same logic, grouped by platform instead of channel)
WITH user_flags AS (
    SELECT u.user_id,
           u.platform,
           MAX(CASE WHEN e.event_name = 'onboarding_complete' THEN 1 ELSE 0 END) AS completed_onboarding,
           MAX(CASE WHEN e.event_name = 'trial_start'         THEN 1 ELSE 0 END) AS started_trial,
           MAX(CASE WHEN e.event_name = 'purchase'            THEN 1 ELSE 0 END) AS purchased
    FROM users_clean u
    LEFT JOIN events_clean e ON e.user_id = u.user_id
    GROUP BY u.user_id, u.platform
)
SELECT platform,
       COUNT(*)                                                AS users,
       ROUND(100.0 * SUM(completed_onboarding) / COUNT(*), 1)  AS onboarding_complete_pct,
       ROUND(100.0 * SUM(purchased) / COUNT(*), 2)             AS overall_conversion_pct
FROM user_flags
GROUP BY platform
ORDER BY overall_conversion_pct DESC;
