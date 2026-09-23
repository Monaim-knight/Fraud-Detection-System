"""Policies, calibration, and the locked evaluation.

Model choice, calibration, the probability threshold, and the daily review
cap are fit on the validation window. Nothing in this module is allowed to
see a test row while those choices are made. The overlap guard is what the
pipeline calls before a test metric is computed.
"""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

from fraudlab.config import FEATURES, Config


def assert_no_overlap(train_ids, eval_ids) -> None:
    shared = set(map(int, train_ids)) & set(map(int, eval_ids))
    if shared:
        raise ValueError(
            f"evaluation rows overlap training rows ({len(shared)} shared ids). "
            "Refusing to compute a metric on data the model was fit on."
        )


def design_matrix(df: pd.DataFrame, medians: dict[str, float] | None = None) -> np.ndarray:
    unknown = [c for c in FEATURES if c not in df.columns]
    if unknown:
        raise ValueError(f"missing features: {unknown}")
    frame = df.loc[:, FEATURES].apply(pd.to_numeric, errors="coerce")
    if medians is None:
        medians = {c: float(frame[c].median()) if frame[c].notna().any() else 0.0 for c in FEATURES}
    for col in FEATURES:
        fill = medians.get(col, 0.0)
        if fill is None or (isinstance(fill, float) and np.isnan(fill)):
            fill = 0.0
        frame[col] = frame[col].fillna(fill)
    values = frame.to_numpy(dtype=float)
    return np.nan_to_num(values, nan=0.0, posinf=0.0, neginf=0.0)


def fit_medians(train_df: pd.DataFrame) -> dict[str, float]:
    medians = {}
    for col in FEATURES:
        series = pd.to_numeric(train_df[col], errors="coerce")
        value = float(series.median()) if series.notna().any() else 0.0
        medians[col] = 0.0 if np.isnan(value) else value
    return medians


class PlattScaler:
    """Logistic calibration fit on validation scores only."""

    def __init__(self) -> None:
        self._model: LogisticRegression | None = None
        self._identity = True

    def fit(self, scores: np.ndarray, y: np.ndarray) -> "PlattScaler":
        y = np.asarray(y).astype(int)
        scores = np.asarray(scores, dtype=float).reshape(-1, 1)
        if len(np.unique(y)) < 2:
            self._identity = True
            return self
        self._model = LogisticRegression(C=1.0e6, solver="lbfgs", max_iter=200)
        self._model.fit(scores, y)
        self._identity = False
        return self

    def transform(self, scores: np.ndarray) -> np.ndarray:
        scores = np.asarray(scores, dtype=float)
        if self._identity or self._model is None:
            return np.clip(scores, 0.0, 1.0)
        return self._model.predict_proba(scores.reshape(-1, 1))[:, 1]


@dataclass
class FittedModel:
    name: str
    estimator: object
    calibrator: PlattScaler

    def raw_scores(self, matrix: np.ndarray) -> np.ndarray:
        return self.estimator.predict_proba(matrix)[:, 1]

    def calibrated_scores(self, matrix: np.ndarray) -> np.ndarray:
        return self.calibrator.transform(self.raw_scores(matrix))


def _sample_weight(y: np.ndarray) -> np.ndarray:
    y = np.asarray(y).astype(int)
    pos = max(int((y == 1).sum()), 1)
    neg = int((y == 0).sum())
    weight = np.ones(len(y), dtype=float)
    weight[y == 1] = neg / pos
    return weight


def fit_models(x_train: np.ndarray, y_train: np.ndarray, x_val: np.ndarray, y_val: np.ndarray, cfg: Config) -> list[FittedModel]:
    y_train = np.asarray(y_train).astype(int)
    y_val = np.asarray(y_val).astype(int)
    weight = _sample_weight(y_train)

    logistic = Pipeline(
        [
            ("scaler", StandardScaler()),
            (
                "clf",
                LogisticRegression(
                    C=0.5,
                    max_iter=500,
                    class_weight="balanced",
                    solver="lbfgs",
                ),
            ),
        ]
    )
    logistic.fit(x_train, y_train)

    boosting = HistGradientBoostingClassifier(
        max_depth=4,
        learning_rate=0.08,
        max_iter=250,
        min_samples_leaf=40,
        l2_regularization=1.0,
        early_stopping=True,
        validation_fraction=0.15,
        n_iter_no_change=15,
        random_state=cfg.seed,
    )
    boosting.fit(x_train, y_train, sample_weight=weight)

    fitted = []
    for name, estimator in (("logistic", logistic), ("gradient_boosting", boosting)):
        raw_val = estimator.predict_proba(x_val)[:, 1]
        calibrator = PlattScaler().fit(raw_val, y_val)
        fitted.append(FittedModel(name=name, estimator=estimator, calibrator=calibrator))
    return fitted


def loss_breakdown(y: np.ndarray, amount: np.ndarray, alert: np.ndarray, review_cost: float) -> dict:
    y = np.asarray(y).astype(int)
    amount = np.asarray(amount, dtype=float)
    alert = np.asarray(alert).astype(bool)
    fraud = y == 1
    tp = int((fraud & alert).sum())
    fp = int((~fraud & alert).sum())
    fn = int((fraud & ~alert).sum())
    tn = int((~fraud & ~alert).sum())
    fraud_amount = float(amount[fraud].sum())
    caught_amount = float(amount[fraud & alert].sum())
    missed_amount = float(amount[fraud & ~alert].sum())
    review_spend = float(review_cost * alert.sum())
    total_loss = missed_amount + review_spend
    alerts = int(alert.sum())
    precision = float(tp / alerts) if alerts else float("nan")
    recall = float(tp / fraud.sum()) if fraud.any() else float("nan")
    amount_recall = float(caught_amount / fraud_amount) if fraud_amount > 0 else float("nan")
    return {
        "tp": tp,
        "fp": fp,
        "fn": fn,
        "tn": tn,
        "alerts": alerts,
        "precision": precision,
        "recall": recall,
        "amount_recall": amount_recall,
        "fraud_amount": fraud_amount,
        "caught_amount": caught_amount,
        "missed_amount": missed_amount,
        "review_spend": review_spend,
        "loss": total_loss,
        "savings_vs_approve_all": fraud_amount - total_loss,
    }


