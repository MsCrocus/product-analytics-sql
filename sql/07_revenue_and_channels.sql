-- 07_revenue_and_channels.sql
-- Business question: Which acquisition channels generate the most revenue, and how does revenue accumulate?

-- 7a. Revenue, ARPU and revenue share by channel
WITH channel_users AS (
    SELECT acquisition_channel AS channel, COUNT(*) AS users
    FROM users_clean
    GROUP BY acquisition_channel
),
channel_revenue AS (
    SELECT u.acquisition_channel AS channel,
           COUNT(*)              AS paying_users,
           SUM(s.price_usd)      AS revenue_usd
    FROM subscriptions s
    JOIN users_clean u ON u.user_id = s.user_id
    GROUP BY u.acquisition_channel
)
SELECT cu.channel,
       cu.users,
       r.paying_users,
       ROUND(100.0 * r.paying_users / cu.users, 2)                AS paying_user_pct,
       ROUND(r.revenue_usd, 2)                                    AS revenue_usd,
       ROUND(r.revenue_usd / cu.users, 3)                         AS arpu_usd,
       ROUND(100.0 * r.revenue_usd / SUM(r.revenue_usd) OVER (), 1) AS revenue_share_pct,
       RANK() OVER (ORDER BY r.revenue_usd DESC)                  AS revenue_rank
FROM channel_users cu
JOIN channel_revenue r ON r.channel = cu.channel
ORDER BY revenue_rank;

-- 7b. Cumulative revenue by day
WITH daily AS (
    SELECT start_date, SUM(price_usd) AS revenue_usd
    FROM subscriptions
    GROUP BY start_date
)
SELECT start_date,
       ROUND(revenue_usd, 2) AS revenue_usd,
       ROUND(SUM(revenue_usd) OVER (ORDER BY start_date), 2) AS cumulative_revenue_usd
FROM daily
ORDER BY start_date;
