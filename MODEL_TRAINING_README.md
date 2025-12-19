# Model Training Pipeline - README

## Overview

This script implements a comprehensive fraud detection model training pipeline with:
1. **Logistic Regression** - Baseline interpretable model
2. **LightGBM** - High-performance gradient boosting
3. **XGBoost** - Alternative high-performance model
4. **Class Imbalance Handling** - Using class weights
5. **Cost-Sensitive Learning** - Optimizing for cost (FN more expensive than FP)
6. **Threshold Tuning** - Finding optimal decision threshold

## Installation

### Required R Packages

```r
# Core packages
install.packages(c("readr", "dplyr", "caret", "pROC"))

# For handling class imbalance
install.packages("ROSE")

# For LightGBM (high-performance model)
install.packages("lightgbm")

# For XGBoost (alternative high-performance model)
install.packages("xgboost")
```

### Optional: Install LightGBM from GitHub (if CRAN version doesn't work)

```r
# Install devtools if needed
install.packages("devtools")

# Install LightGBM from GitHub
devtools::install_github("Microsoft/LightGBM", subdir = "R-package")
```

## Usage

### Basic Usage

```r
# Run the training pipeline
source("train_fraud_models.R")
```

### Configuration

You can modify the cost configuration at the top of the script:

```r
# Cost configuration (false negatives are more expensive)
COST_FALSE_NEGATIVE <- 10  # Cost of missing a fraud (high cost)
COST_FALSE_POSITIVE <- 1   # Cost of flagging legitimate transaction (low cost)
```

Adjust these values based on your business requirements:
- **Higher COST_FALSE_NEGATIVE**: More aggressive fraud detection (fewer missed frauds, more false alarms)
- **Lower COST_FALSE_NEGATIVE**: More conservative (fewer false alarms, but may miss some frauds)

## Pipeline Steps

### Step 1: Load Complete Dataset
- Automatically finds and loads the feature-engineered dataset
- Checks multiple possible locations

### Step 2: Data Preparation
- Identifies target variable (Class or fraud_label)
- Selects feature columns (excludes IDs, timestamps, non-numeric columns)
- Handles missing values

### Step 3: Train/Validation/Test Split
- 70% training, 15% validation, 15% test
- Stratified split to maintain class distribution

### Step 4: Cost-Sensitive Evaluation
- Defines cost calculation function
- Implements threshold optimization based on cost

### Step 5: Logistic Regression
- Baseline interpretable model
- Uses class weights to handle imbalance
- Provides feature importance (coefficients)
- Finds optimal threshold on validation set
- Evaluates on test set

### Step 6: LightGBM
- High-performance gradient boosting model
- Uses class weights and scale_pos_weight
- Early stopping to prevent overfitting
- Feature importance analysis
- Optimal threshold tuning

### Step 7: XGBoost
- Alternative high-performance model
- Similar configuration to LightGBM
- Feature importance analysis
- Optimal threshold tuning

### Step 8: Model Comparison
- Compares all models on test set
- Identifies best model (lowest cost)
- Creates comparison table

### Step 9: Save Models and Results
- Saves all trained models
- Saves optimal thresholds
- Saves comparison results

## Output Files

All outputs are saved to `models/` directory:

1. **`logistic_regression_model.rds`** - Trained logistic regression model
2. **`lightgbm_model.txt`** - Trained LightGBM model (if available)
3. **`xgboost_model.model`** - Trained XGBoost model (if available)
4. **`optimal_thresholds.csv`** - Optimal thresholds for each model
5. **`model_comparison.csv`** - Comparison of all models

## Metrics Explained

### Standard Metrics:
- **Accuracy**: Overall correctness
- **Precision**: Of predicted frauds, how many are actually fraud
- **Recall (Sensitivity)**: Of actual frauds, how many are caught
- **Specificity**: Of actual non-frauds, how many are correctly identified
- **F1-Score**: Harmonic mean of precision and recall

### Cost Metrics:
- **Total Cost**: Sum of (FN × COST_FALSE_NEGATIVE) + (FP × COST_FALSE_POSITIVE)
- **Cost per Transaction**: Average cost normalized by number of transactions

### Why Cost Matters:
- **False Negatives (FN)**: Missing a fraud is expensive (lost money, customer trust)
- **False Positives (FP)**: Flagging legitimate transaction is less expensive (just inconvenience)
- The model optimizes for the threshold that minimizes total cost

## Model Selection

The script automatically selects the best model based on **lowest cost per transaction** on the test set.

However, consider:
- **Logistic Regression**: Best for interpretability, understanding which features matter
- **LightGBM/XGBoost**: Best for performance, but less interpretable

## Threshold Tuning

The script finds the optimal threshold by:
1. Testing thresholds from 0.01 to 0.99
2. Calculating cost for each threshold
3. Selecting the threshold with minimum cost

This is done on the **validation set** to avoid overfitting.

## Class Imbalance Handling

The script handles class imbalance using:
1. **Class Weights**: Inverse frequency weighting
2. **scale_pos_weight**: For LightGBM/XGBoost (ratio of negative to positive class)

This ensures the model doesn't just predict the majority class.

## Next Steps

After training:

1. **Analyze Feature Importance**: Understand which features are most predictive
2. **Tune Hyperparameters**: Adjust model parameters for better performance
3. **Deploy Best Model**: Use the best model for production
4. **Monitor Performance**: Track model performance over time
5. **Retrain Periodically**: Update models with new data

## Troubleshooting

### Issue: "lightgbm package not installed"
**Solution**: Install with `install.packages("lightgbm")` or from GitHub (see Installation section)

### Issue: "xgboost package not installed"
**Solution**: Install with `install.packages("xgboost")`

### Issue: Model performance is poor
**Solutions**:
- Check feature quality
- Try different class weight ratios
- Adjust cost configuration
- Try different hyperparameters
- Check for data leakage

### Issue: Too many false positives
**Solution**: Increase COST_FALSE_POSITIVE relative to COST_FALSE_NEGATIVE

### Issue: Too many false negatives
**Solution**: Increase COST_FALSE_NEGATIVE relative to COST_FALSE_POSITIVE

---

**The model training pipeline is ready to use!**






