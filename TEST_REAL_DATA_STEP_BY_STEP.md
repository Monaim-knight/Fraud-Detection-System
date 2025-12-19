# Step-by-Step Guide: Testing with Real Transaction Data

This guide allows you to test the deployment with real data manually, one step at a time.

---

## Quick Start

**Option 1: Run Full Script**
source("test_with_real_data.R")

**Option 2: Step-by-Step (see below)**

---

## Step 1: Load Required Libraries

library(readr)
library(dplyr)
library(lightgbm)

**Expected Output:**
```
[Libraries loaded]
```

---

## Step 2: Load Real Transaction Data

# Set path to your dataset
dataset_path <- "cnp_dataset/feature_engineered/creditcard_features_complete.csv"

# Check if file exists
if (!file.exists(dataset_path)) {
  cat("✗ Dataset not found\n")
  stop("Please check the path")
}

# Load transactions (start with 1000 for testing)
df <- read_csv(dataset_path, n_max = 1000, show_col_types = FALSE)

cat(sprintf("✓ Loaded %d transactions\n", nrow(df)))
cat(sprintf("  Columns: %d\n", ncol(df)))

# Check for fraud labels
if ("Class" %in% colnames(df)) {
  fraud_count <- sum(df$Class == 1, na.rm = TRUE)
  cat(sprintf("  Fraud transactions: %d (%.2f%%)\n", 
              fraud_count, fraud_count/nrow(df)*100))
}

**Expected Output:**
```
✓ Loaded 1000 transactions
  Columns: 66
  Fraud transactions: X (X.XX%)
```

---

## Step 3: Load Required Features

# Load features list
features <- read_lines("deployment/features.txt")

cat(sprintf("✓ Loaded %d required features\n", length(features)))

# Check which features are in the dataset
available_features <- features[features %in% colnames(df)]
missing_features <- features[!features %in% colnames(df)]

cat(sprintf("  Available: %d\n", length(available_features)))
cat(sprintf("  Missing: %d\n", length(missing_features)))

if (length(missing_features) > 0) {
  cat("  Missing features:", paste(missing_features, collapse = ", "), "\n")
}

**Expected Output:**
```
✓ Loaded 48 required features
  Available: 48
  Missing: 0
```

---

## Step 4: Prepare Data for Prediction

# Select available features
test_data <- df %>% select(all_of(available_features))

# Add missing features with default 0
if (length(missing_features) > 0) {
  for (feat in missing_features) {
    test_data[[feat]] <- 0
  }
}

# Ensure correct feature order
test_data <- test_data %>% select(all_of(features))

cat(sprintf("✓ Prepared: %d rows, %d columns\n", nrow(test_data), ncol(test_data)))
cat(sprintf("✓ All features present: %s\n", all(features %in% colnames(test_data))))

**Expected Output:**
```
✓ Prepared: 1000 rows, 48 columns
✓ All features present: TRUE
```

---

## Step 5: Load Model and Threshold

# Load model
cat("Loading model...\n")
model <- lgb.load("deployment/lightgbm_model.txt")
cat("✓ Model loaded\n")

# Load threshold
thresholds <- read_csv("deployment/thresholds.csv", show_col_types = FALSE)

# Check column names (they might be lowercase)
cat("Thresholds file columns:", paste(colnames(thresholds), collapse = ", "), "\n")
print(thresholds)

# Get threshold (use lowercase column names and model name)
if ("threshold" %in% colnames(thresholds) && "model" %in% colnames(thresholds)) {
  lightgbm_threshold <- thresholds$threshold[thresholds$model == "lightgbm"]
} else if ("Threshold" %in% colnames(thresholds) && "Model" %in% colnames(thresholds)) {
  lightgbm_threshold <- thresholds$Threshold[thresholds$Model == "LightGBM"]
} else {
  cat("⚠ Warning: Could not find threshold columns. Using default: 0.170\n")
  lightgbm_threshold <- 0.170
}

if (length(lightgbm_threshold) == 0 || is.na(lightgbm_threshold)) {
  cat("⚠ Warning: LightGBM threshold not found. Using default: 0.170\n")
  lightgbm_threshold <- 0.170
}

