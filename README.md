# Card-not-present fraud decision study

A reproducible study of whether a score should take a card-not-present transaction out of the automatic-approval path. The book is synthetic, the features see only the past, and the test window is scored once.

On the locked test window, the policy chosen on validation is gradient boosting at a score threshold of 0.129. It reviews 13.3 transactions a day, catches 80.6% of frauds and 93.2% of fraud amount, and is right on 51.3% of alerts. Loss falls by $37,121 versus approving every transaction (95% day-bootstrap interval $29,958 to $43,688). It does not catch camouflage fraud, and the score is too high among the alerts it does raise (mean score 62.1% against a 51.3% fraud rate).

The full comparison is in [reports/evaluation.md](reports/evaluation.md), which `run_pipeline.py` writes. If that file disagrees with a number somewhere else, regenerate it.

## Question

On a later period that was not used to fit anything, does a calibrated model reduce amount-weighted loss versus approving every transaction, and versus rules a reviewer could have written down in advance?

Loss is the amount of fraud that is not alerted, plus a review cost of $8 for every alert. A true positive is treated as a prevented loss. A false positive is treated as a review that then releases the purchase. The test window does not choose the model, the threshold, or the daily review cap.

## Book

`src/fraudlab/generate.py` builds 120 days of transactions. Fraud is one of four behaviors:

- A stolen card: new device, foreign IP, several times the customer's usual amount. Some episodes with that shape are legitimate.
- An account takeover: a short burst on a new device. Ordinary bursts on the customer's own device are legitimate.
- A synthetic ring: young accounts, usually a disposable email and a prepaid BIN, sharing a device. Some lookalikes are legitimate, as is a separate cohort of young customers on their own device.
- Camouflage: a normal purchase on the customer's own device, labeled fraud. The features do not describe it. Perfect recall is not a credible result.

The fraud rate is higher than a live portfolio so the 30-day test window has enough frauds for an interval. Amounts are simulated currency units. This is not the public credit-card file, and it does not contain real customers.

## Features and split

History features are computed in `src/fraudlab/features.py` from transactions strictly earlier than the row being scored. The merchant-category rate uses a fixed prior plus training-window labels that have already occurred. Labels after day 70 do not enter a feature. Cold-start amount scaling is frozen on the training window.

| Window | Days | Role |
| --- | --- | --- |
| Train | 1–70 | Fit the logistic model and the gradient boosting model |
| Validation | 71–90 | Calibrate scores, choose the model, the threshold, and the review cap |
| Test | 91–120 | Report once |

The candidates are: approve everything, a large-amount rule, an analyst rule written down before the test window, a probability threshold on each model, and a daily review cap on the better model. The lowest validation loss wins. Both models are regularized. Scores used for a threshold are calibrated on validation with a one-variable logistic regression.

## Reproduce

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python run_pipeline.py
python -m pytest tests
```

The tests check that dropping future rows leaves past features unchanged, that labels after the training cutoff do not move a feature, and that a metric refuses to run when training and evaluation ids overlap.

`artifacts/` holds the fitted policy and the test-window scores. Both are produced by the run and are not source.

## Limits

A saving on this book is not a production approval. The loss ignores recovery, chargeback delay beyond the gap between train and validation, and the cost of declining a good customer. No drift and no adaptive attacker are simulated. Scoring a new day means appending that day to the history, leaving its labels unknown, and calling the same feature function with the original training cutoff.
