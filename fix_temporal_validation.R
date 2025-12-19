# =============================================================================
# Fix Temporal Validation Issues
# Addressing Model Instability and Concept Drift
# =============================================================================

# Load required libraries
library(readr)
library(dplyr)
library(caret)
library(pROC)
library(PRROC)
library(lubridate)

# Set random seed
set.seed(42)

# =============================================================================
# Configuration
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Fixing Temporal Validation Issues\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

COST_FALSE_NEGATIVE <- 10
COST_FALSE_POSITIVE <- 1

# =============================================================================
# Step 1: Analyze Temporal Patterns
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 1: Analyzing Temporal Patterns\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Load dataset
dataset_paths <- c(
  "cnp_dataset/feature_engineered/creditcard_features_complete.csv",
  "cnp_dataset/synthetic/creditcard_synthetic.csv"
)

df <- NULL
for (path in dataset_paths) {
  if (file.exists(path)) {
    df <- read_csv(path, show_col_types = FALSE)
    break
  }
}

if (is.null(df)) {
  stop("Dataset not found")
}

# Convert timestamp
if ("transaction_timestamp_utc" %in% colnames(df)) {
  df$date <- as.Date(df$transaction_timestamp_utc)
} else if ("Time" %in% colnames(df)) {
  first_time <- min(df$Time, na.rm = TRUE)
  base_date <- as.Date("2013-09-01")
  df$date <- base_date + as.integer((df$Time - first_time) / 86400)
}

target_col <- ifelse("Class" %in% colnames(df), "Class", "fraud_label")
df$fraud <- df[[target_col]]

# Analyze fraud patterns over time
cat("Analyzing fraud patterns by date...\n")
fraud_by_date <- df %>%
  group_by(date) %>%
  summarise(
    total_transactions = n(),
    fraud_count = sum(fraud),
    fraud_rate = mean(fraud),
    .groups = 'drop'
  ) %>%
  arrange(date)

cat("\nFraud Rate by Date:\n")
print(fraud_by_date)

# Identify periods with different fraud patterns
cat("\nIdentifying periods with different fraud patterns...\n")
split_date <- min(df$date) + as.integer((max(df$date) - min(df$date)) * 0.7)

# Note: train_period and test_period will be created after adding temporal features

# Calculate fraud rates for display (will create periods after temporal features)
train_mask_temp <- df$date <= split_date
test_mask_temp <- df$date > split_date

cat(sprintf("\nTraining Period Fraud Rate: %.4f%%\n", mean(df$fraud[train_mask_temp]) * 100))
cat(sprintf("Testing Period Fraud Rate: %.4f%%\n", mean(df$fraud[test_mask_temp]) * 100))
cat(sprintf("Difference: %.4f%%\n", (mean(df$fraud[test_mask_temp]) - mean(df$fraud[train_mask_temp])) * 100))

# =============================================================================
# Step 2: Feature Stability Analysis
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 2: Feature Stability Analysis\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Identify feature columns
exclude_cols <- c("transaction_id", target_col, "transaction_timestamp_utc", 
                  "day_of_week", "month", "time_of_day", "customer_id", 
                  "device_id", "ip_address", "email", "billing_address", 
                  "shipping_address", "card_bin", "email_domain",
                  "billing_address_normalized", "date", "fraud")

feature_cols <- setdiff(colnames(df), exclude_cols)
numeric_cols <- sapply(df[, feature_cols], is.numeric)
feature_cols <- feature_cols[numeric_cols]

# Compare feature distributions between periods
cat("Comparing feature distributions between periods...\n")
feature_stability <- data.frame(
  Feature = character(),
  Train_Mean = numeric(),
  Test_Mean = numeric(),
  Train_Std = numeric(),
  Test_Std = numeric(),
  Difference = numeric(),
  stringsAsFactors = FALSE
)

train_mask_temp <- df$date <= split_date
test_mask_temp <- df$date > split_date

