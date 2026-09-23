# Fraud decision memo

Simulated book from 2024-01-01 covering 120 days. Seed 42. Book digest `7cbbf0de20253d3c`.

## Decision

The day-bootstrap interval for the saving lies above zero. On this synthetic book the selected policy reduces loss versus approving every transaction.

The policy selected on the validation window is **Gradient Boosting threshold**. On the locked test window it reviews 398 transactions (13.3 per day) and its loss is $6,138, against $43,259 of fraud amount if every transaction is approved. The saving is $37,121 (95% day-bootstrap interval $29,958 to $43,688). Count precision is 51.3% (interval 43.8% to 57.5%) and count recall is 80.6% (interval 75.7% to 85.2%). Amount recall is 93.2% (interval 90.6% to 95.5%).

Validation chose the model, the calibrator, the threshold, and the daily review cap. The test window was scored after those choices were fixed. Validation loss is mildly optimistic because calibration and selection share one window. The test loss was not part of that choice.

Confusion matrix on the test window: 204 true positives, 194 false positives, 49 false negatives, 38,770 true negatives. Missed fraud amount $2,954. Review spend $3,184.

No other candidate had a lower test loss. That agreement was not required, and it was not used as a reason to keep the policy.

## What was compared

Loss is missed fraud amount plus a review cost for every alert, true or false. The precommitted review cost is $8 per alert. Approving everything costs the full fraud amount and nothing for review. An alert is assumed to stop the fraud when it is a true positive, and to release a legitimate purchase after review when it is a false positive. There is no separate customer-friction cost for a decline.

| Policy | How it was set | Validation loss | Test loss | Test saving | Test precision | Test recall | Alerts/day |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Approve all | no alerts | $32,950 | $43,259 | $0 | n/a | 0.0% | 0.0 |
| Large-amount rule | train amount at or above the 99.5% quantile | $23,085 | $31,004 | $12,255 | 12.7% | 9.9% | 6.6 |
| Analyst rule | precommitted amount, burst, and young-account checks | $18,030 | $23,491 | $19,768 | 9.2% | 43.1% | 39.4 |
| Logistic threshold | validation threshold 0.278 | $4,672 | $8,688 | $34,571 | 44.2% | 74.3% | 14.2 |
| Gradient Boosting threshold (selected) | validation threshold 0.129 | $3,823 | $6,138 | $37,121 | 51.3% | 80.6% | 13.3 |
| Gradient Boosting daily cap | validation cap of 20 reviews per day | $5,090 | $7,502 | $35,757 | 34.5% | 81.8% | 20.0 |

The selected row is the lowest validation loss.

## Book

130,403 transactions, 1,064 frauds (0.8%), fraud amount $158,017. Train 67956 rows / 608 frauds, validation 23230 / 203, test 39217 / 253.

The label is generated with the behavior, not assigned independently of it. Stolen-card episodes are a new device, a foreign IP, and a large multiple of the customer's usual amount; about 18% of episodes with that shape are legitimate. Account-takeover episodes are a short burst on a new device; ordinary bursts on the customer's own device are legitimate. Ring accounts are young, usually disposable-email and prepaid, and share a device pool; some lookalikes and a separate cohort of young legitimate customers are not fraud. Camouflage fraud is an ordinary purchase on the customer's own device and is not distinguishable from the features. That last source is why a perfect recall is not a credible result on this book.

Features use only earlier transactions. Customer velocity, device reuse, and the amount surprise against the customer's own history are updated after the row is scored. The merchant-category rate uses a fixed prior (0.8% with strength 40) plus training-window labels that have already occurred. Labels after the training cutoff do not move the rate. Cold-start amount scaling uses the training-window mean and standard deviation.

## Review capacity

The cap, if one was eligible, was chosen on the validation scores of the model that won the threshold comparison. The test curve below uses that same score and the same grid. It describes the test window. It was not used to pick the cap.

