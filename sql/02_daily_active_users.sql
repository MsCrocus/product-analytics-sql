-- 02_daily_active_users.sql
-- Business question: How many users are active each day, and what is the weekly trend?
-- Uses the cleaned events view. A user is "active" on a day if they have at least one event.

WITH dau AS (
    SELECT DATE(event_timestamp) AS activity_date,
           COUNT(DISTINCT user_id) AS dau
    FROM events_clean
    GROUP BY DATE(event_timestamp)
)
SELECT activity_date,
       dau,
       ROUND(AVG(dau) OVER (ORDER BY activity_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 1) AS dau_7day_avg
FROM dau
ORDER BY activity_date;
