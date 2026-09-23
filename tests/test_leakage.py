"""Guards that keep a later row, or a later label, out of the features."""

from __future__ import annotations

import numpy as np
import pandas as pd

from fraudlab.config import FEATURES, Config
from fraudlab.features import build_features, train_amount_stats
from fraudlab.generate import generate
from fraudlab.models import assert_no_overlap, best_threshold, loss_breakdown


def _small() -> Config:
    return Config(
        seed=1,
        n_customers=280,
        n_days=40,
        train_days=24,
        val_days=8,
        mean_txn_per_customer=8,
        stolen_episodes=12,
        ato_bursts=5,
        ato_size=4,
        ring_customers=18,
        legit_new_customers=18,
        camouflage=6,
        legit_bursts=5,
        bootstrap_draws=20,
    )


def _featured(cfg: Config, df: pd.DataFrame | None = None):
    df = generate(cfg) if df is None else df
    mu, sd = train_amount_stats(df, cfg.train_end_ts)
    return df, build_features(df, cfg, mu, sd), mu, sd


def test_feature_list_excludes_the_label():
    banned = {"is_fraud", "fraud_mechanism", "amount", "customer_id", "device_id"}
    assert banned.isdisjoint(FEATURES)


def test_dropping_the_future_does_not_change_past_features():
    cfg = _small()
    df, full, mu, sd = _featured(cfg)
    cut_ts = max(float(np.quantile(df["ts"], 0.85)), cfg.val_end_ts + 1.0)
    part = build_features(df.loc[df["ts"] <= cut_ts].copy(), cfg, mu, sd)
    merged = full.merge(part, on="transaction_id", suffixes=("_full", "_cut"))
    assert len(merged) == len(part)
    for col in FEATURES:
        np.testing.assert_allclose(
            merged[f"{col}_full"].to_numpy(),
            merged[f"{col}_cut"].to_numpy(),
            rtol=1e-10,
            atol=1e-8,
        )


def test_labels_after_the_cutoff_do_not_change_features():
    cfg = _small()
    df, full, mu, sd = _featured(cfg)
    flipped = df.copy()
    after = flipped["ts"] >= cfg.train_end_ts
    flipped.loc[after, "is_fraud"] = 1 - flipped.loc[after, "is_fraud"]
    rebuilt = build_features(flipped, cfg, mu, sd)
    for col in FEATURES:
        np.testing.assert_allclose(full[col].to_numpy(), rebuilt[col].to_numpy(), rtol=1e-10, atol=1e-8)


def test_training_labels_do_change_later_category_rates():
    cfg = _small()
    df, full, mu, sd = _featured(cfg)
    train = full["ts"] < cfg.train_end_ts
    merchant = full.loc[train, "merchant_category"].value_counts().idxmax()
    part = full.loc[train & (full["merchant_category"] == merchant)]
    assert len(part) >= 3
    first_id = int(part.iloc[0]["transaction_id"])
    later_id = int(part.iloc[-1]["transaction_id"])
    flipped = df.copy()
    flipped.loc[flipped["transaction_id"] == first_id, "is_fraud"] = (
        1 - flipped.loc[flipped["transaction_id"] == first_id, "is_fraud"].astype(int)
    )
    rebuilt = build_features(flipped, cfg, mu, sd)
    before = float(full.loc[full["transaction_id"] == later_id, "merchant_rate"].iloc[0])
    after = float(rebuilt.loc[rebuilt["transaction_id"] == later_id, "merchant_rate"].iloc[0])
    assert before != after


def test_overlap_guard():
    try:
        assert_no_overlap([1, 2, 3], [3, 4])
    except ValueError:
        return
    raise AssertionError("overlap was accepted")


def test_threshold_can_choose_to_alert_nobody():
    y = np.array([0, 0, 0, 0, 1])
    amount = np.array([10, 10, 10, 10, 5], dtype=float)
    scores = np.array([0.2, 0.3, 0.4, 0.5, 0.6])
    # Reviewing anyone costs more than the single small fraud.
    threshold, stats = best_threshold(y, amount, scores, review_cost=50.0)
    assert threshold > 1.0
    assert stats["alerts"] == 0
    approve = loss_breakdown(y, amount, np.zeros(len(y), dtype=bool), 50.0)
    assert stats["loss"] == approve["loss"]
