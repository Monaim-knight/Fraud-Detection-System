# =============================================================================
# Test Deployment with Real Transaction Data
# Tests the deployment package with actual transactions from the dataset
# =============================================================================

library(readr)
library(dplyr)
library(lightgbm)

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Testing Deployment with Real Transaction Data\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# =============================================================================
# Step 1: Load Real Transaction Data
# =============================================================================

cat("Step 1: Loading Real Transaction Data\n")
cat(paste0(rep("-", 60), collapse = ""), "\n")

# Path to feature-engineered dataset
dataset_path <- "cnp_dataset/feature_engineered/creditcard_features_complete.csv"

if (!file.exists(dataset_path)) {
  cat(sprintf("✗ Dataset not found: %s\n", dataset_path))
  cat("Please check the path and try again.\n")
  stop("Dataset file not found")
}

cat(sprintf("Loading dataset: %s\n", dataset_path))

# Load a sample of transactions (adjust n_max as needed)
# Start with 1000 transactions for testing
df <- read_csv(dataset_path, n_max = 1000, show_col_types = FALSE)

cat(sprintf("✓ Loaded %d transactions\n", nrow(df)))
cat(sprintf("  Columns: %d\n", ncol(df)))

# Check if Class column exists (for evaluation)
has_labels <- "Class" %in% colnames(df)
if (has_labels) {
  fraud_count <- sum(df$Class == 1, na.rm = TRUE)
  cat(sprintf("  Fraud transactions: %d (%.2f%%)\n", 
              fraud_count, 
              fraud_count/nrow(df)*100))
} else {
  cat("  ⚠ No Class column found - cannot evaluate accuracy\n")
}

cat("\n")

# =============================================================================
# Step 2: Load Required Features
# =============================================================================

cat("Step 2: Loading Required Features\n")
cat(paste0(rep("-", 60), collapse = ""), "\n")

features_file <- "deployment/features.txt"

if (!file.exists(features_file)) {
  cat(sprintf("✗ Features file not found: %s\n", features_file))
  stop("Features file not found")
}

features <- read_lines(features_file)
cat(sprintf("✓ Loaded %d required features\n", length(features)))

# Check which features are available in the dataset
available_features <- features[features %in% colnames(df)]
missing_features <- features[!features %in% colnames(df)]

if (length(missing_features) > 0) {
  cat(sprintf("⚠ Warning: %d features missing from dataset:\n", length(missing_features)))
  cat(paste(missing_features, collapse = ", "), "\n")
  cat("These will be set to 0 (default values)\n")
} else {
  cat("✓ All required features are available\n")
}

cat("\n")

# =============================================================================
# Step 3: Prepare Data for Prediction
# =============================================================================

cat("Step 3: Preparing Data for Prediction\n")
cat(paste0(rep("-", 60), collapse = ""), "\n")

# Select available features
test_data <- df %>% select(all_of(available_features))

# Add missing features with default values (0)
if (length(missing_features) > 0) {
  for (feat in missing_features) {
    test_data[[feat]] <- 0
  }
  cat(sprintf("✓ Added %d missing features with default values\n", length(missing_features)))
}

# Ensure feature order matches requirements
test_data <- test_data %>% select(all_of(features))

cat(sprintf("✓ Prepared data: %d rows, %d columns\n", nrow(test_data), ncol(test_data)))

# Verify all features are present
if (all(features %in% colnames(test_data))) {
  cat("✓ All required features are present\n")
} else {
  still_missing <- setdiff(features, colnames(test_data))
  cat(sprintf("✗ Still missing features: %s\n", paste(still_missing, collapse = ", ")))
  stop("Cannot proceed - features missing")
}

cat("\n")

# =============================================================================
# Step 4: Load Model and Thresholds
# =============================================================================

cat("Step 4: Loading Model and Thresholds\n")
cat(paste0(rep("-", 60), collapse = ""), "\n")

# Load model
model_file <- "deployment/lightgbm_model.txt"
if (!file.exists(model_file)) {
  cat(sprintf("✗ Model file not found: %s\n", model_file))
  stop("Model file not found")
}

cat("Loading LightGBM model...\n")
model <- lgb.load(model_file)
cat("✓ Model loaded successfully\n")

# Load thresholds
thresholds_file <- "deployment/thresholds.csv"
thresholds <- read_csv(thresholds_file, show_col_types = FALSE)
lightgbm_threshold <- thresholds$Threshold[thresholds$Model == "LightGBM"]

if (length(lightgbm_threshold) == 0) {
  cat("⚠ LightGBM threshold not found, using default: 0.170\n")
  lightgbm_threshold <- 0.170
} else {
  cat(sprintf("✓ Threshold loaded: %.3f\n", lightgbm_threshold))
}

cat("\n")

# =============================================================================
# Step 5: Make Predictions
# =============================================================================

cat("Step 5: Making Predictions\n")
cat(paste0(rep("-", 60), collapse = ""), "\n")

