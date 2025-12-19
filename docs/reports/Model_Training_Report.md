# Model Training Report
## Fraud Detection Model Training Pipeline

**Date:** [Add Date]  
**Project:** CNP Fraud Detection  
**Dataset:** Credit Card Fraud Detection (Synthetic/Feature-Engineered)

---

## Executive Summary

This report documents the model training pipeline for fraud detection. The pipeline implements multiple machine learning models with cost-sensitive learning, class imbalance handling, and threshold optimization to minimize business costs.

---

## 1. Configuration

### 1.1 Cost Configuration

**Cost Structure:**
- **False Negative Cost (FN)**: 10 units
  - *Definition*: Cost of missing a fraudulent transaction
  - *Impact*: High cost due to financial loss and customer trust issues
  
- **False Positive Cost (FP)**: 1 unit
  - *Definition*: Cost of flagging a legitimate transaction as fraud
  - *Impact*: Lower cost, mainly customer inconvenience

**Cost Ratio:** 10:1 (FN:FP)

**Rationale:**
- Missing a fraud (False Negative) is significantly more expensive than a false alarm (False Positive)
- The model should prioritize catching frauds, even if it means more false alarms
- This cost structure encourages higher recall (sensitivity) at the expense of precision

### 1.2 Data Split Configuration

**Train/Validation/Test Split:**
- **Training Set**: 70% of data
  - Used for model training
  - Largest portion to maximize learning
  
- **Validation Set**: 15% of data
  - Used for hyperparameter tuning
  - Used for threshold optimization
  - Prevents overfitting
  
- **Test Set**: 15% of data
  - Used for final model evaluation
  - Held out until final evaluation
  - Provides unbiased performance estimate

**Split Method:** Stratified random sampling
- Maintains class distribution across all splits
- Ensures representative samples for rare fraud class

---

## 2. Models Implemented

### 2.1 Logistic Regression (Baseline Model)

**Purpose:** Interpretable baseline model

**Characteristics:**
- Linear model with interpretable coefficients
- Provides feature importance through coefficients
- Fast training and prediction
- Good for understanding which features matter

**Class Imbalance Handling:**
- Inverse frequency class weights
- Weight for fraud class: `total_samples / (2 × fraud_samples)`
- Weight for non-fraud class: `total_samples / (2 × non_fraud_samples)`

**Advantages:**
- Highly interpretable
- Fast training
- No hyperparameters to tune
- Feature importance directly from coefficients

**Limitations:**
- Assumes linear relationships
- May not capture complex patterns
- Lower performance on non-linear data

### 2.2 LightGBM (High-Performance Model)

**Purpose:** Gradient boosting for high performance

**Characteristics:**
- Gradient boosting framework
- Handles non-linear relationships
- Feature interactions automatically
- High predictive performance

**Class Imbalance Handling:**
- Class weights in training data
- `scale_pos_weight` parameter
- Ratio: `fraud_weight / non_fraud_weight`

**Hyperparameters:**
- `num_leaves`: 31
- `learning_rate`: 0.05
- `feature_fraction`: 0.8
- `bagging_fraction`: 0.8
- `min_data_in_leaf`: 20
- Early stopping: 50 rounds

**Advantages:**
- High performance
- Handles complex patterns
- Feature importance available
- Fast training

**Limitations:**
- Less interpretable than logistic regression
- Requires hyperparameter tuning
- More complex model

### 2.3 XGBoost (Alternative High-Performance Model)

**Purpose:** Alternative gradient boosting model

**Characteristics:**
- Similar to LightGBM but different implementation
- Robust gradient boosting
- Good for comparison with LightGBM

**Class Imbalance Handling:**
- Class weights in training data
- `scale_pos_weight` parameter

**Hyperparameters:**
- `max_depth`: 6
- `eta` (learning_rate): 0.1
- `subsample`: 0.8
- `colsample_bytree`: 0.8
- `min_child_weight`: 3
- Early stopping: 50 rounds

**Advantages:**
- High performance
- Robust implementation
- Good for comparison

**Limitations:**
- Less interpretable
- Requires hyperparameter tuning

---

## 3. Class Imbalance Handling

### 3.1 Problem

Fraud detection datasets are highly imbalanced:
- **Fraud Rate**: ~0.17% (very rare)
- **Non-Fraud Rate**: ~99.83% (majority class)

