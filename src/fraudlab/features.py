"""Point-in-time features.

Every history feature is computed from transactions strictly earlier than
the row being scored. Category fraud rates use a fixed prior plus labels
from the training window only, and only from rows that have already
occurred. Validation and test labels never enter a feature. Deleting a
future row, or flipping a label after the training cutoff, does not change
the feature values of the rows that remain.
"""

from __future__ import annotations

import math
from collections import defaultdict, deque

import numpy as np
import pandas as pd

from fraudlab.config import DISPOSABLE_DOMAINS, FEATURES, PREPAID_BINS, Config


def train_amount_stats(df: pd.DataFrame, train_end_ts: float) -> tuple[float, float]:
    amounts = df.loc[df["ts"] < train_end_ts, "amount"].to_numpy(dtype=float)
    if len(amounts) < 2:
        raise ValueError("training window has too few amounts to scale cold-start customers")
    mu = float(amounts.mean())
    sd = float(amounts.std())
    return mu, max(sd, 1.0)


def build_features(
    df: pd.DataFrame,
    cfg: Config,
    amount_mean: float,
    amount_std: float,
) -> pd.DataFrame:
    """Return a copy sorted by time, with FEATURES attached."""
    missing = {"ts", "amount", "customer_id", "device_id", "is_fraud", "merchant_category"} - set(df.columns)
    if missing:
        raise ValueError(f"transactions are missing columns: {sorted(missing)}")

    out = df.sort_values(["ts", "transaction_id"], kind="mergesort").reset_index(drop=True)
    n = len(out)
    ts = out["ts"].to_numpy(dtype=float)
    amount = out["amount"].to_numpy(dtype=float)
    customer = out["customer_id"].to_numpy()
    device = out["device_id"].to_numpy()
    merchant = out["merchant_category"].to_numpy()
    label = out["is_fraud"].to_numpy(dtype=int)
    train_end = float(cfg.train_end_ts)

    event_time = pd.to_datetime(out["event_time"])
    hour = (
        event_time.dt.hour
        + event_time.dt.minute / 60.0
        + event_time.dt.second / 3600.0
    ).to_numpy(dtype=float)
    dow = event_time.dt.dayofweek.to_numpy(dtype=float)
    age_days = (
        (event_time - pd.to_datetime(out["account_open"])).dt.total_seconds() / 86400.0
    ).to_numpy(dtype=float)
    age_days = np.clip(age_days, 0.0, None)

    disposable = out["email_domain"].isin(DISPOSABLE_DOMAINS).to_numpy(dtype=float)
    prepaid = out["card_bin"].isin(PREPAID_BINS).to_numpy(dtype=float)
    geo = (out["ip_country"].to_numpy() != out["home_country"].to_numpy()).astype(float)

    cols = {name: np.zeros(n, dtype=float) for name in FEATURES}
    cols["log_amount"] = np.log(np.clip(amount, 1e-9, None))
    cols["hour_sin"] = np.sin(2.0 * math.pi * hour / 24.0)
    cols["hour_cos"] = np.cos(2.0 * math.pi * hour / 24.0)
    cols["dow_sin"] = np.sin(2.0 * math.pi * dow / 7.0)
    cols["dow_cos"] = np.cos(2.0 * math.pi * dow / 7.0)
    cols["account_age_days"] = age_days
    cols["disposable_email"] = disposable
    cols["prepaid_card"] = prepaid
    cols["geo_mismatch"] = geo

    cust_n: dict = defaultdict(int)
    cust_sum: dict = defaultdict(float)
    cust_sq: dict = defaultdict(float)
    cust_last: dict = {}
    cust_devices: dict = defaultdict(set)
    cust_events: dict = defaultdict(deque)
    dev_customers: dict = defaultdict(set)
    dev_events: dict = defaultdict(deque)
    merch_n: dict = defaultdict(int)
    merch_f: dict = defaultdict(int)
    prior = cfg.merchant_prior_strength
    prior_f = cfg.merchant_prior_strength * cfg.merchant_prior_rate
    long_gap = 30.0 * 86400.0

    for i in range(n):
        cid = customer[i]
        dev = device[i]
        cat = merchant[i]
        t = ts[i]
        amt = amount[i]

        events = cust_events[cid]
        while events and t - events[0][0] > 86400.0:
            events.popleft()
        prior_24h = len(events)
        prior_amt_24h = 0.0
        prior_1h = 0
        for old_t, old_amt in events:
            prior_amt_24h += old_amt
            if t - old_t <= 3600.0:
                prior_1h += 1

        dev_q = dev_events[dev]
        while dev_q and t - dev_q[0] > 86400.0:
            dev_q.popleft()

        seen_n = cust_n[cid]
        if seen_n >= 3:
            mu = cust_sum[cid] / seen_n
            var = cust_sq[cid] / seen_n - mu * mu
            sd = max(var, 0.0) ** 0.5
            sd = max(sd, 1.0)
            z = (amt - mu) / sd
        else:
            z = (amt - amount_mean) / amount_std

        last = cust_last.get(cid)
        if last is None:
            no_history = 1.0
            gap = long_gap
        else:
            no_history = 0.0
            gap = max(t - last, 0.0)

        rate = (merch_f[cat] + prior_f) / (merch_n[cat] + prior)

        cols["amount_z"][i] = float(np.clip(z, -8.0, 8.0))
        cols["no_history"][i] = no_history
        cols["prior_txn_count"][i] = float(seen_n)
        cols["prior_txn_1h"][i] = float(prior_1h)
        cols["prior_txn_24h"][i] = float(prior_24h)
        cols["log_prior_amount_24h"][i] = math.log1p(max(prior_amt_24h, 0.0))
        cols["log_seconds_since_prev"][i] = math.log1p(gap)
        cols["new_device"][i] = 0.0 if dev in cust_devices[cid] else 1.0
        cols["device_prior_customers"][i] = float(len(dev_customers[dev]))
        cols["device_txn_24h"][i] = float(len(dev_q))
        cols["merchant_rate"][i] = float(rate)

        cust_n[cid] = seen_n + 1
        cust_sum[cid] += amt
        cust_sq[cid] += amt * amt
        cust_last[cid] = t
        cust_devices[cid].add(dev)
        events.append((t, amt))
        dev_customers[dev].add(cid)
        dev_q.append(t)
        if t < train_end:
            merch_n[cat] += 1
            merch_f[cat] += int(label[i])

    for name, values in cols.items():
        out[name] = values
    unexpected = set(FEATURES) & {"is_fraud", "fraud_mechanism", "amount"}
    if unexpected:
        raise RuntimeError(f"label columns leaked into the feature list: {unexpected}")
    return out