def alerts_at_threshold(scores: np.ndarray, threshold: float) -> np.ndarray:
    return np.asarray(scores, dtype=float) >= threshold


def best_threshold(y: np.ndarray, amount: np.ndarray, scores: np.ndarray, review_cost: float) -> tuple[float, dict]:
    """Smallest validation loss. Alerting nobody is always a candidate."""
    scores = np.asarray(scores, dtype=float)
    quantiles = np.concatenate(
        [
            np.linspace(0.50, 0.90, 17),
            np.linspace(0.90, 0.99, 37),
            np.linspace(0.99, 0.9995, 20),
        ]
    )
    candidates = np.quantile(scores, quantiles)
    candidates = np.unique(np.concatenate([candidates, [1.0 + 1e-9]]))
    best_t = float(candidates[-1])
    best = loss_breakdown(y, amount, alerts_at_threshold(scores, best_t), review_cost)
    for threshold in candidates:
        stats = loss_breakdown(y, amount, alerts_at_threshold(scores, float(threshold)), review_cost)
        if stats["loss"] < best["loss"]:
            best = stats
            best_t = float(threshold)
    return best_t, best


def alerts_at_capacity(day: np.ndarray, scores: np.ndarray, k: int) -> np.ndarray:
    scores = np.asarray(scores, dtype=float)
    day = np.asarray(day)
    alert = np.zeros(len(scores), dtype=bool)
    if k <= 0:
        return alert
    for value in np.unique(day):
        idx = np.flatnonzero(day == value)
        if len(idx) <= k:
            alert[idx] = True
            continue
        top = idx[np.argpartition(scores[idx], -k)[-k:]]
        alert[top] = True
    return alert


def best_capacity(
    day: np.ndarray,
    y: np.ndarray,
    amount: np.ndarray,
    scores: np.ndarray,
    review_cost: float,
    grid: tuple[int, ...],
) -> tuple[int, dict]:
    best_k = 0
    best = loss_breakdown(y, amount, np.zeros(len(y), dtype=bool), review_cost)
    for k in grid:
        stats = loss_breakdown(y, amount, alerts_at_capacity(day, scores, k), review_cost)
        if stats["loss"] < best["loss"]:
            best = stats
            best_k = int(k)
    return best_k, best


def capacity_curve(
    day: np.ndarray,
    y: np.ndarray,
    amount: np.ndarray,
    scores: np.ndarray,
    review_cost: float,
    grid: tuple[int, ...],
    n_days: int,
) -> list[dict]:
    rows = []
    for k in (0,) + tuple(grid):
        stats = loss_breakdown(y, amount, alerts_at_capacity(day, scores, k), review_cost)
        stats["k"] = int(k)
        stats["alerts_per_day"] = stats["alerts"] / n_days if n_days else 0.0
        rows.append(stats)
    return rows


def amount_rule_alerts(df: pd.DataFrame, train_mask: np.ndarray, cfg: Config) -> np.ndarray:
    cutoff = float(np.quantile(df.loc[train_mask, "amount"].to_numpy(dtype=float), cfg.amount_rule_quantile))
    return df["amount"].to_numpy(dtype=float) >= cutoff


def analyst_rule_alerts(df: pd.DataFrame, cfg: Config) -> np.ndarray:
    return (
        (df["amount_z"].to_numpy(dtype=float) >= cfg.rule_amount_z)
        | (
            (df["new_device"].to_numpy(dtype=float) == 1.0)
            & (df["prior_txn_1h"].to_numpy(dtype=float) >= cfg.rule_burst_count)
        )
        | (
            (df["disposable_email"].to_numpy(dtype=float) == 1.0)
            & (df["prepaid_card"].to_numpy(dtype=float) == 1.0)
            & (df["account_age_days"].to_numpy(dtype=float) < cfg.rule_young_days)
            & (df["device_prior_customers"].to_numpy(dtype=float) >= cfg.rule_device_customers)
        )
    )


def bootstrap_policy(
    day: np.ndarray,
    y: np.ndarray,
    amount: np.ndarray,
    alert: np.ndarray,
    review_cost: float,
    draws: int,
    seed: int,
) -> dict:
    """Resample whole days so the interval reflects day-to-day variation."""
    rng = np.random.default_rng(seed)
    day = np.asarray(day)
    days = np.unique(day)
    buckets = {d: np.flatnonzero(day == d) for d in days}
    keys = ("savings_vs_approve_all", "precision", "recall", "amount_recall", "loss")
    collected = {key: [] for key in keys}
    for _ in range(draws):
        chosen = rng.choice(days, size=len(days), replace=True)
        idx = np.concatenate([buckets[d] for d in chosen])
        stats = loss_breakdown(y[idx], amount[idx], alert[idx], review_cost)
        for key in keys:
            collected[key].append(stats[key])
    summary = {"draws": draws, "days": int(len(days))}
    for key, values in collected.items():
        arr = np.asarray(values, dtype=float)
        summary[key] = {
            "p2.5": float(np.nanpercentile(arr, 2.5)),
            "p50": float(np.nanpercentile(arr, 50)),
            "p97.5": float(np.nanpercentile(arr, 97.5)),
        }
    return summary