Without handling imbalance, models tend to:
- Predict majority class (non-fraud) for everything
- Achieve high accuracy but poor fraud detection
- Miss most fraudulent transactions

### 3.2 Solution: Class Weights

**Approach:** Inverse frequency weighting

**Formula:**
```
weight_fraud = total_samples / (2 × fraud_samples)
weight_non_fraud = total_samples / (2 × non_fraud_samples)
```

**Effect:**
- Fraud samples get higher weight during training
- Model pays more attention to fraud cases
- Balances the learning process

**Implementation:**
- Logistic Regression: Sample weights in `glm()`
- LightGBM: `scale_pos_weight` parameter
- XGBoost: `scale_pos_weight` parameter

---

## 4. Cost-Sensitive Learning

### 4.1 Cost Function

**Total Cost Calculation:**
```
Total Cost = (FN × COST_FALSE_NEGATIVE) + (FP × COST_FALSE_POSITIVE)
```

**Cost per Transaction:**
```
Cost per Transaction = Total Cost / Number of Transactions
```

### 4.2 Threshold Optimization

**Process:**
1. Train model on training set
2. Get probability predictions on validation set
3. Test thresholds from 0.01 to 0.99 (step 0.01)
4. Calculate cost for each threshold
5. Select threshold with minimum cost

**Why Validation Set?**
- Prevents overfitting to test set
- Provides unbiased threshold selection
- Allows fair comparison across models

**Result:**
- Each model gets its own optimal threshold
- Thresholds typically lower than 0.5 (to catch more frauds)
- Optimized for business cost, not just accuracy

---

## 5. Evaluation Metrics

### 5.1 Standard Metrics

**Accuracy:**
- Overall correctness: `(TP + TN) / (TP + TN + FP + FN)`
- May be misleading with imbalanced data

**Precision:**
- Of predicted frauds, how many are actually fraud: `TP / (TP + FP)`
- Measures false alarm rate

**Recall (Sensitivity):**
- Of actual frauds, how many are caught: `TP / (TP + FN)`
- **Most important for fraud detection**
- Measures fraud detection rate

**Specificity:**
- Of actual non-frauds, how many are correctly identified: `TN / (TN + FP)`
- Measures legitimate transaction identification

**F1-Score:**
- Harmonic mean of precision and recall: `2 × (Precision × Recall) / (Precision + Recall)`
- Balances precision and recall

### 5.2 Cost Metrics

**Total Cost:**
- Sum of all costs: `(FN × 10) + (FP × 1)`
- Business impact measure

**Cost per Transaction:**
- Average cost normalized by number of transactions
- **Primary metric for model selection**
- Lower is better

### 5.3 Confusion Matrix

```
                Predicted
              Non-Fraud  Fraud
Actual
Non-Fraud        TN       FP
Fraud            FN       TP
```

**Interpretation:**
- **TP (True Positive)**: Correctly identified frauds
- **TN (True Negative)**: Correctly identified legitimate transactions
- **FP (False Positive)**: Legitimate transactions flagged as fraud
- **FN (False Negative)**: Fraudulent transactions missed

---

## 6. Training Process

### 6.1 Data Preparation

**Steps:**
1. Load complete feature-engineered dataset
2. Identify target variable (Class or fraud_label)
3. Select feature columns (exclude IDs, timestamps, non-numeric)
4. Handle missing values (median imputation)
5. Prepare feature matrices

### 6.2 Model Training

**For Each Model:**
1. Prepare data format (dataframe, matrix, or DMatrix)
2. Apply class weights
3. Train model with appropriate parameters
4. Use early stopping (for LightGBM/XGBoost) to prevent overfitting

### 6.3 Threshold Optimization

**For Each Model:**
1. Get probability predictions on validation set
2. Test 99 thresholds (0.01 to 0.99)
3. Calculate cost for each threshold
4. Select optimal threshold (minimum cost)

### 6.4 Evaluation

**For Each Model:**
1. Evaluate on validation set with optimal threshold
2. Evaluate on test set with optimal threshold
3. Calculate all metrics
4. Compare performance

---

## 7. Results

### 7.1 Model Comparison (Test Set)

**Complete Model Comparison Table:**