cat("Generating predictions...\n")

# Convert to matrix for LightGBM
test_matrix <- as.matrix(test_data)

# Get predictions (probabilities)
pred_proba <- predict(model, test_matrix)

# Apply threshold to get binary predictions
pred_binary <- ifelse(pred_proba >= lightgbm_threshold, 1, 0)

# Create results dataframe
results <- data.frame(
  transaction_id = if ("transaction_id" %in% colnames(df)) df$transaction_id else 1:nrow(df),
  fraud_probability = pred_proba,
  fraud_prediction = pred_binary,
  threshold_used = lightgbm_threshold
)

# Add actual labels if available
if (has_labels) {
  results$actual_label <- df$Class
  results$is_correct <- ifelse(results$fraud_prediction == results$actual_label, 1, 0)
}

cat(sprintf("✓ Predictions generated for %d transactions\n", nrow(results)))
cat("\n")

# =============================================================================
# Step 6: Analyze Results
# =============================================================================

cat("Step 6: Analyzing Results\n")
cat(paste0(rep("-", 60), collapse = ""), "\n\n")

# Basic statistics
cat("Prediction Statistics:\n")
cat(sprintf("  Total transactions: %d\n", nrow(results)))
cat(sprintf("  Fraud predictions: %d (%.2f%%)\n", 
            sum(results$fraud_prediction == 1),
            sum(results$fraud_prediction == 1)/nrow(results)*100))
cat(sprintf("  Non-fraud predictions: %d (%.2f%%)\n",
            sum(results$fraud_prediction == 0),
            sum(results$fraud_prediction == 0)/nrow(results)*100))

cat("\nProbability Distribution:\n")
cat(sprintf("  Min probability: %.4f\n", min(results$fraud_probability)))
cat(sprintf("  Max probability: %.4f\n", max(results$fraud_probability)))
cat(sprintf("  Mean probability: %.4f\n", mean(results$fraud_probability)))
cat(sprintf("  Median probability: %.4f\n", median(results$fraud_probability)))

# High-risk transactions (probability > 0.5)
high_risk <- sum(results$fraud_probability > 0.5)
cat(sprintf("\n  High-risk transactions (prob > 0.5): %d\n", high_risk))

# Very high-risk transactions (probability > 0.8)
very_high_risk <- sum(results$fraud_probability > 0.8)
cat(sprintf("  Very high-risk transactions (prob > 0.8): %d\n", very_high_risk))

cat("\n")

# =============================================================================
# Step 7: Evaluate Performance (if labels available)
# =============================================================================

if (has_labels) {
  cat("Step 7: Evaluating Performance\n")
  cat(paste0(rep("-", 60), collapse = ""), "\n\n")
  
  # Confusion matrix
  actual <- results$actual_label
  predicted <- results$fraud_prediction
  
  TP <- sum(predicted == 1 & actual == 1)  # True Positives
  TN <- sum(predicted == 0 & actual == 0)    # True Negatives
  FP <- sum(predicted == 1 & actual == 0)    # False Positives
  FN <- sum(predicted == 0 & actual == 1)    # False Negatives
  
  cat("Confusion Matrix:\n")
  cat(sprintf("  True Positives (TP):  %d - Correctly identified frauds\n", TP))
  cat(sprintf("  True Negatives (TN):  %d - Correctly identified legitimate\n", TN))
  cat(sprintf("  False Positives (FP): %d - False alarms\n", FP))
  cat(sprintf("  False Negatives (FN): %d - Missed frauds\n", FN))
  
  cat("\nPerformance Metrics:\n")
  
  # Calculate metrics
  accuracy <- (TP + TN) / (TP + TN + FP + FN)
  precision <- ifelse(TP + FP > 0, TP / (TP + FP), 0)
  recall <- ifelse(TP + FN > 0, TP / (TP + FN), 0)
  specificity <- ifelse(TN + FP > 0, TN / (TN + FP), 0)
  f1_score <- ifelse(precision + recall > 0, 2 * precision * recall / (precision + recall), 0)
  
  cat(sprintf("  Accuracy:    %.4f (%.2f%%)\n", accuracy, accuracy * 100))
  cat(sprintf("  Precision:   %.4f (%.2f%%)\n", precision, precision * 100))
  cat(sprintf("  Recall:      %.4f (%.2f%%)\n", recall, recall * 100))
  cat(sprintf("  Specificity: %.4f (%.2f%%)\n", specificity, specificity * 100))
  cat(sprintf("  F1-Score:    %.4f\n", f1_score))
  
  # Cost calculation
  COST_FALSE_NEGATIVE <- 10  # Cost of missing a fraud
  COST_FALSE_POSITIVE <- 1    # Cost of false alarm
  
  total_cost <- (FN * COST_FALSE_NEGATIVE) + (FP * COST_FALSE_POSITIVE)
  cost_per_transaction <- total_cost / nrow(results)
  
  cat("\nCost Analysis:\n")
  cat(sprintf("  Cost of False Negatives: %d × %d = %d\n", FN, COST_FALSE_NEGATIVE, FN * COST_FALSE_NEGATIVE))
  cat(sprintf("  Cost of False Positives: %d × %d = %d\n", FP, COST_FALSE_POSITIVE, FP * COST_FALSE_POSITIVE))
  cat(sprintf("  Total Cost: %d\n", total_cost))
  cat(sprintf("  Cost per Transaction: %.4f\n", cost_per_transaction))
  
  # Expected cost without model (all transactions pass)
  cost_without_model <- sum(actual == 1) * COST_FALSE_NEGATIVE
  cost_saved <- cost_without_model - total_cost
  
  cat("\nCost Savings:\n")
  cat(sprintf("  Cost without model: %d\n", cost_without_model))
  cat(sprintf("  Cost with model:    %d\n", total_cost))
  cat(sprintf("  Cost saved:         %d\n", cost_saved))
  cat(sprintf("  Cost saved %%:      %.2f%%\n", (cost_saved / cost_without_model) * 100))
  
  cat("\n")
} else {
  cat("Step 7: Performance Evaluation\n")
  cat(paste0(rep("-", 60), collapse = ""), "\n")
  cat("⚠ Cannot evaluate performance - no actual labels available\n")
  cat("Review predictions manually to assess quality\n")
  cat("\n")
}