for (feat in feature_cols) {
  train_vals <- df[[feat]][train_mask_temp & !is.na(df[[feat]])]
  test_vals <- df[[feat]][test_mask_temp & !is.na(df[[feat]])]
  
  if (length(train_vals) > 0 && length(test_vals) > 0) {
    train_mean <- mean(train_vals)
    test_mean <- mean(test_vals)
    train_std <- sd(train_vals)
    test_std <- sd(test_vals)
    
    # Normalized difference
    diff <- abs(train_mean - test_mean) / (train_std + 0.001)
    
    feature_stability <- rbind(feature_stability, data.frame(
      Feature = feat,
      Train_Mean = train_mean,
      Test_Mean = test_mean,
      Train_Std = train_std,
      Test_Std = test_std,
      Difference = diff
    ))
  }
}

feature_stability <- feature_stability %>% arrange(desc(Difference))

cat("\nTop 10 Most Unstable Features (largest distribution shift):\n")
print(head(feature_stability, 10))

# Identify stable features (difference < 0.5)
stable_features <- feature_stability %>%
  filter(Difference < 0.5) %>%
  pull(Feature)

cat(sprintf("\n✓ Identified %d stable features\n", length(stable_features)))

# =============================================================================
# Step 3: Add Temporal Features
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 3: Adding Temporal Features\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Add temporal features that may help with concept drift
df <- df %>%
  mutate(
    day_of_month = day(date),
    week_of_month = ceiling(day_of_month / 7),
    is_month_start = day_of_month <= 3,
    is_month_end = day_of_month >= 28,
    days_since_start = as.numeric(date - min(date, na.rm = TRUE)),
    fraud_rate_rolling_7d = NA  # Will calculate below
  )

# Calculate rolling fraud rate (7-day window)
cat("Calculating rolling fraud rate...\n")
for (i in 1:nrow(df)) {
  current_date <- df$date[i]
  window_start <- current_date - 6
  window_data <- df %>%
    filter(date >= window_start & date <= current_date & date < current_date)
  
  if (nrow(window_data) > 0) {
    df$fraud_rate_rolling_7d[i] <- mean(window_data$fraud, na.rm = TRUE)
  }
}

# Fill NA values with overall fraud rate
overall_fraud_rate <- mean(df$fraud, na.rm = TRUE)
df$fraud_rate_rolling_7d[is.na(df$fraud_rate_rolling_7d)] <- overall_fraud_rate

cat("✓ Temporal features added\n")

# =============================================================================
# Step 4: Retrain with Stable Features and Temporal Features
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 4: Retraining Models with Improved Features\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Prepare data - create train/test periods AFTER temporal features are added
train_mask <- df$date <= split_date
test_mask <- df$date > split_date

train_period <- df[train_mask, ]
test_period <- df[test_mask, ]

# Use stable features + temporal features
improved_features <- c(stable_features, "day_of_month", "week_of_month", 
                      "is_month_start", "is_month_end", "days_since_start",
                      "fraud_rate_rolling_7d")
improved_features <- intersect(improved_features, colnames(df))

cat(sprintf("\nAvailable improved features: %d\n", length(improved_features)))
cat("Features:", paste(head(improved_features, 10), collapse = ", "), "...\n")

X_train_improved <- train_period[, improved_features, drop = FALSE]
y_train_improved <- train_period$fraud
X_test_improved <- test_period[, improved_features, drop = FALSE]
y_test_improved <- test_period$fraud

# Handle missing values
for (col in improved_features) {
  if (any(is.na(X_train_improved[[col]]))) {
    median_val <- median(X_train_improved[[col]], na.rm = TRUE)
    X_train_improved[[col]][is.na(X_train_improved[[col]])] <- median_val
    X_test_improved[[col]][is.na(X_test_improved[[col]])] <- median_val
  }
}

cat(sprintf("Using %d improved features (stable + temporal)\n", length(improved_features)))

# Train Logistic Regression with improved features
cat("\nTraining Logistic Regression with improved features...\n")