| Reviews per day (cap) | Validation loss | Test loss | Test precision | Test recall | Test saving |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | $32,950 | $43,259 | n/a | 0.0% | $0 |
| 5 | $18,604 | $24,136 | 72.7% | 43.1% | $19,122 |
| 10 | $8,540 | $12,313 | 57.0% | 67.6% | $30,946 |
| 20 | $5,090 | $7,502 | 34.5% | 81.8% | $35,757 |
| 40 | $7,593 | $12,123 | 17.4% | 82.6% | $31,136 |
| 80 | $13,816 | $21,723 | 8.7% | 82.6% | $21,536 |

## Where the test alerts land

| Mechanism | Transactions | Frauds | Caught | Missed amount | False alerts |
| --- | ---: | ---: | ---: | ---: | ---: |
| synthetic_ring | 93 | 93 | 92 | $49 | 0 |
| account_takeover | 60 | 60 | 58 | $157 | 0 |
| stolen_card | 56 | 56 | 54 | $225 | 0 |
| camouflage | 44 | 44 | 0 | $2,523 | 0 |
| hard_negative | 12 | 0 | 0 | $0 | 10 |
| legit_burst | 92 | 0 | 0 | $0 | 16 |
| legit_new_account | 168 | 0 | 0 | $0 | 1 |
| none | 38,672 | 0 | 0 | $0 | 147 |
| ring_lookalike | 20 | 0 | 0 | $0 | 20 |

## Calibration diagnostic

Deciles of the calibrated score on the test window. This table was not used to choose the policy. Expected calibration error is 0.002, and it is small because almost every transaction has a score near zero.

Among the 398 test transactions the policy alerts, the mean score is 62.1% and the observed fraud rate is 51.3%. The probabilities are too high in the region a reviewer actually acts on, so the score should not be read as the chance the transaction is fraud. The loss uses the threshold, not the probability as a price.

| Score decile | Transactions | Mean score | Observed fraud rate |
| ---: | ---: | ---: | ---: |
| 1 | 3,928 | 0.04% | 0.05% |
| 2 | 3,927 | 0.05% | 0.08% |
| 3 | 4,023 | 0.05% | 0.22% |
| 4 | 3,830 | 0.05% | 0.13% |
| 5 | 4,010 | 0.06% | 0.15% |
| 6 | 3,812 | 0.06% | 0.10% |
| 7 | 3,944 | 0.08% | 0.05% |
| 8 | 3,903 | 0.10% | 0.15% |
| 9 | 3,926 | 0.14% | 0.15% |
| 10 | 3,914 | 6.95% | 5.37% |

## Review-cost sensitivity

For each review cost, the probability threshold is chosen again on the validation window of the same model. These rows are not test results.

| Review cost | Validation threshold | Validation loss | Validation saving | Validation alerts/day |
| ---: | ---: | ---: | ---: | ---: |
| $4 | 0.027 | $2,617 | $30,332 | 17.4 |
| $8 | 0.129 | $3,823 | $29,127 | 14.6 |
| $15 | 0.534 | $5,742 | $27,207 | 11.1 |
| $30 | 0.599 | $8,977 | $23,972 | 10.5 |

## Limits

- The book is synthetic. A saving here is evidence about this generating process, not about a live portfolio.
- The fraud rate is higher than a typical card-not-present book, so that the test window has enough frauds for an interval.
- Loss treats a true positive as a fully prevented fraud and a false positive as a review that releases the purchase. Recovery rates, dispute delays, and the cost of declining a good customer are not in the loss.
- Category risk assumes labels from the training window are known before the validation period starts. A longer chargeback lag than that gap would make the rate unavailable.
- Camouflage fraud has no feature signal. Catching it would mean the model had seen the label, which this design treats as a failure.
- No drift, seasonality beyond day of week, or adversary adapting to the score is simulated.

## Reproduce

```
python run_pipeline.py
python -m pytest tests
```

Stack: Python 3.14.3, numpy 2.5.3, pandas 3.0.6, scikit-learn 1.9.1.