# =============================================================================
# Step 8: Display Sample Predictions
# =============================================================================

cat("Step 8: Sample Predictions\n")
cat(paste0(rep("-", 60), collapse = ""), "\n\n")

# Show top 10 highest probability predictions
cat("Top 10 Highest Fraud Probabilities:\n")
top_predictions <- results %>%
  arrange(desc(fraud_probability)) %>%
  head(10)

print(top_predictions)

cat("\n")

# Show some low probability predictions
cat("Sample Low Fraud Probabilities:\n")
low_predictions <- results %>%
  arrange(fraud_probability) %>%
  head(5)

print(low_predictions)

cat("\n")

# =============================================================================
# Step 9: Save Results
# =============================================================================

cat("Step 9: Saving Results\n")
cat(paste0(rep("-", 60), collapse = ""), "\n")

output_dir <- "evaluation"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

output_file <- file.path(output_dir, "real_data_test_predictions.csv")
write_csv(results, output_file)
cat(sprintf("✓ Predictions saved to: %s\n", output_file))

# Save summary
summary_stats <- data.frame(
  metric = c("Total_Transactions", "Fraud_Predictions", "Non_Fraud_Predictions",
             "Min_Probability", "Max_Probability", "Mean_Probability", "Median_Probability",
             "High_Risk_Count", "Very_High_Risk_Count"),
  value = c(nrow(results),
            sum(results$fraud_prediction == 1),
            sum(results$fraud_prediction == 0),
            min(results$fraud_probability),
            max(results$fraud_probability),
            mean(results$fraud_probability),
            median(results$fraud_probability),
            high_risk,
            very_high_risk)
)

if (has_labels) {
  summary_stats <- rbind(summary_stats,
    data.frame(
      metric = c("Accuracy", "Precision", "Recall", "Specificity", "F1_Score",
                 "Total_Cost", "Cost_Per_Transaction", "Cost_Saved"),
      value = c(accuracy, precision, recall, specificity, f1_score,
                total_cost, cost_per_transaction, cost_saved)
    )
  )
}

summary_file <- file.path(output_dir, "real_data_test_summary.csv")
write_csv(summary_stats, summary_file)
cat(sprintf("✓ Summary saved to: %s\n", summary_file))

cat("\n")

# =============================================================================
# Step 10: Final Summary
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("REAL DATA TESTING COMPLETE!\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

cat("Summary:\n")
cat(sprintf("  Transactions tested: %d\n", nrow(results)))
cat(sprintf("  Fraud predictions: %d (%.2f%%)\n",
            sum(results$fraud_prediction == 1),
            sum(results$fraud_prediction == 1)/nrow(results)*100))

if (has_labels) {
  cat(sprintf("  Accuracy: %.2f%%\n", accuracy * 100))
  cat(sprintf("  Recall: %.2f%%\n", recall * 100))
  cat(sprintf("  Precision: %.2f%%\n", precision * 100))
  cat(sprintf("  Cost saved: %d\n", cost_saved))
}

cat("\n")
cat("Results saved to:\n")
cat(sprintf("  - %s\n", output_file))
cat(sprintf("  - %s\n", summary_file))
cat("\n")

cat("Next Steps:\n")
cat("  1. Review predictions in the saved CSV file\n")
cat("  2. Check high-risk transactions manually\n")
if (!has_labels) {
  cat("  3. Validate predictions with domain experts\n")
}
cat("  4. If satisfied, proceed with production deployment\n")
cat("  5. Set up daily monitoring\n")

cat("\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")






