"""Write the decision memo from the numbers the pipeline just computed."""

from __future__ import annotations

import math


def _money(value: float) -> str:
    if value is None or (isinstance(value, float) and math.isnan(value)):
        return "n/a"
    sign = "-" if value < 0 else ""
    return f"{sign}${abs(value):,.0f}"


def _pct(value: float) -> str:
    if value is None or (isinstance(value, float) and math.isnan(value)):
        return "n/a"
    return f"{100.0 * value:.1f}%"


def _num(value: float, digits: int = 0) -> str:
    if value is None or (isinstance(value, float) and math.isnan(value)):
        return "n/a"
    return f"{value:,.{digits}f}"


def _interval(band: dict, kind: str) -> str:
    if kind == "money":
        return f"{_money(band['p2.5'])} to {_money(band['p97.5'])}"
    return f"{_pct(band['p2.5'])} to {_pct(band['p97.5'])}"


def write_report(path: str, study: dict) -> None:
    d = study["decision"]
    test = d["test"]
    boot = study["bootstrap"]
    savings = boot["savings_vs_approve_all"]
    book = study["book"]
    cfg = study["config"]

    if d["name"] == "approve_all":
        verdict = (
            "Validation preferred approving every transaction. No alerting policy "
            "reduced validation loss by enough to be selected."
        )
    elif savings["p2.5"] > 0:
        verdict = (
            "The day-bootstrap interval for the saving lies above zero. On this "
            "synthetic book the selected policy reduces loss versus approving "
            "every transaction."
        )
    elif savings["p97.5"] < 0:
        verdict = (
            "The day-bootstrap interval for the saving lies below zero. The "
            "selected policy loses money on the test window versus approving "
            "every transaction, so it should not be deployed."
        )
    else:
        verdict = (
            "The day-bootstrap interval for the saving includes zero. The test "
            "window does not establish a reliable reduction in loss versus "
            "approving every transaction."
        )

    lines = [
        "# Fraud decision memo",
        "",
        f"Simulated book from {book['start']} covering {cfg['n_days']} days. "
        f"Seed {cfg['seed']}. Book digest `{book['digest']}`.",
        "",
        "## Decision",
        "",
        verdict,
        "",
        (
            f"The policy selected on the validation window is **{d['label']}**. "
            f"On the locked test window it reviews {_num(test['alerts'])} transactions "
            f"({_num(test['alerts_per_day'], 1)} per day) and its loss is {_money(test['loss'])}, "
            f"against {_money(test['fraud_amount'])} of fraud amount if every transaction is approved. "
            f"The saving is {_money(test['savings_vs_approve_all'])} "
            f"(95% day-bootstrap interval {_interval(savings, 'money')}). "
            f"Count precision is {_pct(test['precision'])} "
            f"(interval {_interval(boot['precision'], 'pct')}) and count recall is {_pct(test['recall'])} "
            f"(interval {_interval(boot['recall'], 'pct')}). "
            f"Amount recall is {_pct(test['amount_recall'])} "
            f"(interval {_interval(boot['amount_recall'], 'pct')})."
        ),
        "",
        (
            "Validation chose the model, the calibrator, the threshold, and the "
            "daily review cap. The test window was scored after those choices were "
            "fixed. Validation loss is mildly optimistic because calibration and "
            "selection share one window. The test loss was not part of that choice."
        ),
        "",
        f"Confusion matrix on the test window: {_num(test['tp'])} true positives, "
        f"{_num(test['fp'])} false positives, {_num(test['fn'])} false negatives, {_num(test['tn'])} true negatives. "
        f"Missed fraud amount {_money(test['missed_amount'])}. Review spend {_money(test['review_spend'])}.",
        "",
    ]

    if study.get("test_disagrees"):
        lines.extend([study["test_disagrees"], ""])
    else:
        lines.extend(
            [
                "No other candidate had a lower test loss. That agreement was not required, and it was not used as a reason to keep the policy.",
                "",
            ]
        )

    lines.extend(
        [
            "## What was compared",
            "",
            "Loss is missed fraud amount plus a review cost for every alert, true or false. "
            f"The precommitted review cost is ${cfg['review_cost']:.0f} per alert. "
            "Approving everything costs the full fraud amount and nothing for review. "
            "An alert is assumed to stop the fraud when it is a true positive, and to "
            "release a legitimate purchase after review when it is a false positive. "
            "There is no separate customer-friction cost for a decline.",
            "",
            "| Policy | How it was set | Validation loss | Test loss | Test saving | Test precision | Test recall | Alerts/day |",
            "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    for row in study["comparison"]:
        marker = " (selected)" if row["name"] == d["name"] else ""
        lines.append(
            "| {label}{marker} | {how} | {vloss} | {tloss} | {save} | {prec} | {rec} | {apd} |".format(
                label=row["label"],
                marker=marker,
                how=row["how"],
                vloss=_money(row["val"]["loss"]),
                tloss=_money(row["test"]["loss"]),
                save=_money(row["test"]["savings_vs_approve_all"]),
                prec=_pct(row["test"]["precision"]),
                rec=_pct(row["test"]["recall"]),
                apd=_num(row["test"]["alerts_per_day"], 1),
            )
        )

    lines.extend(
        [
            "",
            "The selected row is the lowest validation loss.",
            "",
            "## Book",
            "",
            (
                f"{_num(book['rows'])} transactions, {_num(book['frauds'])} frauds "
                f"({_pct(book['fraud_rate'])}), fraud amount {_money(book['fraud_amount'])}. "
                f"Train {book['train_rows']} rows / {book['train_frauds']} frauds, "
                f"validation {book['val_rows']} / {book['val_frauds']}, "
                f"test {book['test_rows']} / {book['test_frauds']}."
            ),
            "",
            "The label is generated with the behavior, not assigned independently of it. "
            "Stolen-card episodes are a new device, a foreign IP, and a large multiple of the customer's usual amount; "
            "about 18% of episodes with that shape are legitimate. "
            "Account-takeover episodes are a short burst on a new device; ordinary bursts on the customer's own device are legitimate. "
            "Ring accounts are young, usually disposable-email and prepaid, and share a device pool; some lookalikes and a separate cohort of young legitimate customers are not fraud. "
            "Camouflage fraud is an ordinary purchase on the customer's own device and is not distinguishable from the features. "
            "That last source is why a perfect recall is not a credible result on this book.",
            "",
            "Features use only earlier transactions. Customer velocity, device reuse, and the amount surprise against the customer's own history are updated after the row is scored. "
            "The merchant-category rate uses a fixed prior (0.8% with strength 40) plus training-window labels that have already occurred. "
            "Labels after the training cutoff do not move the rate. Cold-start amount scaling uses the training-window mean and standard deviation.",
            "",
            "## Review capacity",
            "",
            "The cap, if one was eligible, was chosen on the validation scores of the model that won the threshold comparison. "
            "The test curve below uses that same score and the same grid. It describes the test window. It was not used to pick the cap.",
            "",
            "| Reviews per day (cap) | Validation loss | Test loss | Test precision | Test recall | Test saving |",
            "| ---: | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    val_by_k = {row["k"]: row for row in study["val_capacity"]}
    for row in study["test_capacity"]:
        val_row = val_by_k[row["k"]]
        lines.append(
            "| {k} | {vloss} | {tloss} | {prec} | {rec} | {save} |".format(
                k=row["k"],
                vloss=_money(val_row["loss"]),
                tloss=_money(row["loss"]),
                prec=_pct(row["precision"]),
                rec=_pct(row["recall"]),
                save=_money(row["savings_vs_approve_all"]),
            )
        )

    lines.extend(["", "## Where the test alerts land", ""])
    lines.append("| Mechanism | Transactions | Frauds | Caught | Missed amount | False alerts |")
    lines.append("| --- | ---: | ---: | ---: | ---: | ---: |")
    for row in study["mechanisms"]:
        lines.append(
            "| {mechanism} | {n} | {frauds} | {caught} | {missed} | {fp} |".format(
                mechanism=row["mechanism"],
                n=_num(row["n"]),
                frauds=_num(row["frauds"]),
                caught=_num(row["caught"]),
                missed=_money(row["missed_amount"]),
                fp=_num(row["false_alerts"]),
            )
        )

    if study.get("calibration"):
        lines.extend(
            [
                "",
                "## Calibration diagnostic",
                "",
                "Deciles of the calibrated score on the test window. This table was not used to choose the policy. "
                f"Expected calibration error is {study['ece']:.3f}, and it is small because almost every transaction has a score near zero.",
                "",
            ]
        )
        op = study.get("operating_calibration")
        if op and op.get("n"):
            gap = op["mean_score"] - op["observed_rate"]
            if gap > 0.02:
                reading = (
                    "The probabilities are too high in the region a reviewer actually acts on, "
                    "so the score should not be read as the chance the transaction is fraud."
                )
            elif gap < -0.02:
                reading = (
                    "The probabilities are too low in the region a reviewer actually acts on, "
                    "so the score should not be read as the chance the transaction is fraud."
                )
            else:
                reading = "At the operating point the mean score is close to the observed fraud rate."
            lines.append(
                f"Among the {_num(op['n'])} test transactions the policy alerts, the mean score is "
                f"{_pct(op['mean_score'])} and the observed fraud rate is {_pct(op['observed_rate'])}. "
                f"{reading} The loss uses the threshold, not the probability as a price."
            )
            lines.append("")
        lines.extend(
            [
                "| Score decile | Transactions | Mean score | Observed fraud rate |",
                "| ---: | ---: | ---: | ---: |",
            ]
        )
        for i, row in enumerate(study["calibration"], start=1):
            lines.append(
                f"| {i} | {_num(row['n'])} | {100.0 * row['mean_score']:.2f}% | {100.0 * row['fraud_rate']:.2f}% |"
            )

    lines.extend(
        [
            "",
            "## Review-cost sensitivity",
            "",
            "For each review cost, the probability threshold is chosen again on the validation window of the same model. "
            "These rows are not test results.",
            "",
            "| Review cost | Validation threshold | Validation loss | Validation saving | Validation alerts/day |",
            "| ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    for row in study["cost_sensitivity"]:
        lines.append(
            "| {cost} | {thr} | {loss} | {save} | {apd} |".format(
                cost=_money(row["review_cost"]),
                thr=f"{row['threshold']:.3f}" if row["threshold"] <= 1 else "alert none",
                loss=_money(row["loss"]),
                save=_money(row["savings"]),
                apd=_num(row["alerts_per_day"], 1),
            )
        )

    lines.extend(
        [
            "",
            "## Limits",
            "",
            "- The book is synthetic. A saving here is evidence about this generating process, not about a live portfolio.",
            "- The fraud rate is higher than a typical card-not-present book, so that the test window has enough frauds for an interval.",
            "- Loss treats a true positive as a fully prevented fraud and a false positive as a review that releases the purchase. Recovery rates, dispute delays, and the cost of declining a good customer are not in the loss.",
            "- Category risk assumes labels from the training window are known before the validation period starts. A longer chargeback lag than that gap would make the rate unavailable.",
            "- Camouflage fraud has no feature signal. Catching it would mean the model had seen the label, which this design treats as a failure.",
            "- No drift, seasonality beyond day of week, or adversary adapting to the score is simulated.",
            "",
            "## Reproduce",
            "",
            "```",
            "python run_pipeline.py",
            "python -m pytest tests",
            "```",
            "",
            f"Stack: Python {study['versions']['python']}, numpy {study['versions']['numpy']}, "
            f"pandas {study['versions']['pandas']}, scikit-learn {study['versions']['sklearn']}.",
            "",
        ]
    )
    with open(path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines))
