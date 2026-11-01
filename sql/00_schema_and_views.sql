-- 00_schema_and_views.sql
-- Tables for the synthetic mobile-app dataset plus "clean" views used by all other queries.
-- Dialect: SQLite (3.25+ for window functions). Timestamps are stored as 'YYYY-MM-DD HH:MM:SS' text.

DROP VIEW  IF EXISTS events_clean;
DROP VIEW  IF EXISTS users_clean;
DROP TABLE IF EXISTS experiment_assignments;
DROP TABLE IF EXISTS subscriptions;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id             INTEGER PRIMARY KEY,
    signup_date         TEXT NOT NULL,      -- YYYY-MM-DD
    platform            TEXT,               -- iOS / Android (raw values are inconsistent on purpose)
    country             TEXT,               -- ISO-2 code, may be NULL
    acquisition_channel TEXT                -- organic / paid_social / paid_search / referral
);

CREATE TABLE events (
    event_id        INTEGER PRIMARY KEY,
    user_id         INTEGER NOT NULL,
    event_name      TEXT NOT NULL,
    event_timestamp TEXT NOT NULL           -- YYYY-MM-DD HH:MM:SS
);

CREATE TABLE subscriptions (
    subscription_id INTEGER PRIMARY KEY,
    user_id         INTEGER NOT NULL,
    plan            TEXT NOT NULL,          -- monthly / annual
    price_usd       REAL NOT NULL,
    start_date      TEXT NOT NULL
);

CREATE TABLE experiment_assignments (
    user_id         INTEGER NOT NULL,
    experiment_name TEXT NOT NULL,
    variant         TEXT NOT NULL,          -- control / variant
    assigned_at     TEXT NOT NULL
);

-- Users with normalised platform and country.
CREATE VIEW users_clean AS
SELECT
    user_id,
    signup_date,
    CASE UPPER(platform) WHEN 'IOS' THEN 'iOS' WHEN 'ANDROID' THEN 'Android' ELSE 'Unknown' END AS platform,
    COALESCE(NULLIF(country, ''), 'Unknown') AS country,
    acquisition_channel
FROM users;

-- Events after removing orphans, events dated before signup, and exact duplicates
-- (same user + event name + timestamp; the earliest event_id is kept).
CREATE VIEW events_clean AS
SELECT e.event_id, e.user_id, e.event_name, e.event_timestamp
FROM events e
JOIN users u ON u.user_id = e.user_id
WHERE DATE(e.event_timestamp) >= u.signup_date
  AND e.event_id = (
        SELECT MIN(d.event_id)
        FROM events d
        WHERE d.user_id = e.user_id
          AND d.event_name = e.event_name
          AND d.event_timestamp = e.event_timestamp
  );