cat(sprintf("✓ Threshold: %.3f\n", lightgbm_threshold))

**Expected Output:**
```
Loading model...
✓ Model loaded
✓ Threshold: 0.170
```

---

## Step 6: Make Predictions

# Convert to matrix
test_matrix <- as.matrix(test_data)

# Get probabilities
cat("Generating predictions...\n")
pred_proba <- predict(model, test_matrix)

# Apply threshold
pred_binary <- ifelse(pred_proba >= lightgbm_threshold, 1, 0)

cat(sprintf("✓ Predictions generated\n"))
cat(sprintf("  Fraud predictions: %d\n", sum(pred_binary == 1)))
cat(sprintf("  Non-fraud predictions: %d\n", sum(pred_binary == 0)))

**Expected Output:**
```
Generating predictions...
✓ Predictions generated
  Fraud predictions: X
  Non-fraud predictions: X
```

---

## Step 7: Create Results DataFrame

# Create results
results <- data.frame(
  transaction_id = if ("transaction_id" %in% colnames(df)) df$transaction_id else 1:nrow(df),
  fraud_probability = pred_proba,
  fraud_prediction = pred_binary,
  threshold_used = lightgbm_threshold
)

# Add actual labels if available
if ("Class" %in% colnames(df)) {
  results$actual_label <- df$Class
  results$is_correct <- ifelse(results$fraud_prediction == results$actual_label, 1, 0)
}

cat("✓ Results dataframe created\n")
cat(sprintf("  Rows: %d\n", nrow(results)))
cat(sprintf("  Columns: %d\n", ncol(results)))

**Expected Output:**
```
✓ Results dataframe created
  Rows: 1000
  Columns: 6
```

---

## Step 8: Analyze Predictions

# Basic statistics
cat("\nPrediction Statistics:\n")
cat(sprintf("  Total: %d\n", nrow(results)))
cat(sprintf("  Fraud predicted: %d (%.2f%%)\n",
            sum(results$fraud_prediction == 1),
            sum(results$fraud_prediction == 1)/nrow(results)*100))

cat("\nProbability Distribution:\n")
cat(sprintf("  Min: %.4f\n", min(results$fraud_probability)))
cat(sprintf("  Max: %.4f\n", max(results$fraud_probability)))
cat(sprintf("  Mean: %.4f\n", mean(results$fraud_probability)))
cat(sprintf("  Median: %.4f\n", median(results$fraud_probability)))

# High-risk transactions
high_risk <- sum(results$fraud_probability > 0.5)
very_high_risk <- sum(results$fraud_probability > 0.8)

cat(sprintf("\n  High-risk (prob > 0.5): %d\n", high_risk))
cat(sprintf("  Very high-risk (prob > 0.8): %d\n", very_high_risk))

**Expected Output:**
```
Prediction Statistics:
  Total: 1000
  Fraud predicted: X (X.XX%)

Probability Distribution:
  Min: 0.XXXX
  Max: 0.XXXX
  Mean: 0.XXXX
  Median: 0.XXXX

  High-risk (prob > 0.5): X
  Very high-risk (prob > 0.8): X
```

---

## Step 9: Evaluate Performance (if labels available)