| Model | Threshold | Accuracy | Precision | Recall | F1-Score | Cost/Transaction |
|-------|-----------|----------|-----------|--------|----------|------------------|
| Logistic Regression | 0.970 | 0.9961 | 0.8333 | 0.3659 | 0.5085 | 0.0351 |
| **LightGBM** | **0.030** | **0.9851** | **0.2370** | **0.7805** | **0.3636** | **0.0257** ⭐ |
| XGBoost | 0.070 | 0.9932 | 0.4000 | 0.4878 | 0.4396 | 0.0320 |

**Key Observations:**
- **LightGBM** achieves the lowest cost per transaction (0.0257)
- **LightGBM** has the highest recall (78.05%) - catches most frauds
- **Logistic Regression** has the highest precision (83.33%) but lowest recall
- **XGBoost** provides balanced performance between the two extremes
- All models show high accuracy (>98%) due to class imbalance

### 7.2 Detailed Model Performance

#### 7.2.1 Logistic Regression (Test Set)

**Performance Metrics:**
- **Accuracy**: 99.61%
- **Precision**: 83.33%
- **Recall (Sensitivity)**: 36.59%
- **Specificity**: 99.96%
- **F1-Score**: 0.5085
- **Cost per Transaction**: 0.0351

**Confusion Matrix:**
- True Positives (TP): 15
- True Negatives (TN): 7,456
- False Positives (FP): 3
- False Negatives (FN): 26

**Analysis:**
- Very high precision (83.33%) - when it predicts fraud, it's usually correct
- Low recall (36.59%) - misses many frauds (26 out of 41)
- Very conservative threshold (0.970) - only predicts fraud when very confident
- Low false positive rate (only 3 false alarms)
- Higher cost per transaction (0.0351) due to missed frauds

#### 7.2.2 LightGBM (Test Set)

**Performance Metrics:**
- **Accuracy**: 98.51%
- **Precision**: 23.70%
- **Recall (Sensitivity)**: 78.05%
- **Specificity**: 98.62%
- **F1-Score**: 0.3636
- **Cost per Transaction**: 0.0257

**Confusion Matrix:**
- True Positives (TP): 32
- True Negatives (TN): 7,356
- False Positives (FP): 103
- False Negatives (FN): 9

**Analysis:**
- Much higher recall (78.05%) - catches most frauds (32 out of 41)
- Lower precision (23.70%) - more false alarms (103)
- Aggressive threshold (0.030) - predicts fraud more often
- Lower cost per transaction (0.0257) - best cost performance
- Better for cost-sensitive learning (FN cost >> FP cost)

### 7.3 Best Model Selection

**Selection Criteria:** Lowest cost per transaction on test set

**Best Model:** **LightGBM** (Cost per Transaction: 0.0257)

**Final Model Ranking (by Cost per Transaction):**
1. **LightGBM**: 0.0257 (Best - Lowest Cost) ⭐
   - Recall: 78.05%
   - Catches 32 out of 41 frauds (78%)
   - Optimal threshold: 0.030
   
2. **XGBoost**: 0.0320 (Second)
   - Recall: 48.78%
   - Catches 20 out of 41 frauds (49%)
   - Optimal threshold: 0.070
   
3. **Logistic Regression**: 0.0351 (Third)
   - Recall: 36.59%
   - Catches 15 out of 41 frauds (37%)
   - Optimal threshold: 0.970

**Best Model Selection Results:**
```
✓ Best Model (Lowest Cost): LightGBM
  Cost per Transaction: 0.0257
  Recall: 0.7805
```

**Selection Rationale:**
- Lowest cost per transaction (0.0257 vs 0.0320 and 0.0351)
- Highest recall (78.05% vs 48.78% and 36.59%)
- Catches significantly more frauds (32 vs 20 vs 15)
- Best aligned with cost structure (FN cost = 10, FP cost = 1)
- Despite lower precision, the cost savings from catching more frauds outweigh false positive costs

**Rationale:**
- Lowest cost per transaction (0.0257 vs 0.0351 for Logistic Regression)
- Much higher recall (78.05% vs 36.59%) - catches more frauds
- Only misses 9 frauds vs 26 for Logistic Regression
- Better aligned with cost structure (FN cost = 10, FP cost = 1)
- Despite lower precision, the cost savings from catching more frauds outweigh the cost of false positives

**Trade-offs:**
- More false positives (103 vs 3) but acceptable given low FP cost
- Lower precision but higher overall business value

