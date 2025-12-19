# Model Evaluation and Analysis - README

## Overview

This script performs comprehensive model evaluation including:
1. **Advanced Metrics**: Predictions, Recall, PR AUC, Expected Cost Saved
2. **Segment Analysis**: Performance by merchant, geography, account age
3. **Temporal Validation**: Train on past months, test on future months

## Installation

### Required R Packages

```r
# Core packages
install.packages(c("readr", "dplyr", "caret", "pROC"))

# For PR AUC calculation
install.packages("PRROC")

# For visualizations
install.packages(c("ggplot2", "gridExtra"))

# For pivot operations
install.packages("tidyr")

# Model packages (if not already installed)
install.packages(c("lightgbm", "xgboost"))
```

## Usage

```r
# Run the evaluation script
source("evaluate_models.R")
```

## What the Script Does

### Step 1: Load Data and Models
- Loads the feature-engineered dataset
- Loads all trained models (Logistic Regression, LightGBM, XGBoost)
- Loads optimal thresholds

### Step 2: Prepare Data
- Prepares feature matrices
- Handles missing values
- Matches training data format

### Step 3: Advanced Metrics Calculation

**Metrics Calculated:**
- **Standard Metrics**: Accuracy, Precision, Recall, Specificity, F1-Score
- **ROC AUC**: Area under ROC curve
- **PR AUC**: Area under Precision-Recall curve (better for imbalanced data)
- **Cost Metrics**: Total cost, cost per transaction
- **Expected Cost Saved**: Cost saved compared to no model (all transactions approved)

**Output:** `comprehensive_metrics.csv`

### Step 4: Segment Analysis

**Segments Analyzed:**
- Merchant (if `merchant_id` or `merchant` column exists)
- Geography (if `country`, `ip_country`, `billing_country` exists)
- Account Age (if `account_age`, `customer_age_days` exists)

**For Each Segment:**
- Total transactions
- Fraud count and rate
- Model performance (Recall, Precision, F1, ROC AUC, PR AUC)
- Cost metrics

**Output:** `segment_analysis.csv`

### Step 5: Temporal Validation

**Process:**
1. Split data by time (70% past for training, 30% future for testing)
2. Train models on past data
3. Evaluate on future data
4. Compare performance across time periods

**Purpose:**
- Tests model generalization over time
- Identifies if model performance degrades over time
- Validates that past patterns predict future fraud

**Output:** `temporal_validation.csv`

### Step 6: Visualizations

**Generated Plots:**
1. **ROC Curves**: Comparison of all models
2. **Precision-Recall Curves**: Better for imbalanced data
3. **Metrics Comparison Bar Chart**: Side-by-side comparison

**Output:** 
- `roc_curves.png`
- `pr_curves.png`
- `metrics_comparison.png`

## Output Files

All outputs are saved to `evaluation/` directory:

1. **`comprehensive_metrics.csv`**
   - All metrics for all models
   - Includes ROC AUC, PR AUC, Cost Saved

2. **`segment_analysis.csv`**
   - Performance by segment
   - Identifies high-risk segments

3. **`temporal_validation.csv`**
   - Performance on temporal train/test split
   - Tests model stability over time

4. **Visualizations:**
   - `roc_curves.png` - ROC curves for all models
   - `pr_curves.png` - Precision-Recall curves
   - `metrics_comparison.png` - Bar chart comparison

## Metrics Explained

### ROC AUC (Area Under ROC Curve)
- Measures ability to distinguish between classes
- Range: 0 to 1 (higher is better)
- 0.5 = random, 1.0 = perfect
- Good for balanced datasets

### PR AUC (Area Under Precision-Recall Curve)
- Better metric for imbalanced datasets
- Range: 0 to 1 (higher is better)
- Focuses on positive class (fraud)
- More informative than ROC AUC for fraud detection

### Expected Cost Saved
- Compares model cost vs. no model scenario
- Without model: All transactions approved = all frauds cost FN × count
- With model: Cost = (FN × COST_FALSE_NEGATIVE) + (FP × COST_FALSE_POSITIVE)
- Cost Saved = Cost without model - Cost with model
- Shows business value of the model

## Segment Analysis

### Purpose
- Identify high-risk segments
- Understand where model performs well/poorly
- Target interventions to specific segments

### Example Insights
- "Merchant X has 5% fraud rate vs 0.17% overall"
- "Country Y has poor model performance (low recall)"
- "New accounts (< 30 days) have higher fraud rate"

## Temporal Validation

### Purpose
- Test if model trained on past data works on future data
- Detect concept drift (fraud patterns changing over time)
- Validate model stability

### Expected Results
- If performance is similar: Model is stable
- If performance degrades: May need retraining or feature updates

## Troubleshooting

### Issue: "No segment columns found"
**Solution**: The script will create a placeholder. Add segment columns to your dataset if needed.

### Issue: "No timestamp column found"
**Solution**: The script will skip temporal validation. Ensure `transaction_timestamp_utc` or `Time` column exists.

### Issue: "PRROC package not installed"
**Solution**: Install with `install.packages("PRROC")`

### Issue: Segment analysis is slow
**Solution**: The script limits to top 20 segments per type to avoid too many segments.

## Next Steps

After evaluation:

1. **Review Metrics**: Identify best performing model
2. **Analyze Segments**: Find high-risk segments for targeted interventions
3. **Check Temporal Performance**: Ensure model works on future data
4. **Update Model**: If performance degrades, retrain with recent data
5. **Deploy**: Use best model for production

---

**The evaluation script is ready to use!**