if ("actual_label" %in% colnames(results)) {
  actual <- results$actual_label
  predicted <- results$fraud_prediction
  
  # Confusion matrix
  TP <- sum(predicted == 1 & actual == 1)
  TN <- sum(predicted == 0 & actual == 0)
  FP <- sum(predicted == 1 & actual == 0)
  FN <- sum(predicted == 0 & actual == 1)
  
  cat("\nConfusion Matrix:\n")
  cat(sprintf("  TP: %d, TN: %d, FP: %d, FN: %d\n", TP, TN, FP, FN))
  
  # Metrics
  accuracy <- (TP + TN) / (TP + TN + FP + FN)
  precision <- ifelse(TP + FP > 0, TP / (TP + FP), 0)
  recall <- ifelse(TP + FN > 0, TP / (TP + FN), 0)
  f1_score <- ifelse(precision + recall > 0, 2 * precision * recall / (precision + recall), 0)
  
  cat("\nPerformance Metrics:\n")
  cat(sprintf("  Accuracy:  %.4f (%.2f%%)\n", accuracy, accuracy * 100))
  cat(sprintf("  Precision: %.4f (%.2f%%)\n", precision, precision * 100))
  cat(sprintf("  Recall:    %.4f (%.2f%%)\n", recall, recall * 100))
  cat(sprintf("  F1-Score:  %.4f\n", f1_score))
  
  # Cost analysis
  COST_FN <- 10
  COST_FP <- 1
  total_cost <- (FN * COST_FN) + (FP * COST_FP)
  cost_without_model <- sum(actual == 1) * COST_FN
  cost_saved <- cost_without_model - total_cost
  
  cat("\nCost Analysis:\n")
  cat(sprintf("  Total cost: %d\n", total_cost))
  cat(sprintf("  Cost saved: %d\n", cost_saved))
}

**Expected Output:**
```
Confusion Matrix:
  TP: X, TN: X, FP: X, FN: X

Performance Metrics:
  Accuracy:  0.XXXX (XX.XX%)
  Precision: 0.XXXX (XX.XX%)
  Recall:    0.XXXX (XX.XX%)
  F1-Score:  0.XXXX

Cost Analysis:
  Total cost: X
  Cost saved: X
```

---

## Step 10: View Sample Predictions

# Top 10 highest probabilities
cat("\nTop 10 Highest Fraud Probabilities:\n")
top_predictions <- results %>%
  arrange(desc(fraud_probability)) %>%
  head(10)

print(top_predictions)

# Some low probabilities
cat("\nSample Low Fraud Probabilities:\n")
low_predictions <- results %>%
  arrange(fraud_probability) %>%
  head(5)

print(low_predictions)

**Expected Output:**
```
[Shows top 10 and bottom 5 predictions with probabilities]
```

---

## Step 11: Save Results

# Create output directory
if (!dir.exists("evaluation")) {
  dir.create("evaluation", recursive = TRUE)
}

# Save predictions
output_file <- "evaluation/real_data_test_predictions.csv"
write_csv(results, output_file)
cat(sprintf("✓ Saved: %s\n", output_file))

# View first few rows
cat("\nFirst 5 rows:\n")
print(head(results, 5))

**Expected Output:**
```
✓ Saved: evaluation/real_data_test_predictions.csv

First 5 rows:
[Shows first 5 prediction results]
```

---

## Step 12: Review and Interpret Results

# Summary questions to consider
cat("\nReview Questions:\n")
cat("  1. Do fraud probabilities make sense?\n")
cat("  2. Are high-risk transactions actually suspicious?\n")
if ("actual_label" %in% colnames(results)) {
  cat("  3. How does accuracy compare to training results?\n")
  cat("  4. Are false positives acceptable?\n")
  cat("  5. Are we catching enough frauds (recall)?\n")
}
cat("  6. Should threshold be adjusted?\n")

---

## Troubleshooting

### Issue: "Dataset not found"
**Solution:** Check the path to your dataset:
# List files in cnp_dataset directory
list.files("cnp_dataset/feature_engineered/", recursive = TRUE)

### Issue: "Features missing"
**Solution:** The script will add missing features with 0. This is expected if some features weren't in the original dataset.

### Issue: "Model loading error"
**Solution:** Make sure you've run `deploy_models.R` first:
source("deploy_models.R")

### Issue: "Memory error with large dataset"
**Solution:** Reduce the number of transactions:
# Load fewer transactions
df <- read_csv(dataset_path, n_max = 500, show_col_types = FALSE)

---

## Next Steps After Testing

1. ✅ **Review predictions** - Check if they make sense
2. ✅ **Validate high-risk cases** - Manually review top predictions
3. ✅ **Compare with training metrics** - Should be similar
4. ✅ **Adjust threshold if needed** - Based on business needs
5. ✅ **Proceed to production** - If satisfied with results

---

**Ready to test?** Start with Step 1 and work through each step!

