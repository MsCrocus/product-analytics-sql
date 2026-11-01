"""Generate a synthetic mobile-app event dataset (fictional app, no real company data).

Run:  python scripts/generate_data.py
Output: CSV files in ../data  (seeded, so the output is reproducible)

The dataset intentionally contains a few data-quality problems (duplicates,
orphan events, events before signup, missing country, inconsistent platform
casing) so that the validation queries in sql/01_data_quality_checks.sql have
something real to find.
"""
import csv
import os
import random
from datetime import datetime, timedelta

random.seed(42)
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")
os.makedirs(OUT, exist_ok=True)

N_USERS = 5000
START = datetime(2026, 1, 1)
SIGNUP_DAYS = 60                      # signups: 2026-01-01 .. 2026-03-01
END = datetime(2026, 3, 31, 23, 59)   # data window end

COUNTRIES = ["TR", "US", "DE", "BR", "GB", "ID", "FR"]
COUNTRY_W = [22, 25, 10, 12, 9, 12, 10]
CHANNELS = ["organic", "paid_social", "paid_search", "referral"]
CHANNEL_W = [40, 28, 20, 12]
# P(purchase | trial started) by acquisition channel
PURCHASE_BY_CHANNEL = {"organic": 0.46, "paid_social": 0.36, "paid_search": 0.44, "referral": 0.55}

users, events, subs, assigns = [], [], [], []
event_id = 1
sub_id = 1


def add_event(uid, name, ts):
    global event_id
    events.append([event_id, uid, name, ts.strftime("%Y-%m-%d %H:%M:%S")])
    event_id += 1


for uid in range(1, N_USERS + 1):
    signup = START + timedelta(days=random.randrange(SIGNUP_DAYS),
                               seconds=random.randrange(86400))
    platform = random.choices(["iOS", "Android"], [45, 55])[0]
    country = random.choices(COUNTRIES, COUNTRY_W)[0]
    channel = random.choices(CHANNELS, CHANNEL_W)[0]
    variant = random.choice(["control", "variant"])
    users.append([uid, signup.strftime("%Y-%m-%d"), platform, country, channel])
    assigns.append([uid, "onboarding_v2", variant, signup.strftime("%Y-%m-%d %H:%M:%S")])

    # ---- onboarding / monetisation funnel ----
    t = signup
    add_event(uid, "app_open", t)
    completed = paywall = trial = purchased = False
    if random.random() < 0.92:
        t += timedelta(seconds=random.randrange(5, 60))
        add_event(uid, "onboarding_start", t)
        p_complete = 0.55 if variant == "control" else 0.65
        completed = random.random() < p_complete
    if completed:
        t += timedelta(seconds=random.randrange(30, 240))
        add_event(uid, "onboarding_complete", t)
        paywall = random.random() < 0.80
    if paywall:
        t += timedelta(seconds=random.randrange(5, 60))
        add_event(uid, "paywall_view", t)
        p_trial = 0.30 if variant == "control" else 0.34
        trial = random.random() < p_trial
    if trial:
        t += timedelta(seconds=random.randrange(5, 90))
        add_event(uid, "trial_start", t)
        trial_ts = t
        purchased = random.random() < PURCHASE_BY_CHANNEL[channel]
    if purchased:
        pts = trial_ts + timedelta(days=3, seconds=random.randrange(3600))
        if pts <= END:
            add_event(uid, "purchase", pts)
            plan = random.choices(["monthly", "annual"], [70, 30])[0]
            price = 4.99 if plan == "monthly" else 29.99
            subs.append([sub_id, uid, plan, price, pts.strftime("%Y-%m-%d")])
            sub_id += 1

    # ---- later activity (drives retention) ----
    base = 0.34 if completed else 0.14
    if purchased:
        base += 0.12
    midnight = signup.replace(hour=0, minute=0, second=0)
    for d in range(1, 31):
        day_start = midnight + timedelta(days=d)
        if day_start > END:
            break
        p_active = base * (0.88 ** (d - 1)) + 0.02
        if random.random() < p_active:
            ts = day_start + timedelta(seconds=random.randrange(7 * 3600, 23 * 3600))
            add_event(uid, "app_open", ts)
            for _ in range(random.choices([0, 1, 2, 3], [20, 40, 25, 15])[0]):
                ts += timedelta(seconds=random.randrange(20, 600))
                add_event(uid, "feature_use", ts)

# ---- planted data-quality issues ----
for row in random.sample(events, 30):                       # 30 duplicate events
    events.append([event_id] + row[1:])
    event_id += 1
user_signup = {u[0]: datetime.strptime(u[1], "%Y-%m-%d") for u in users}
for i in random.sample(range(len(events)), 20):             # 20 events before signup
    uid = events[i][1]
    events[i][3] = (user_signup[uid] - timedelta(days=1, hours=3)).strftime("%Y-%m-%d %H:%M:%S")
for _ in range(15):                                         # 15 orphan events
    add_event(random.randint(9001, 9100), "app_open", START + timedelta(days=random.randrange(60)))
for i in random.sample(range(len(users)), 40):              # 40 users without country
    users[i][3] = ""
for i in random.sample(range(len(users)), 25):              # 25 users with odd platform casing
    users[i][2] = users[i][2].lower() if i % 2 else users[i][2].upper()

events.sort(key=lambda r: r[3])
for i, r in enumerate(events, start=1):                     # sequential ids after sorting
    r[0] = i


def write(name, header, rows):
    with open(os.path.join(OUT, name), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(rows)
    print(f"{name}: {len(rows)} rows")


write("users.csv", ["user_id", "signup_date", "platform", "country", "acquisition_channel"], users)
write("events.csv", ["event_id", "user_id", "event_name", "event_timestamp"], events)
write("subscriptions.csv", ["subscription_id", "user_id", "plan", "price_usd", "start_date"], subs)
write("experiment_assignments.csv", ["user_id", "experiment_name", "variant", "assigned_at"], assigns)
