"""Synthetic card-not-present book with a known generating process.

Fraud is created as behavior, not painted onto random rows after the fact.

Four fraud sources, each with a non-fraud lookalike so no single flag is the label:

- Stolen card: a new device, a foreign IP, and a multiple of the customer's
  usual amount. About 18% of episodes with that shape are legitimate
  (a new phone on a trip) and are labeled hard_negative.
- Account takeover: several transactions in a few minutes on a device the
  customer has not used. Separate legit_burst rows are ordinary shopping
  sprees on the customer's own device.
- Synthetic ring: young accounts, usually a disposable email and a prepaid
  BIN, sharing a small pool of devices. Some ring-shaped accounts are
  legitimate, and a separate cohort of young legitimate customers uses
  disposable mail or prepaid cards on their own device.
- Camouflage: a normal purchase on the customer's own device, in their own
  country, near their usual amount, labeled fraud. Nothing in the features
  distinguishes it. It is the reason recall has a ceiling.

Amounts are simulated currency units. The fraud rate is higher than a live
portfolio so that a 30-day test window contains enough frauds to estimate
an interval. No concept drift is simulated beyond the mix this process
already produces.
"""

from __future__ import annotations

import numpy as np
import pandas as pd

from fraudlab.config import (
    CORP_DOMAINS,
    COUNTRIES,
    COUNTRY_P,
    DISPOSABLE_DOMAINS,
    FREE_DOMAINS,
    LEGIT_MERCHANT_P,
    MERCHANTS,
    PREPAID_BINS,
    REGULAR_BINS,
    STOLEN_MERCHANT_P,
    Config,
)


def _other_country(rng: np.random.Generator, home: str) -> str:
    choices = [c for c in COUNTRIES if c != home]
    return choices[int(rng.integers(0, len(choices)))]


def _clip_amount(value: float) -> float:
    return float(np.clip(value, 1.0, 5000.0))


