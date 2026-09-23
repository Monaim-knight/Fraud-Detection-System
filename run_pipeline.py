"""Fit the study and write the decision memo.

Run from the repository root: python run_pipeline.py
"""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

import joblib
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "src"))

from fraudlab.config import CAPACITY_GRID, FEATURES, REVIEW_COST_SENSITIVITY, Config  # noqa: E402
from fraudlab.features import build_features, train_amount_stats  # noqa: E402
from fraudlab.generate import generate  # noqa: E402
from fraudlab.models import (  # noqa: E402
    alerts_at_capacity,
    alerts_at_threshold,
    amount_rule_alerts,
    analyst_rule_alerts,
    assert_no_overlap,
    best_capacity,
    best_threshold,
    bootstrap_policy,
    capacity_curve,
    design_matrix,
    fit_medians,
    fit_models,
    loss_breakdown,
)
from fraudlab.reporting import write_report  # noqa: E402


def _split_masks(ts: np.ndarray, cfg: Config) -> dict[str, np.ndarray]:
    return {
        "train": ts < cfg.train_end_ts,
        "val": (ts >= cfg.train_end_ts) & (ts < cfg.val_end_ts),
        "test": ts >= cfg.val_end_ts,
    }


def _with_rate(stats: dict, n_days: int) -> dict:
    stats = dict(stats)
    stats["alerts_per_day"] = stats["alerts"] / n_days if n_days else 0.0
    return stats


def _digest(df: pd.DataFrame) -> str:
    payload = df.loc[:, ["transaction_id", "ts", "is_fraud", "amount"]].to_csv(index=False)
    return hashlib.sha256(payload.encode()).hexdigest()[:16]


def _calibration(y: np.ndarray, scores: np.ndarray, bins: int = 10) -> tuple[list[dict], float]:
    frame = pd.DataFrame({"y": y, "score": scores})
    try:
        frame["bin"] = pd.qcut(frame["score"], bins, labels=False, duplicates="drop")
    except ValueError:
        return [], float("nan")
    rows = []
    ece = 0.0
    n = len(frame)
    for _, part in frame.groupby("bin"):
        mean_score = float(part["score"].mean())
        fraud_rate = float(part["y"].mean())
        rows.append({"n": int(len(part)), "mean_score": mean_score, "fraud_rate": fraud_rate})
        ece += abs(mean_score - fraud_rate) * len(part) / n
    return rows, float(ece)


def _mechanism_rows(frame: pd.DataFrame, alert: np.ndarray) -> list[dict]:
    work = frame.copy()
    work["alert"] = alert
    rows = []
    for mechanism, part in work.groupby("fraud_mechanism", sort=False):
        fraud = part["is_fraud"].to_numpy(dtype=int) == 1
        flagged = part["alert"].to_numpy(dtype=bool)
        amount = part["amount"].to_numpy(dtype=float)
        rows.append(
            {
                "mechanism": str(mechanism),
                "n": int(len(part)),
                "frauds": int(fraud.sum()),
                "caught": int((fraud & flagged).sum()),
                "missed_amount": float(amount[fraud & ~flagged].sum()),
                "false_alerts": int((~fraud & flagged).sum()),
            }
        )
    rows.sort(key=lambda row: (-row["frauds"], row["mechanism"]))
    return rows


