"""Two-proportion z-test for the onboarding_v2 experiment.

Reads the counts directly from product_analytics.db (same logic as sql/06_ab_test_onboarding_v2.sql)
and prints absolute lift, relative lift, z-score, two-sided p-value and a 95% confidence interval
for the difference in proportions. Only the Python standard library is needed.

Run:  python scripts/ab_test_significance.py
"""
import math
import os
import sqlite3

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
con = sqlite3.connect(os.path.join(ROOT, "product_analytics.db"))

QUERY = """
WITH user_flags AS (
    SELECT a.user_id, a.variant,
           MAX(CASE WHEN e.event_name = 'onboarding_complete' THEN 1 ELSE 0 END) AS completed,
           MAX(CASE WHEN e.event_name = 'trial_start'         THEN 1 ELSE 0 END) AS trial
    FROM experiment_assignments a
    LEFT JOIN events_clean e ON e.user_id = a.user_id
    WHERE a.experiment_name = 'onboarding_v2'
    GROUP BY a.user_id, a.variant
)
SELECT variant, COUNT(*), SUM(completed), SUM(trial) FROM user_flags GROUP BY variant
"""
rows = {v: (n, c, t) for v, n, c, t in con.execute(QUERY)}


def normal_cdf(x):
    return 0.5 * (1 + math.erf(x / math.sqrt(2)))


def z_test(name, x_ctrl, n_ctrl, x_var, n_var):
    p1, p2 = x_ctrl / n_ctrl, x_var / n_var
    pooled = (x_ctrl + x_var) / (n_ctrl + n_var)
    se_pooled = math.sqrt(pooled * (1 - pooled) * (1 / n_ctrl + 1 / n_var))
    z = (p2 - p1) / se_pooled
    p_value = 2 * (1 - normal_cdf(abs(z)))
    se_diff = math.sqrt(p1 * (1 - p1) / n_ctrl + p2 * (1 - p2) / n_var)
    lo, hi = (p2 - p1) - 1.96 * se_diff, (p2 - p1) + 1.96 * se_diff
    print(f"{name}")
    print(f"  control : {p1:.2%} ({x_ctrl}/{n_ctrl})")
    print(f"  variant : {p2:.2%} ({x_var}/{n_var})")
    print(f"  absolute lift : {100 * (p2 - p1):+.2f} percentage points")
    print(f"  relative lift : {100 * (p2 - p1) / p1:+.1f}%")
    print(f"  z = {z:.2f}, two-sided p-value = {p_value:.2g}")
    print(f"  95% CI for the difference: [{100 * lo:+.2f}, {100 * hi:+.2f}] percentage points\n")


n_c, comp_c, trial_c = rows["control"]
n_v, comp_v, trial_v = rows["variant"]
z_test("Onboarding completion rate (primary metric)", comp_c, n_c, comp_v, n_v)
z_test("Trial start rate (secondary metric)", trial_c, n_c, trial_v, n_v)