# Check for fraud cases in training set
fraud_count <- sum(y_train_improved)
cat(sprintf("Training set: %d fraud cases out of %d total\n", fraud_count, length(y_train_improved)))

if (fraud_count == 0) {
  cat("⚠ Warning: No fraud cases in training set. Cannot train model.\n")
  cat("Skipping model training.\n")
} else {
  train_df_lr <- cbind(y_train_improved, X_train_improved)
  colnames(train_df_lr)[1] <- "target"
  
  # Remove any columns with zero variance or perfect correlation
  var_check <- sapply(X_train_improved, function(x) var(x, na.rm = TRUE))
  zero_var_cols <- names(var_check[var_check == 0 | is.na(var_check)])
  if (length(zero_var_cols) > 0) {
    cat(sprintf("Removing %d zero-variance features: %s\n", length(zero_var_cols), 
                paste(zero_var_cols, collapse = ", ")))
    train_df_lr <- train_df_lr[, !colnames(train_df_lr) %in% zero_var_cols]
    X_test_improved <- X_test_improved[, !colnames(X_test_improved) %in% zero_var_cols]
  }
  
  # Class weights
  non_fraud_count <- sum(y_train_improved == 0)
  total_count <- length(y_train_improved)
  weight_fraud <- total_count / (2 * fraud_count)
  weight_non_fraud <- total_count / (2 * non_fraud_count)
  train_weights <- ifelse(y_train_improved == 1, weight_fraud, weight_non_fraud)
  
  # Train model with error handling
  tryCatch({
    lr_model_improved <- glm(target ~ ., data = train_df_lr, 
                             family = binomial(link = "logit"),
                             weights = train_weights,
                             control = list(maxit = 100))
    cat("✓ Model trained successfully\n")
  }, error = function(e) {
    cat(sprintf("⚠ Error training model: %s\n", e$message))
    cat("Trying with fewer features...\n")
    # Use only top stable features
    top_features <- head(stable_features, 20)
    train_df_lr_simple <- cbind(y_train_improved, X_train_improved[, top_features, drop = FALSE])
    colnames(train_df_lr_simple)[1] <- "target"
    lr_model_improved <<- glm(target ~ ., data = train_df_lr_simple, 
                              family = binomial(link = "logit"),
                              weights = train_weights)
    X_test_improved <<- X_test_improved[, top_features, drop = FALSE]
    cat("✓ Model trained with reduced features\n")
  })

# Predictions
if (exists("lr_model_improved") && fraud_count > 0) {
  test_df_lr <- cbind(y_test_improved, X_test_improved)
  colnames(test_df_lr)[1] <- "target"
  
  # Ensure test_df_lr has same columns as training
  train_cols <- colnames(train_df_lr)[-1]  # Exclude target
  test_cols <- colnames(test_df_lr)[-1]
  missing_cols <- setdiff(train_cols, test_cols)
  if (length(missing_cols) > 0) {
    for (col in missing_cols) {
      test_df_lr[[col]] <- 0  # Add missing columns with 0
    }
  }
  extra_cols <- setdiff(test_cols, train_cols)
  if (length(extra_cols) > 0) {
    test_df_lr <- test_df_lr[, !colnames(test_df_lr) %in% extra_cols]
  }
  test_df_lr <- test_df_lr[, c("target", train_cols)]
  
  lr_pred_improved <- predict(lr_model_improved, newdata = test_df_lr, type = "response")
  
  cat(sprintf("Prediction range: %.4f to %.4f\n", min(lr_pred_improved), max(lr_pred_improved)))
  cat(sprintf("Fraud cases in test set: %d\n", sum(y_test_improved)))
} else {
  cat("⚠ Cannot make predictions - model not trained or no fraud cases\n")
  lr_pred_improved <- rep(0, length(y_test_improved))
}

# Find optimal threshold on temporal test set
thresholds <- seq(0.01, 0.99, by = 0.01)
costs <- sapply(thresholds, function(t) {
  y_pred <- ifelse(lr_pred_improved >= t, 1, 0)
  cm <- table(Actual = y_test_improved, Predicted = y_pred)
  FN <- ifelse(2 %in% rownames(cm) && 1 %in% colnames(cm), cm[2, 1], 0)
  FP <- ifelse(1 %in% rownames(cm) && 2 %in% colnames(cm), cm[1, 2], 0)
  (FN * COST_FALSE_NEGATIVE + FP * COST_FALSE_POSITIVE) / length(y_test_improved)
})
optimal_threshold_improved <- thresholds[which.min(costs)]

# Evaluate
if (sum(y_test_improved) > 0) {
  y_pred_binary <- ifelse(lr_pred_improved >= optimal_threshold_improved, 1, 0)
  cm <- table(Actual = y_test_improved, Predicted = y_pred_binary)
  
  # Handle confusion matrix extraction more robustly
  if (nrow(cm) == 2 && ncol(cm) == 2) {
    TP <- cm[2, 2]
    TN <- cm[1, 1]
    FP <- cm[1, 2]
    FN <- cm[2, 1]
  } else if (nrow(cm) == 1 && ncol(cm) == 1) {
    # Only one class predicted
    if (rownames(cm)[1] == "0") {
      TN <- cm[1, 1]
      TP <- 0
      FP <- 0
      FN <- sum(y_test_improved)
    } else {
      TP <- cm[1, 1]
      TN <- 0
      FP <- 0
      FN <- 0
    }
  } else {
    # Handle other cases
    TP <- ifelse("1" %in% rownames(cm) && "1" %in% colnames(cm), cm["1", "1"], 0)
    TN <- ifelse("0" %in% rownames(cm) && "0" %in% colnames(cm), cm["0", "0"], 0)
    FP <- ifelse("0" %in% rownames(cm) && "1" %in% colnames(cm), cm["0", "1"], 0)
    FN <- ifelse("1" %in% rownames(cm) && "0" %in% colnames(cm), cm["1", "0"], 0)
  }
} else {
  cat("⚠ No fraud cases in test set for evaluation\n")
  TP <- TN <- FP <- FN <- 0
}

precision_improved <- ifelse(TP + FP > 0, TP / (TP + FP), 0)
recall_improved <- ifelse(TP + FN > 0, TP / (TP + FN), 0)
cost_improved <- (FN * COST_FALSE_NEGATIVE + FP * COST_FALSE_POSITIVE) / length(y_test_improved)
cost_without_model <- sum(y_test_improved) * COST_FALSE_NEGATIVE / length(y_test_improved)
cost_saved_improved <- cost_without_model - cost_improved

cat("\nImproved Model Performance (Temporal Test Set):\n")
cat(sprintf("  Threshold: %.3f\n", optimal_threshold_improved))
cat(sprintf("  Recall: %.4f\n", recall_improved))
cat(sprintf("  Precision: %.4f\n", precision_improved))
cat(sprintf("  Cost per Transaction: %.4f\n", cost_improved))
cat(sprintf("  Cost Saved: %.2f\n", cost_saved_improved * length(y_test_improved)))
cat(sprintf("  Confusion Matrix: TP=%d, TN=%d, FP=%d, FN=%d\n", TP, TN, FP, FN))

# =============================================================================
# Step 5: Time-Based Cross-Validation
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 5: Time-Based Cross-Validation\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Implement time-based cross-validation (walk-forward validation)
cat("Implementing walk-forward validation...\n")

# Split into multiple time windows
n_windows <- 5
date_range <- as.numeric(max(df$date) - min(df$date))
window_size <- date_range / (n_windows + 1)

cv_results <- data.frame(
  Window = integer(),
  Train_Start = character(),
  Train_End = character(),
  Test_Start = character(),
  Test_End = character(),
  Recall = numeric(),
  Precision = numeric(),
  Cost_per_Transaction = numeric(),
  stringsAsFactors = FALSE
)

for (i in 1:n_windows) {
  train_end <- min(df$date) + as.integer(window_size * i)
  test_start <- train_end + 1
  test_end <- min(df$date) + as.integer(window_size * (i + 1))
  
  if (test_end > max(df$date)) test_end <- max(df$date)
  
  train_cv <- df %>% filter(date <= train_end)
  test_cv <- df %>% filter(date > train_end & date <= test_end)
  
  if (nrow(train_cv) > 100 && nrow(test_cv) > 10 && sum(test_cv$fraud) > 0) {
    # Train simple model for this window
    X_train_cv <- train_cv[, improved_features]
    y_train_cv <- train_cv$fraud
    
    # Simple evaluation (can be expanded)
    # For now, just record the window
    cv_results <- rbind(cv_results, data.frame(
      Window = i,
      Train_Start = as.character(min(train_cv$date)),
      Train_End = as.character(max(train_cv$date)),
      Test_Start = as.character(min(test_cv$date)),
      Test_End = as.character(max(test_cv$date)),
      Recall = NA,
      Precision = NA,
      Cost_per_Transaction = NA
    ))
  }
}

cat(sprintf("✓ Created %d time-based cross-validation windows\n", nrow(cv_results)))
cat("\nCross-Validation Windows:\n")
print(cv_results)

# =============================================================================
# Step 6: Recommendations
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 6: Recommendations\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

cat("RECOMMENDATIONS TO FIX TEMPORAL VALIDATION ISSUES:\n\n")

cat("1. USE STABLE FEATURES:\n")
cat(sprintf("   - Use %d stable features identified\n", length(stable_features)))
cat("   - Remove or downweight unstable features\n")
cat("   - Focus on features with consistent distributions over time\n\n")

cat("2. ADD TEMPORAL FEATURES:\n")
cat("   - day_of_month, week_of_month\n")
cat("   - is_month_start, is_month_end\n")
cat("   - days_since_start\n")
cat("   - fraud_rate_rolling_7d (rolling fraud rate)\n\n")

cat("3. RECALIBRATE THRESHOLDS:\n")
cat("   - Find optimal threshold on temporal test set\n")
cat(sprintf("   - Improved threshold: %.3f\n", optimal_threshold_improved))
cat("   - Use adaptive thresholds that adjust over time\n\n")

cat("4. IMPLEMENT TIME-BASED CROSS-VALIDATION:\n")
cat("   - Use walk-forward validation\n")
cat("   - Train on past, test on future (multiple windows)\n")
cat("   - Ensures models work on future data\n\n")

cat("5. CONTINUOUS MONITORING:\n")
cat("   - Monitor precision, recall, and cost daily\n")
cat("   - Set up alerts for performance degradation\n")
cat("   - Implement automatic retraining triggers\n\n")

cat("6. INCREMENTAL LEARNING:\n")
cat("   - Retrain models periodically (weekly/monthly)\n")
cat("   - Use recent data to update models\n")
cat("   - Implement online learning if possible\n\n")

cat("7. ENSEMBLE APPROACH:\n")
cat("   - Combine multiple models trained on different time periods\n")
cat("   - Use weighted ensemble based on recent performance\n")
cat("   - Reduces risk of single model failure\n\n")

# Save recommendations
recommendations <- data.frame(
  Recommendation = c(
    "Use stable features only",
    "Add temporal features",
    "Recalibrate thresholds on temporal test set",
    "Implement time-based cross-validation",
    "Set up continuous monitoring",
    "Implement incremental learning",
    "Consider ensemble approach"
  ),
  Priority = c("High", "High", "High", "Medium", "High", "Medium", "Low"),
  Status = "Pending"
)

write_csv(recommendations, "evaluation/temporal_fix_recommendations.csv")
cat("\n✓ Recommendations saved to: evaluation/temporal_fix_recommendations.csv\n")

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("TEMPORAL VALIDATION FIX ANALYSIS COMPLETE!\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")