def generate(cfg: Config | None = None) -> pd.DataFrame:
    cfg = cfg or Config()
    if cfg.train_days <= 0 or cfg.val_days <= 0 or cfg.test_days <= 0:
        raise ValueError("train, validation, and test each need at least one day")
    if abs(sum(COUNTRY_P) - 1.0) > 1e-9:
        raise ValueError("country probabilities must sum to 1")
    if abs(sum(LEGIT_MERCHANT_P) - 1.0) > 1e-9 or abs(sum(STOLEN_MERCHANT_P) - 1.0) > 1e-9:
        raise ValueError("merchant probabilities must sum to 1")

    rng = np.random.default_rng(cfg.seed)
    n = cfg.n_customers
    horizon = float(cfg.n_days * 86400)
    countries = np.array(COUNTRIES)

    home = rng.choice(countries, size=n, p=np.array(COUNTRY_P))
    typical = np.clip(np.exp(rng.normal(np.log(48.0), 0.55, size=n)), 10.0, 350.0)
    open_ts = rng.uniform(0.0, 15.0 * 86400.0, size=n)
    late = rng.random(n) < 0.12
    open_ts[late] = rng.uniform(0.0, max(horizon - 5 * 86400.0, 1.0), size=int(late.sum()))
    has_secondary = rng.random(n) < 0.18
    n_txn = rng.poisson(cfg.mean_txn_per_customer, size=n)

    email_roll = rng.random(n)
    base_email = []
    base_bin = []
    for i in range(n):
        if email_roll[i] < 0.08:
            base_email.append(DISPOSABLE_DOMAINS[int(rng.integers(0, len(DISPOSABLE_DOMAINS)))])
        elif email_roll[i] < 0.55:
            base_email.append(FREE_DOMAINS[int(rng.integers(0, len(FREE_DOMAINS)))])
        else:
            base_email.append(CORP_DOMAINS[int(rng.integers(0, len(CORP_DOMAINS)))])
        if rng.random() < 0.07:
            base_bin.append(PREPAID_BINS[int(rng.integers(0, len(PREPAID_BINS)))])
        else:
            base_bin.append(REGULAR_BINS[int(rng.integers(0, len(REGULAR_BINS)))])

    rows: list[dict] = []

    def add(
        cid: int,
        opened: float,
        t: float,
        device: str,
        ip: str,
        home_c: str,
        email: str,
        card_bin: str,
        merchant: str,
        amount: float,
        is_fraud: int,
        mechanism: str,
    ) -> None:
        if t < 0.0 or t >= horizon:
            return
        rows.append(
            {
                "customer_id": cid,
                "account_open_ts": opened,
                "ts": float(t),
                "device_id": device,
                "ip_country": ip,
                "home_country": home_c,
                "email_domain": email,
                "card_bin": card_bin,
                "merchant_category": merchant,
                "amount": _clip_amount(amount),
                "is_fraud": int(is_fraud),
                "fraud_mechanism": mechanism,
            }
        )

    for i in range(n):
        k = int(n_txn[i])
        opened = float(open_ts[i])
        if k == 0 or opened >= horizon - 1:
            continue
        times = rng.uniform(opened, horizon, size=k)
        cid = i + 1
        primary = f"D{cid}"
        secondary = f"D{cid}B" if has_secondary[i] else primary
        for t in times:
            roll = rng.random()
            if roll < 0.94:
                device = primary
            elif roll < 0.98:
                device = secondary
            else:
                device = f"D{int(rng.integers(1, n + 1))}"
            ip = home[i] if rng.random() < 0.94 else _other_country(rng, home[i])
            merchant = MERCHANTS[int(rng.choice(len(MERCHANTS), p=LEGIT_MERCHANT_P))]
            amount = float(np.exp(rng.normal(np.log(typical[i]), 0.50)))
            add(
                cid, opened, float(t), device, ip, home[i], base_email[i], base_bin[i],
                merchant, amount, 0, "none",
            )

    eligible = np.flatnonzero(open_ts < 40.0 * 86400.0)
    if len(eligible) == 0:
        raise RuntimeError("no customers are eligible for fraud episodes")

    for j in range(cfg.stolen_episodes):
        i = int(rng.choice(eligible))
        earliest = float(open_ts[i] + 10.0 * 86400.0)
        if earliest >= horizon - 1:
            continue
        t = float(rng.uniform(earliest, horizon - 1))
        cid = i + 1
        fraud = rng.random() < cfg.stolen_fraud_probability
        merchant = MERCHANTS[int(rng.choice(len(MERCHANTS), p=STOLEN_MERCHANT_P))]
        amount = float(typical[i] * rng.uniform(3.5, 9.0))
        add(
            cid,
            float(open_ts[i]),
            t,
            f"STOLEN{j}",
            _other_country(rng, home[i]),
            home[i],
            base_email[i],
            base_bin[i],
            merchant,
            amount,
            1 if fraud else 0,
            "stolen_card" if fraud else "hard_negative",
        )

    offsets = np.array([0, 180, 420, 900, 1500, 2100], dtype=float)[: cfg.ato_size]
    for j in range(cfg.ato_bursts):
        i = int(rng.choice(eligible))
        earliest = float(open_ts[i] + 5.0 * 86400.0)
        if earliest >= horizon - 3600:
            continue
        t0 = float(rng.uniform(earliest, horizon - 3600))
        cid = i + 1
        ip = _other_country(rng, home[i]) if rng.random() < 0.5 else home[i]
        for off in offsets:
            merchant = "digital_goods" if rng.random() < 0.6 else "electronics"
            amount = float(typical[i] * rng.uniform(0.8, 2.2))
            add(
                cid, float(open_ts[i]), t0 + float(off), f"ATO{j}", ip, home[i],
                base_email[i], base_bin[i], merchant, amount, 1, "account_takeover",
            )

    for j in range(cfg.legit_bursts):
        i = int(rng.choice(eligible))
        earliest = float(open_ts[i] + 5.0 * 86400.0)
        if earliest >= horizon - 3600:
            continue
        t0 = float(rng.uniform(earliest, horizon - 3600))
        cid = i + 1
        for off in (0.0, 400.0, 900.0, 2000.0):
            merchant = MERCHANTS[int(rng.choice(len(MERCHANTS), p=LEGIT_MERCHANT_P))]
            amount = float(np.exp(rng.normal(np.log(typical[i]), 0.40)))
            add(
                cid, float(open_ts[i]), t0 + off, f"D{cid}", home[i], home[i],
                base_email[i], base_bin[i], merchant, amount, 0, "legit_burst",
            )

    next_cid = n + 1
    for _ in range(cfg.ring_customers):
        cid = next_cid
        next_cid += 1
        opened = float(rng.uniform(0.0, max(horizon - 2 * 86400.0, 1.0)))
        home_c = str(rng.choice(countries, p=np.array(COUNTRY_P)))
        if rng.random() < 0.80:
            email = DISPOSABLE_DOMAINS[int(rng.integers(0, len(DISPOSABLE_DOMAINS)))]
        else:
            email = FREE_DOMAINS[int(rng.integers(0, len(FREE_DOMAINS)))]
        card_bin = (
            PREPAID_BINS[int(rng.integers(0, len(PREPAID_BINS)))]
            if rng.random() < 0.75
            else REGULAR_BINS[int(rng.integers(0, len(REGULAR_BINS)))]
        )
        device = f"MULE{int(rng.integers(0, cfg.mule_devices))}"
        typical_r = float(np.exp(rng.normal(np.log(70.0), 0.30)))
        for _tx in range(int(rng.integers(1, 4))):
            t = opened + float(rng.uniform(0.0, 36.0 * 3600.0))
            ip = _other_country(rng, home_c) if rng.random() < 0.55 else home_c
            merchant = rng.choice(("digital_goods", "luxury", "electronics"))
            amount = typical_r * float(rng.uniform(1.1, 3.0))
            fraud = rng.random() < cfg.ring_fraud_probability
            add(
                cid, opened, t, device, ip, home_c, email, card_bin, str(merchant),
                amount, 1 if fraud else 0, "synthetic_ring" if fraud else "ring_lookalike",
            )

    for _ in range(cfg.legit_new_customers):
        cid = next_cid
        next_cid += 1
        opened = float(rng.uniform(0.0, max(horizon - 5 * 86400.0, 1.0)))
        home_c = str(rng.choice(countries, p=np.array(COUNTRY_P)))
        if rng.random() < 0.45:
            email = DISPOSABLE_DOMAINS[int(rng.integers(0, len(DISPOSABLE_DOMAINS)))]
        elif rng.random() < 0.7:
            email = FREE_DOMAINS[int(rng.integers(0, len(FREE_DOMAINS)))]
        else:
            email = CORP_DOMAINS[int(rng.integers(0, len(CORP_DOMAINS)))]
        card_bin = (
            PREPAID_BINS[int(rng.integers(0, len(PREPAID_BINS)))]
            if rng.random() < 0.25
            else REGULAR_BINS[int(rng.integers(0, len(REGULAR_BINS)))]
        )
        typical_r = float(np.exp(rng.normal(np.log(30.0), 0.35)))
        for _tx in range(int(rng.integers(1, 4))):
            t = opened + float(rng.uniform(0.0, 5.0 * 86400.0))
            ip = home_c if rng.random() < 0.88 else _other_country(rng, home_c)
            merchant = MERCHANTS[int(rng.choice(len(MERCHANTS), p=LEGIT_MERCHANT_P))]
            amount = typical_r * float(rng.uniform(0.5, 1.5))
            add(
                cid, opened, t, f"NEW{cid}", ip, home_c, email, card_bin, merchant,
                amount, 0, "legit_new_account",
            )

    history = np.flatnonzero(open_ts < horizon - 10 * 86400.0)
    take = min(cfg.camouflage, len(history))
    for i in rng.choice(history, size=take, replace=False):
        i = int(i)
        earliest = float(open_ts[i] + 10.0 * 86400.0)
        if earliest >= horizon - 1:
            continue
        t = float(rng.uniform(earliest, horizon - 1))
        cid = i + 1
        merchant = MERCHANTS[int(rng.choice(len(MERCHANTS), p=LEGIT_MERCHANT_P))]
        amount = float(np.exp(rng.normal(np.log(typical[i]), 0.35)))
        add(
            cid, float(open_ts[i]), t, f"D{cid}", home[i], home[i], base_email[i],
            base_bin[i], merchant, amount, 1, "camouflage",
        )

    df = pd.DataFrame(rows)
    if df.empty:
        raise RuntimeError("generator produced no transactions")
    df = df.sort_values(["ts", "customer_id", "device_id"], kind="mergesort").reset_index(drop=True)
    start = pd.Timestamp(cfg.start)
    df.insert(0, "transaction_id", np.arange(1, len(df) + 1))
    df["event_time"] = start + pd.to_timedelta(df["ts"].to_numpy(), unit="s")
    df["account_open"] = start + pd.to_timedelta(df["account_open_ts"].to_numpy(), unit="s")
    df = df.drop(columns=["account_open_ts"])
    return df
