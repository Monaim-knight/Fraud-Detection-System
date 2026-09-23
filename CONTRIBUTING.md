# Contributing

Run `python -m pytest tests` before sending a change. A change that computes a reported metric on rows the model was fit on, or that selects a threshold on the test window, should not be merged.

The numbers in `reports/evaluation.md` come from `run_pipeline.py`. Regenerate the memo rather than editing its results by hand.

The book is synthetic. Do not add a real card file to the repository.
