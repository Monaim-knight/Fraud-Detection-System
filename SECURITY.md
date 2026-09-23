# Security

This study uses a synthetic book. Do not point the pipeline at live card data, and do not commit customer files, PANs, credentials, or model artifacts trained on real transactions.

`artifacts/policy.joblib` is a local output. Treat a model trained outside this synthetic book as sensitive even when the training rows are not stored beside it.