def _jsonable(value):
    if isinstance(value, dict):
        return {str(k): _jsonable(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [_jsonable(v) for v in value]
    if isinstance(value, (np.floating,)):
        value = float(value)
    if isinstance(value, (np.integer,)):
        return int(value)
    if isinstance(value, float) and (np.isnan(value) or np.isinf(value)):
        return None
    return value


def main() -> None:
    cfg = Config()
    print("Generating the book...")
    raw = generate(cfg)
    amount_mean, amount_std = train_amount_stats(raw, cfg.train_end_ts)
    print(f"  {len(raw):,} transactions, {int(raw['is_fraud'].sum()):,} frauds")
    print("Building point-in-time features...")
    frame = build_features(raw, cfg, amount_mean, amount_std)
    ts = frame["ts"].to_numpy(dtype=float)
    masks = _split_masks(ts, cfg)
    if min(masks["train"].sum(), masks["val"].sum(), masks["test"].sum()) == 0:
        raise RuntimeError("a split window is empty")
    assert_no_overlap(
        frame.loc[masks["train"], "transaction_id"],
        frame.loc[masks["test"], "transaction_id"],
    )
    assert_no_overlap(
        frame.loc[masks["train"], "transaction_id"],
        frame.loc[masks["val"], "transaction_id"],
    )

    medians = fit_medians(frame.loc[masks["train"]])
    matrix = design_matrix(frame, medians)
    y = frame["is_fraud"].to_numpy(dtype=int)
    amount = frame["amount"].to_numpy(dtype=float)
    day = np.floor(ts / 86400.0).astype(int)

    print("Fitting logistic regression and gradient boosting...")
    models = fit_models(matrix[masks["train"]], y[masks["train"]], matrix[masks["val"]], y[masks["val"]], cfg)
    scored = {model.name: model.calibrated_scores(matrix) for model in models}

    def days_in(mask: np.ndarray) -> int:
        return int(len(np.unique(day[mask])))

    policies = []

    def add_policy(name: str, label: str, how: str, alerts: np.ndarray, model_name: str | None) -> None:
        policies.append(
            {
                "name": name,
                "label": label,
                "how": how,
                "model_name": model_name,
                "alerts": alerts,
                "val": _with_rate(
                    loss_breakdown(y[masks["val"]], amount[masks["val"]], alerts[masks["val"]], cfg.review_cost),
                    days_in(masks["val"]),
                ),
                "test": _with_rate(
                    loss_breakdown(y[masks["test"]], amount[masks["test"]], alerts[masks["test"]], cfg.review_cost),
                    days_in(masks["test"]),
                ),
            }
        )

    none = np.zeros(len(frame), dtype=bool)
    add_policy("approve_all", "Approve all", "no alerts", none, None)
    add_policy(
        "amount_rule",
        "Large-amount rule",
        f"train amount at or above the {cfg.amount_rule_quantile:.1%} quantile",
        amount_rule_alerts(frame, masks["train"], cfg),
        None,
    )
    add_policy(
        "analyst_rule",
        "Analyst rule",
        "precommitted amount, burst, and young-account checks",
        analyst_rule_alerts(frame, cfg),
        None,
    )

    threshold_choice = {}
    for model in models:
        threshold, _stats = best_threshold(
            y[masks["val"]], amount[masks["val"]], scored[model.name][masks["val"]], cfg.review_cost
        )
        threshold_choice[model.name] = threshold
        add_policy(
            f"{model.name}_threshold",
            f"{model.label if hasattr(model, 'label') else model.name.replace('_', ' ').title()} threshold",
            f"validation threshold {threshold:.3f}" if threshold <= 1 else "validation chose no alerts",
            alerts_at_threshold(scored[model.name], threshold),
            model.name,
        )

    model_policies = [p for p in policies if p["name"].endswith("_threshold")]
    chosen_model_policy = min(model_policies, key=lambda row: row["val"]["loss"])
    chosen_model_name = chosen_model_policy["model_name"]
    k_star, _k_stats = best_capacity(
        day[masks["val"]],
        y[masks["val"]],
        amount[masks["val"]],
        scored[chosen_model_name][masks["val"]],
        cfg.review_cost,
        CAPACITY_GRID,
    )
    add_policy(
        f"{chosen_model_name}_capacity",
        f"{chosen_model_name.replace('_', ' ').title()} daily cap",
        f"validation cap of {k_star} reviews per day",
        alerts_at_capacity(day, scored[chosen_model_name], k_star),
        chosen_model_name,
    )

    decision = policies[0]
    for policy in policies[1:]:
        if policy["val"]["loss"] < decision["val"]["loss"]:
            decision = policy

    test_best = min(policies, key=lambda row: row["test"]["loss"])
    disagrees = ""
    if test_best["name"] != decision["name"]:
        disagrees = (
            f"On the test window, {test_best['label']} has a lower loss "
            f"({test_best['test']['loss']:,.0f} versus {decision['test']['loss']:,.0f}). "
            "That comparison was not used. The decision remains the validation choice."
        )

    print(f"Selected on validation: {decision['label']}")
    boot = bootstrap_policy(
        day[masks["test"]],
        y[masks["test"]],
        amount[masks["test"]],
        decision["alerts"][masks["test"]],
        cfg.review_cost,
        cfg.bootstrap_draws,
        cfg.seed,
    )
    calibration, ece = _calibration(y[masks["test"]], scored[chosen_model_name][masks["test"]])
    alerted = decision["alerts"] & masks["test"]
    operating_calibration = {
        "n": int(alerted.sum()),
        "mean_score": float(scored[chosen_model_name][alerted].mean()) if alerted.any() else float("nan"),
        "observed_rate": float(y[alerted].mean()) if alerted.any() else float("nan"),
    }
    val_curve = capacity_curve(
        day[masks["val"]],
        y[masks["val"]],
        amount[masks["val"]],
        scored[chosen_model_name][masks["val"]],
        cfg.review_cost,
        CAPACITY_GRID,
        days_in(masks["val"]),
    )
    test_curve = capacity_curve(
        day[masks["test"]],
        y[masks["test"]],
        amount[masks["test"]],
        scored[chosen_model_name][masks["test"]],
        cfg.review_cost,
        CAPACITY_GRID,
        days_in(masks["test"]),
    )

    sensitivity = []
    for cost in REVIEW_COST_SENSITIVITY:
        threshold, stats = best_threshold(
            y[masks["val"]], amount[masks["val"]], scored[chosen_model_name][masks["val"]], cost
        )
        sensitivity.append(
            {
                "review_cost": cost,
                "threshold": threshold,
                "loss": stats["loss"],
                "savings": stats["savings_vs_approve_all"],
                "alerts_per_day": stats["alerts"] / days_in(masks["val"]),
            }
        )

    counts = {}
    for name, mask in masks.items():
        counts[f"{name}_rows"] = int(mask.sum())
        counts[f"{name}_frauds"] = int(y[mask].sum())
    book = {
        "start": cfg.start,
        "rows": int(len(frame)),
        "frauds": int(y.sum()),
        "fraud_rate": float(y.mean()),
        "fraud_amount": float(amount[y == 1].sum()),
        "digest": _digest(frame),
        **counts,
    }
    versions = {
        "python": sys.version.split()[0],
        "numpy": np.__version__,
        "pandas": pd.__version__,
        "sklearn": __import__("sklearn").__version__,
    }
    study = {
        "config": cfg.to_dict(),
        "versions": versions,
        "book": book,
        "comparison": [
            {k: v for k, v in policy.items() if k != "alerts"}
            for policy in policies
        ],
        "decision": {k: v for k, v in decision.items() if k != "alerts"},
        "test_disagrees": disagrees,
        "bootstrap": boot,
        "val_capacity": val_curve,
        "test_capacity": test_curve,
        "mechanisms": _mechanism_rows(frame.loc[masks["test"]], decision["alerts"][masks["test"]]),
        "calibration": calibration,
        "operating_calibration": operating_calibration,
        "ece": ece,
        "cost_sensitivity": sensitivity,
        "chosen_model": chosen_model_name,
        "thresholds": threshold_choice,
        "capacity_k": k_star,
    }

    reports = ROOT / "reports"
    artifacts = ROOT / "artifacts"
    reports.mkdir(exist_ok=True)
    artifacts.mkdir(exist_ok=True)
    write_report(str(reports / "evaluation.md"), study)
    (reports / "metrics.json").write_text(json.dumps(_jsonable(study), indent=2))

    scored_out = frame.loc[masks["test"], ["transaction_id", "event_time", "amount", "is_fraud", "fraud_mechanism"]].copy()
    scored_out["score"] = scored[chosen_model_name][masks["test"]]
    scored_out["alert"] = decision["alerts"][masks["test"]].astype(int)
    scored_out.to_csv(artifacts / "test_scores.csv", index=False)

    chosen_estimator = next(model for model in models if model.name == chosen_model_name)
    joblib.dump(
        {
            "model": chosen_estimator,
            "medians": medians,
            "features": list(FEATURES),
            "amount_mean": amount_mean,
            "amount_std": amount_std,
            "threshold": threshold_choice[chosen_model_name],
            "capacity_k": k_star,
            "decision": decision["name"],
            "config": cfg.to_dict(),
        },
        artifacts / "policy.joblib",
    )
    test = decision["test"]
    print(
        f"Test loss {test['loss']:.0f} | saving {test['savings_vs_approve_all']:.0f} | "
        f"precision {test['precision']:.3f} | recall {test['recall']:.3f}"
    )
    print(f"Wrote {reports / 'evaluation.md'}")


if __name__ == "__main__":
    main()
