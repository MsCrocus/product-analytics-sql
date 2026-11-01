-- 03_onboarding_funnel.sql
-- Business question: Where do users drop off between signup and purchase?
-- Step 1 counts all signed-up users, the remaining steps count distinct users with that event.

WITH funnel AS (
    SELECT 1 AS step_no, 'signup'              AS step, COUNT(*) AS users FROM users_clean
    UNION ALL
    SELECT 2, 'onboarding_start',    COUNT(DISTINCT user_id) FROM events_clean WHERE event_name = 'onboarding_start'
    UNION ALL
    SELECT 3, 'onboarding_complete', COUNT(DISTINCT user_id) FROM events_clean WHERE event_name = 'onboarding_complete'
    UNION ALL
    SELECT 4, 'paywall_view',        COUNT(DISTINCT user_id) FROM events_clean WHERE event_name = 'paywall_view'
    UNION ALL
    SELECT 5, 'trial_start',         COUNT(DISTINCT user_id) FROM events_clean WHERE event_name = 'trial_start'
    UNION ALL
    SELECT 6, 'purchase',            COUNT(DISTINCT user_id) FROM events_clean WHERE event_name = 'purchase'
)
SELECT step_no,
       step,
       users,
       ROUND(100.0 * users / LAG(users) OVER (ORDER BY step_no), 1)          AS pct_of_previous_step,
       ROUND(100.0 * users / FIRST_VALUE(users) OVER (ORDER BY step_no), 1)  AS pct_of_first_step
FROM funnel
ORDER BY step_no;