#### 7.2.3 XGBoost (Test Set)

**Performance Metrics:**
- **Accuracy**: 99.32%
- **Precision**: 40.00%
- **Recall (Sensitivity)**: 48.78%
- **Specificity**: 99.60%
- **F1-Score**: 0.4396
- **Cost per Transaction**: 0.0320

**Confusion Matrix:**
- True Positives (TP): 20
- True Negatives (TN): 7,429
- False Positives (FP): 30
- False Negatives (FN): 21

**Analysis:**
- Moderate recall (48.78%) - catches about half of frauds (20 out of 41)
- Moderate precision (40.00%) - better than LightGBM, worse than Logistic Regression
- Balanced threshold (0.070) - middle ground between LR and LightGBM
- Moderate false positive rate (30 false alarms)
- Cost per transaction (0.0320) - between LR and LightGBM
- Good balance between precision and recall

### 7.4 Feature Importance

#### Top 20 Features (Logistic Regression):

1. **ip_geo_mismatch** (21.48) - IP country ≠ billing country (strongest predictor)
2. **shared_address_count** (-16.81) - Lower shared addresses = higher fraud risk
3. **day_of_month** (-14.09) - Day of month indicator
4. **email_domain_risk** (1.43) - Email domain risk score
5. **high_risk_geo_flag** (1.31) - High-risk geographic location
6. **hour_of_day** (-0.58) - Time of day
7. **weekend_flag** (0.50) - Weekend transaction indicator
8. **V3** (0.45) - PCA feature
9. **rapid_transaction_flag** (-0.31) - Rapid transaction indicator
10. **V25** (0.31) - PCA feature

**Key Insights:**
- Placeholder features (ip_geo_mismatch, email_domain_risk, high_risk_geo_flag) are among top predictors
- Identity consistency features are highly important
- Time-based features (hour_of_day, weekend_flag) are significant

#### Top 20 Features (LightGBM):

1. **time_since_previous** (5.92%) - Time since previous transaction (most important)
2. **Time** (5.46%) - Transaction timing
3. **hour_of_day** (4.37%) - Hour of day
4. **V11** (3.81%) - PCA feature
5. **V16** (3.78%) - PCA feature
6. **V9** (3.56%) - PCA feature
7. **V3** (3.39%) - PCA feature
8. **V18** (3.28%) - PCA feature
9. **V19** (3.26%) - PCA feature
10. **V21** (3.15%) - PCA feature
11. **V25** (3.02%) - PCA feature
12. **V27** (3.00%) - PCA feature
13. **V7** (2.94%) - PCA feature
14. **Amount** (2.92%) - Transaction amount
15. **V6** (2.71%) - PCA feature

**Key Insights:**
- Time-based features are most important (time_since_previous, Time, hour_of_day)
- Velocity features are critical for fraud detection
- Original PCA features (V1-V28) remain important
- Transaction amount is in top features

#### Top 20 Features (XGBoost):

1. **V27** (6.76%) - PCA feature (most important)
2. **email_domain_risk** (6.33%) - Email domain risk score (placeholder feature)
3. **ip_geo_mismatch** (6.22%) - IP country ≠ billing country (placeholder feature)
4. **Time** (4.95%) - Transaction timing
5. **V3** (4.52%) - PCA feature
6. **V9** (3.62%) - PCA feature
7. **V26** (3.50%) - PCA feature
8. **V18** (3.44%) - PCA feature
9. **time_since_previous** (3.43%) - Time since previous transaction
10. **V6** (3.42%) - PCA feature
11. **V13** (3.38%) - PCA feature
12. **V17** (3.35%) - PCA feature
13. **Amount** (3.26%) - Transaction amount
14. **V21** (3.20%) - PCA feature
15. **V5** (2.91%) - PCA feature
16. **hour_of_day** (2.72%) - Hour of day
17. **V25** (2.71%) - PCA feature
18. **device_reuse_count** (2.61%) - Device reuse count (placeholder feature)
19. **V15** (2.19%) - PCA feature
20. **V10** (2.16%) - PCA feature

**Key Insights:**
- Placeholder features are highly important (email_domain_risk, ip_geo_mismatch, device_reuse_count)
- Original PCA features (V27, V3, V9, etc.) remain critical
- Time-based features (Time, time_since_previous, hour_of_day) are significant
- Transaction amount is important
- Identity consistency features (ip_geo_mismatch, device_reuse_count) are top predictors

