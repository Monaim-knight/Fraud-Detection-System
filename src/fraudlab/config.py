"""Locked study settings.

These choices are part of the design, not knobs to turn after seeing the
test window. Validation may select a model, a threshold, and a review cap.
The test window is scored once, at the settings chosen on validation.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass


COUNTRIES = ("US", "GB", "DE", "FR", "CA", "AU", "BR", "MX", "IN", "NG")
COUNTRY_P = (0.26, 0.12, 0.10, 0.08, 0.08, 0.06, 0.09, 0.07, 0.09, 0.05)

MERCHANTS = (
    "grocery",
    "fuel",
    "restaurant",
    "travel",
    "digital_goods",
    "electronics",
    "luxury",
)
LEGIT_MERCHANT_P = (0.24, 0.12, 0.18, 0.10, 0.16, 0.14, 0.06)
STOLEN_MERCHANT_P = (0.04, 0.03, 0.05, 0.12, 0.28, 0.26, 0.22)

FREE_DOMAINS = ("gmail.com", "outlook.com", "yahoo.com", "icloud.com")
CORP_DOMAINS = ("acme.com", "northwind.com", "contoso.com", "initech.com")
DISPOSABLE_DOMAINS = (
    "mailinator.com",
    "guerrillamail.com",
    "tempmail.com",
    "yopmail.com",
)
PREPAID_BINS = ("411111", "422222", "433333", "510510")
REGULAR_BINS = ("400000", "411112", "510000", "520000", "530000")

# History features only. The label, the mechanism name, and the raw amount
# used for the loss calculation are deliberately absent.
FEATURES = (
    "log_amount",
    "amount_z",
    "hour_sin",
    "hour_cos",
    "dow_sin",
    "dow_cos",
    "account_age_days",
    "no_history",
    "prior_txn_count",
    "prior_txn_1h",
    "prior_txn_24h",
    "log_prior_amount_24h",
    "log_seconds_since_prev",
    "new_device",
    "device_prior_customers",
    "device_txn_24h",
    "geo_mismatch",
    "disposable_email",
    "prepaid_card",
    "merchant_rate",
)

CAPACITY_GRID = (5, 10, 20, 40, 80)
REVIEW_COST_SENSITIVITY = (4.0, 8.0, 15.0, 30.0)


@dataclass(frozen=True)
class Config:
    seed: int = 42
    n_customers: int = 8000
    n_days: int = 120
    train_days: int = 70
    val_days: int = 20
    start: str = "2024-01-01"
    mean_txn_per_customer: float = 16.0
    review_cost: float = 8.0
    # Fixed prior for the category rate. Not estimated from labels.
    merchant_prior_rate: float = 0.008
    merchant_prior_strength: float = 40.0
    stolen_episodes: int = 220
    stolen_fraud_probability: float = 0.82
    ato_bursts: int = 70
    ato_size: int = 5
    ring_customers: int = 280
    ring_fraud_probability: float = 0.75
    legit_new_customers: int = 400
    camouflage: int = 120
    legit_bursts: int = 100
    mule_devices: int = 40
    amount_rule_quantile: float = 0.995
    rule_amount_z: float = 3.5
    rule_burst_count: int = 3
    rule_young_days: float = 2.0
    rule_device_customers: int = 2
    bootstrap_draws: int = 400

    @property
    def test_days(self) -> int:
        return self.n_days - self.train_days - self.val_days

    @property
    def train_end_ts(self) -> float:
        return float(self.train_days * 86400)

    @property
    def val_end_ts(self) -> float:
        return float((self.train_days + self.val_days) * 86400)

    def to_dict(self) -> dict:
        payload = asdict(self)
        payload["test_days"] = self.test_days
        return payload


def split_name(ts: float, cfg: Config) -> str:
    if ts < cfg.train_end_ts:
        return "train"
    if ts < cfg.val_end_ts:
        return "val"
    return "test"
