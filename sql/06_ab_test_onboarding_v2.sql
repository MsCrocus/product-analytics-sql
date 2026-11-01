-- 06_ab_test_onboarding_v2.sql
-- Experiment: "onboarding_v2" (new onboarding flow). Hypothesis: the new flow increases onboarding
-- completion and, downstream, trial starts.
-- Primary metric: onboarding completion rate (completed / assigned users).
-- Secondary metric: trial start rate (trial_start / assigned users).

-- 6a. Sample ratio check: are users split roughly 50/50?
SELECT variant,
       COUNT(*) AS assigned_users,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS share_pct
FROM experiment_assignments
WHERE experiment_name = 'onboarding_v2'
GROUP BY variant;

-- 6b. Results per variant
WITH user_flags AS (
    SELECT a.user_id,
           a.variant,
           MAX(CASE WHEN e.event_name = 'onboarding_complete' THEN 1 ELSE 0 END) AS completed_onboarding,
           MAX(CASE WHEN e.event_name = 'trial_start'         THEN 1 ELSE 0 END) AS started_trial,
           MAX(CASE WHEN e.event_name = 'purchase'            THEN 1 ELSE 0 END) AS purchased
    FROM experiment_assignments a
    LEFT JOIN events_clean e ON e.user_id = a.user_id
    WHERE a.experiment_name = 'onboarding_v2'
    GROUP BY a.user_id, a.variant
)
SELECT variant,
       COUNT(*)                         AS users,
       SUM(completed_onboarding)        AS completed,
       ROUND(100.0 * SUM(completed_onboarding) / COUNT(*), 2) AS completion_rate_pct,
       SUM(started_trial)               AS trials,
       ROUND(100.0 * SUM(started_trial) / COUNT(*), 2)        AS trial_rate_pct,
       SUM(purchased)                   AS purchases,
       ROUND(100.0 * SUM(purchased) / COUNT(*), 2)            AS purchase_rate_pct
FROM user_flags
GROUP BY variant
ORDER BY variant DESC;   -- 'variant' row first, then 'control'

-- Statistical significance is calculated in scripts/ab_test_significance.py
-- (two-proportion z-test), using the counts produced by 6b.