---

## 8. Model Artifacts

### 8.1 Saved Models

All models are saved to `models/` directory:

1. **`logistic_regression_model.rds`**
   - RDS format (R native)
   - Load with: `readRDS("models/logistic_regression_model.rds")`

2. **`lightgbm_model.txt`**
   - LightGBM native format
   - Load with: `lgb.load("models/lightgbm_model.txt")`

3. **`xgboost_model.model`**
   - XGBoost native format
   - Load with: `xgb.load("models/xgboost_model.model")`

### 8.2 Saved Thresholds

**File:** `models/optimal_thresholds.csv`

Contains optimal threshold for each model:
- Used for predictions in production
- Different for each model
- Optimized for cost minimization

### 8.3 Comparison Results

**File:** `models/model_comparison.csv`

Contains comparison of all models on test set:
- All metrics for each model
- Used for model selection
- Documents final performance

---

## 9. Recommendations

### 9.1 Model Selection

*[To be added after results]*

### 9.2 Production Deployment

1. **Use Best Model**: Deploy model with lowest cost
2. **Monitor Performance**: Track metrics over time
3. **Set Alerts**: Alert on performance degradation
4. **Retrain Periodically**: Update model with new data

### 9.3 Threshold Adjustment

- **If too many false positives**: Increase threshold slightly
- **If missing too many frauds**: Decrease threshold slightly
- **Monitor business impact**: Adjust based on actual costs

### 9.4 Cost Configuration

- **Review periodically**: Adjust costs based on business changes
- **A/B testing**: Test different cost ratios
- **Business alignment**: Ensure costs reflect actual business impact

---

## 10. Next Steps

1. **Run Training Script**: Execute `train_fraud_models.R`
2. **Review Results**: Analyze model performance
3. **Select Best Model**: Choose model with lowest cost
4. **Deploy Model**: Use best model for predictions
5. **Monitor Performance**: Track metrics in production
6. **Retrain Periodically**: Update models with new data

---

## 11. Technical Details

### 11.1 Software Versions

- **R Version**: *[Add version]*
- **Package Versions**: *[Add versions]*

### 11.2 Computational Resources

- **Training Time**: *[To be added]*
- **Memory Usage**: *[To be added]*
- **CPU Usage**: *[To be added]*

### 11.3 Dataset Information

- **Total Samples**: *[To be added]*
- **Features**: *[To be added]*
- **Fraud Rate**: *[To be added]*
- **Train/Val/Test Split**: 70% / 15% / 15%

---

## Appendix

### A. Cost Configuration Rationale

The 10:1 cost ratio (FN:FP) reflects:
- Financial loss from fraud
- Customer trust impact
- Regulatory compliance
- Operational costs

### B. Threshold Selection Process

1. Train model → Get probabilities
2. Test thresholds (0.01 to 0.99)
3. Calculate cost for each threshold
4. Select minimum cost threshold
5. Apply to test set for final evaluation

### C. Class Weight Calculation

```r
fraud_count <- sum(y_train)
non_fraud_count <- sum(y_train == 0)
total_count <- length(y_train)

weight_fraud <- total_count / (2 * fraud_count)
weight_non_fraud <- total_count / (2 * non_fraud_count)
```

---

**Report Status:** ✅ *Training Results Complete*

**Last Updated:** [Current Date]

**Summary:**
- ✅ Logistic Regression: Trained and evaluated (Cost: 0.0351)
- ✅ LightGBM: Trained and evaluated (Best Model - Cost: 0.0257)
- ✅ XGBoost: Trained and evaluated (Cost: 0.0320)

**Best Model:** **LightGBM** (Cost per Transaction: 0.0257)

**Key Findings:**
- LightGBM achieves lowest cost (0.0257) with highest recall (78.05%)
- XGBoost provides balanced performance (0.0320 cost, 48.78% recall)
- Logistic Regression has highest precision (83.33%) but misses many frauds
- Placeholder features (ip_geo_mismatch, email_domain_risk, device_reuse_count) are among top predictors across all models
- Time-based features are critical for fraud detection

**Note:** XGBoost training completed with a deprecation warning about 'watchlist' parameter (will be renamed to 'evals' in future versions). This does not affect model performance.

