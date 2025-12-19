# =============================================================================
# Fraud Detection Model Training Pipeline
# Step 4: Model Training with Cost-Sensitive Learning
# =============================================================================

# Load required libraries
library(readr)
library(dplyr)
library(caret)
library(pROC)
library(ROSE)  # For handling class imbalance
library(lightgbm)  # For LightGBM (install if needed)
library(xgboost)  # For XGBoost

# Set random seed for reproducibility
set.seed(42)

# =============================================================================
# Configuration
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Fraud Detection Model Training Pipeline\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Cost configuration (false negatives are more expensive)
COST_FALSE_NEGATIVE <- 10  # Cost of missing a fraud (high cost)
COST_FALSE_POSITIVE <- 1   # Cost of flagging legitimate transaction (low cost)

# Train/Validation/Test split ratios
TRAIN_RATIO <- 0.7
VAL_RATIO <- 0.15
TEST_RATIO <- 0.15

cat("Configuration:\n")
cat(sprintf("  Cost of False Negative (missing fraud): %d\n", COST_FALSE_NEGATIVE))
cat(sprintf("  Cost of False Positive (false alarm): %d\n", COST_FALSE_POSITIVE))
cat(sprintf("  Cost Ratio (FN:FP): %.1f:1\n", COST_FALSE_NEGATIVE / COST_FALSE_POSITIVE))
cat(sprintf("  Train/Val/Test Split: %.0f%% / %.0f%% / %.0f%%\n\n", 
            TRAIN_RATIO*100, VAL_RATIO*100, TEST_RATIO*100))

# =============================================================================
# Step 1: Load Complete Dataset
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 1: Loading Complete Dataset\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Try to load the complete feature-engineered dataset
dataset_paths <- c(
  "cnp_dataset/feature_engineered/creditcard_features_complete.csv",
  "cnp_dataset/synthetic/creditcard_synthetic.csv",
  "cnp_dataset/feature_engineered/creditcard_features.csv",
  "cnp_dataset/labeled/creditcard_labeled.csv"
)

df <- NULL
for (path in dataset_paths) {
  if (file.exists(path)) {
    cat(sprintf("Loading: %s\n", path))
    df <- read_csv(path, show_col_types = FALSE)
    cat(sprintf("✓ Dataset loaded: %d rows, %d columns\n\n", nrow(df), ncol(df)))
    break
  }
}

if (is.null(df)) {
  stop("No dataset found. Please run feature engineering first.")
}

# =============================================================================
# Step 2: Data Preparation
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 2: Data Preparation\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Identify target variable
target_col <- ifelse("Class" %in% colnames(df), "Class", "fraud_label")
if (!target_col %in% colnames(df)) {
  stop("Target variable (Class or fraud_label) not found in dataset")
}

cat(sprintf("Target variable: %s\n", target_col))

# Check class distribution
class_dist <- df %>%
  count(!!sym(target_col)) %>%
  mutate(percentage = n / nrow(df) * 100)

cat("\nClass Distribution:\n")
print(class_dist)

# Identify feature columns (exclude ID, target, and non-numeric columns)
exclude_cols <- c("transaction_id", target_col, "transaction_timestamp_utc", 
                  "day_of_week", "month", "time_of_day", "customer_id", 
                  "device_id", "ip_address", "email", "billing_address", 
                  "shipping_address", "card_bin", "email_domain",
                  "billing_address_normalized")

feature_cols <- setdiff(colnames(df), exclude_cols)

# Remove any remaining non-numeric columns
numeric_cols <- sapply(df[, feature_cols], is.numeric)
feature_cols <- feature_cols[numeric_cols]

cat(sprintf("\n✓ Selected %d features for modeling\n", length(feature_cols)))

# Prepare data
X <- df[, feature_cols]
y <- df[[target_col]]

# Handle any remaining missing values
if (sum(is.na(X)) > 0) {
  cat("Handling missing values...\n")
  # Simple imputation: replace with median
  for (col in feature_cols) {
    if (any(is.na(X[[col]]))) {
      X[[col]][is.na(X[[col]])] <- median(X[[col]], na.rm = TRUE)
    }
  }
  cat("✓ Missing values handled\n")
}

# =============================================================================
# Step 3: Train/Validation/Test Split
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 3: Train/Validation/Test Split\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Stratified split to maintain class distribution
train_idx <- createDataPartition(y, p = TRAIN_RATIO, list = FALSE)
train_data <- df[train_idx, ]
remaining_data <- df[-train_idx, ]

val_idx <- createDataPartition(remaining_data[[target_col]], p = VAL_RATIO / (VAL_RATIO + TEST_RATIO), list = FALSE)
val_data <- remaining_data[val_idx, ]
test_data <- remaining_data[-val_idx, ]

# Prepare feature matrices
X_train <- train_data[, feature_cols]
y_train <- train_data[[target_col]]
X_val <- val_data[, feature_cols]
y_val <- val_data[[target_col]]
X_test <- test_data[, feature_cols]
y_test <- test_data[[target_col]]

cat(sprintf("Training set: %d samples (%.1f%%)\n", nrow(X_train), TRAIN_RATIO*100))
cat(sprintf("  Fraud: %d (%.2f%%)\n", sum(y_train), mean(y_train)*100))
cat(sprintf("Validation set: %d samples (%.1f%%)\n", nrow(X_val), VAL_RATIO*100))
cat(sprintf("  Fraud: %d (%.2f%%)\n", sum(y_val), mean(y_val)*100))
cat(sprintf("Test set: %d samples (%.1f%%)\n", nrow(X_test), TEST_RATIO*100))
cat(sprintf("  Fraud: %d (%.2f%%)\n\n", sum(y_test), mean(y_test)*100))

# =============================================================================
# Step 4: Cost-Sensitive Evaluation Function
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 4: Cost-Sensitive Evaluation Metrics\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Function to calculate cost-sensitive metrics
calculate_cost_metrics <- function(y_true, y_pred, threshold = 0.5) {
  # Convert probabilities to binary predictions
  y_pred_binary <- ifelse(y_pred >= threshold, 1, 0)
  
  # Confusion matrix
  cm <- table(Actual = y_true, Predicted = y_pred_binary)
  
  # Extract values
  TN <- cm[1, 1]  # True Negative
  FP <- cm[1, 2]  # False Positive
  FN <- cm[2, 1]  # False Negative
  TP <- cm[2, 2]  # True Positive
  
  # Standard metrics
  accuracy <- (TP + TN) / (TP + TN + FP + FN)
  precision <- ifelse(TP + FP > 0, TP / (TP + FP), 0)
  recall <- ifelse(TP + FN > 0, TP / (TP + FN), 0)  # Sensitivity, True Positive Rate
  specificity <- ifelse(TN + FP > 0, TN / (TN + FP), 0)  # True Negative Rate
  f1_score <- ifelse(precision + recall > 0, 2 * (precision * recall) / (precision + recall), 0)
  
  # Cost calculation
  total_cost <- (FN * COST_FALSE_NEGATIVE) + (FP * COST_FALSE_POSITIVE)
  
  # Cost per transaction (normalized)
  cost_per_transaction <- total_cost / length(y_true)
  
  return(list(
    threshold = threshold,
    TP = TP, TN = TN, FP = FP, FN = FN,
    accuracy = accuracy,
    precision = precision,
    recall = recall,
    specificity = specificity,
    f1_score = f1_score,
    total_cost = total_cost,
    cost_per_transaction = cost_per_transaction
  ))
}

# Function to find optimal threshold based on cost
find_optimal_threshold <- function(y_true, y_pred_proba) {
  thresholds <- seq(0.01, 0.99, by = 0.01)
  costs <- numeric(length(thresholds))
  
  for (i in seq_along(thresholds)) {
    metrics <- calculate_cost_metrics(y_true, y_pred_proba, thresholds[i])
    costs[i] <- metrics$cost_per_transaction
  }
  
  optimal_idx <- which.min(costs)
  optimal_threshold <- thresholds[optimal_idx]
  
  return(list(
    optimal_threshold = optimal_threshold,
    min_cost = costs[optimal_idx],
    all_thresholds = thresholds,
    all_costs = costs
  ))
}

cat("✓ Cost-sensitive evaluation functions defined\n")
cat(sprintf("  Cost of False Negative: %d\n", COST_FALSE_NEGATIVE))
cat(sprintf("  Cost of False Positive: %d\n\n", COST_FALSE_POSITIVE))

# =============================================================================
# Step 5: Logistic Regression (Baseline - Interpretable)
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 5: Logistic Regression (Baseline Model)\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Prepare data for logistic regression
train_df_lr <- cbind(y_train, X_train)
colnames(train_df_lr)[1] <- "target"

# Handle class imbalance with class weights
fraud_count <- sum(y_train)
non_fraud_count <- sum(y_train == 0)
total_count <- length(y_train)

# Calculate class weights (inverse frequency)
weight_fraud <- total_count / (2 * fraud_count)
weight_non_fraud <- total_count / (2 * non_fraud_count)

# Create weights vector
train_weights <- ifelse(y_train == 1, weight_fraud, weight_non_fraud)

cat("Training logistic regression with class weights...\n")
cat(sprintf("  Fraud weight: %.2f\n", weight_fraud))
cat(sprintf("  Non-fraud weight: %.2f\n", weight_non_fraud))

# Train logistic regression
lr_model <- glm(target ~ ., 
                data = train_df_lr, 
                family = binomial(link = "logit"),
                weights = train_weights)

cat("✓ Logistic regression model trained\n")

# Predictions on validation set
val_df_lr <- cbind(y_val, X_val)
colnames(val_df_lr)[1] <- "target"

lr_pred_proba_val <- predict(lr_model, newdata = val_df_lr, type = "response")
lr_pred_proba_test <- predict(lr_model, newdata = cbind(y_test, X_test), type = "response")

# Find optimal threshold on validation set
cat("\nFinding optimal threshold on validation set...\n")
threshold_opt_lr <- find_optimal_threshold(y_val, lr_pred_proba_val)
cat(sprintf("✓ Optimal threshold: %.3f\n", threshold_opt_lr$optimal_threshold))
cat(sprintf("  Minimum cost per transaction: %.4f\n", threshold_opt_lr$min_cost))

# Evaluate on validation set
lr_metrics_val <- calculate_cost_metrics(y_val, lr_pred_proba_val, threshold_opt_lr$optimal_threshold)

cat("\nLogistic Regression - Validation Set Metrics:\n")
cat(sprintf("  Accuracy: %.4f\n", lr_metrics_val$accuracy))
cat(sprintf("  Precision: %.4f\n", lr_metrics_val$precision))
cat(sprintf("  Recall (Sensitivity): %.4f\n", lr_metrics_val$recall))
cat(sprintf("  Specificity: %.4f\n", lr_metrics_val$specificity))
cat(sprintf("  F1-Score: %.4f\n", lr_metrics_val$f1_score))
cat(sprintf("  Total Cost: %.2f\n", lr_metrics_val$total_cost))
cat(sprintf("  Cost per Transaction: %.4f\n", lr_metrics_val$cost_per_transaction))
cat(sprintf("  Confusion Matrix: TP=%d, TN=%d, FP=%d, FN=%d\n", 
            lr_metrics_val$TP, lr_metrics_val$TN, lr_metrics_val$FP, lr_metrics_val$FN))

# Evaluate on test set
lr_metrics_test <- calculate_cost_metrics(y_test, lr_pred_proba_test, threshold_opt_lr$optimal_threshold)

cat("\nLogistic Regression - Test Set Metrics:\n")
cat(sprintf("  Accuracy: %.4f\n", lr_metrics_test$accuracy))
cat(sprintf("  Precision: %.4f\n", lr_metrics_test$precision))
cat(sprintf("  Recall (Sensitivity): %.4f\n", lr_metrics_test$recall))
cat(sprintf("  Specificity: %.4f\n", lr_metrics_test$specificity))
cat(sprintf("  F1-Score: %.4f\n", lr_metrics_test$f1_score))
cat(sprintf("  Total Cost: %.2f\n", lr_metrics_test$total_cost))
cat(sprintf("  Cost per Transaction: %.4f\n", lr_metrics_test$cost_per_transaction))
cat(sprintf("  Confusion Matrix: TP=%d, TN=%d, FP=%d, FN=%d\n\n", 
            lr_metrics_test$TP, lr_metrics_test$TN, lr_metrics_test$FP, lr_metrics_test$FN))

# Feature importance (coefficients)
lr_coef <- coef(lr_model)
lr_coef <- lr_coef[names(lr_coef) != "(Intercept)"]
lr_importance <- data.frame(
  feature = names(lr_coef),
  coefficient = as.numeric(lr_coef),
  abs_coefficient = abs(as.numeric(lr_coef))
) %>%
  arrange(desc(abs_coefficient)) %>%
  head(20)

cat("Top 20 Most Important Features (Logistic Regression):\n")
print(lr_importance)

# =============================================================================
# Step 6: LightGBM (High Performance Model)
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 6: LightGBM (High Performance Model)\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Check if lightgbm is available
if (!requireNamespace("lightgbm", quietly = TRUE)) {
  cat("⚠ lightgbm package not installed. Skipping LightGBM.\n")
  cat("Install with: install.packages('lightgbm')\n\n")
  lgbm_model <- NULL
} else {
  cat("Training LightGBM with class weights...\n")
  
  # Prepare data for LightGBM
  lgb_train <- lgb.Dataset(
    data = as.matrix(X_train),
    label = y_train,
    weight = train_weights,
    free_raw_data = FALSE
  )
  
  lgb_val <- lgb.Dataset(
    data = as.matrix(X_val),
    label = y_val,
    free_raw_data = FALSE
  )
  
  # LightGBM parameters
  lgbm_params <- list(
    objective = "binary",
    metric = "binary_logloss",
    boosting_type = "gbdt",
    num_leaves = 31,
    learning_rate = 0.05,
    feature_fraction = 0.8,
    bagging_fraction = 0.8,
    bagging_freq = 5,
    min_data_in_leaf = 20,
    lambda_l1 = 0.1,
    lambda_l2 = 0.1,
    scale_pos_weight = weight_fraud / weight_non_fraud,  # Handle imbalance
    verbose = -1
  )
  
  # Train model
  lgbm_model <- lgb.train(
    params = lgbm_params,
    data = lgb_train,
    valids = list(validation = lgb_val),
    nrounds = 500,
    early_stopping_rounds = 50,
    verbose = 1
  )
  
  cat("✓ LightGBM model trained\n")
  
  # Predictions
  lgbm_pred_proba_val <- predict(lgbm_model, as.matrix(X_val))
  lgbm_pred_proba_test <- predict(lgbm_model, as.matrix(X_test))
  
  # Find optimal threshold
  cat("\nFinding optimal threshold on validation set...\n")
  threshold_opt_lgbm <- find_optimal_threshold(y_val, lgbm_pred_proba_val)
  cat(sprintf("✓ Optimal threshold: %.3f\n", threshold_opt_lgbm$optimal_threshold))
  cat(sprintf("  Minimum cost per transaction: %.4f\n", threshold_opt_lgbm$min_cost))
  
  # Evaluate on validation set
  lgbm_metrics_val <- calculate_cost_metrics(y_val, lgbm_pred_proba_val, threshold_opt_lgbm$optimal_threshold)
  
  cat("\nLightGBM - Validation Set Metrics:\n")
  cat(sprintf("  Accuracy: %.4f\n", lgbm_metrics_val$accuracy))
  cat(sprintf("  Precision: %.4f\n", lgbm_metrics_val$precision))
  cat(sprintf("  Recall (Sensitivity): %.4f\n", lgbm_metrics_val$recall))
  cat(sprintf("  Specificity: %.4f\n", lgbm_metrics_val$specificity))
  cat(sprintf("  F1-Score: %.4f\n", lgbm_metrics_val$f1_score))
  cat(sprintf("  Total Cost: %.2f\n", lgbm_metrics_val$total_cost))
  cat(sprintf("  Cost per Transaction: %.4f\n", lgbm_metrics_val$cost_per_transaction))
  cat(sprintf("  Confusion Matrix: TP=%d, TN=%d, FP=%d, FN=%d\n", 
              lgbm_metrics_val$TP, lgbm_metrics_val$TN, lgbm_metrics_val$FP, lgbm_metrics_val$FN))
  
  # Evaluate on test set
  lgbm_metrics_test <- calculate_cost_metrics(y_test, lgbm_pred_proba_test, threshold_opt_lgbm$optimal_threshold)
  
  cat("\nLightGBM - Test Set Metrics:\n")
  cat(sprintf("  Accuracy: %.4f\n", lgbm_metrics_test$accuracy))
  cat(sprintf("  Precision: %.4f\n", lgbm_metrics_test$precision))
  cat(sprintf("  Recall (Sensitivity): %.4f\n", lgbm_metrics_test$recall))
  cat(sprintf("  Specificity: %.4f\n", lgbm_metrics_test$specificity))
  cat(sprintf("  F1-Score: %.4f\n", lgbm_metrics_test$f1_score))
  cat(sprintf("  Total Cost: %.2f\n", lgbm_metrics_test$total_cost))
  cat(sprintf("  Cost per Transaction: %.4f\n", lgbm_metrics_test$cost_per_transaction))
  cat(sprintf("  Confusion Matrix: TP=%d, TN=%d, FP=%d, FN=%d\n\n", 
              lgbm_metrics_test$TP, lgbm_metrics_test$TN, lgbm_metrics_test$FP, lgbm_metrics_test$FN))
  
  # Feature importance
  lgbm_importance <- lgb.importance(lgbm_model)
  cat("Top 20 Most Important Features (LightGBM):\n")
  print(head(lgbm_importance, 20))
}

# =============================================================================
# Step 7: XGBoost (Alternative High Performance Model)
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 7: XGBoost (Alternative High Performance Model)\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Check if xgboost is available
if (!requireNamespace("xgboost", quietly = TRUE)) {
  cat("⚠ xgboost package not installed. Skipping XGBoost.\n")
  cat("Install with: install.packages('xgboost')\n\n")
  xgb_model <- NULL
} else {
  cat("Training XGBoost with class weights...\n")
  
  # Prepare data for XGBoost
  dtrain <- xgb.DMatrix(
    data = as.matrix(X_train),
    label = y_train,
    weight = train_weights
  )
  
  dval <- xgb.DMatrix(
    data = as.matrix(X_val),
    label = y_val
  )
  
  dtest <- xgb.DMatrix(
    data = as.matrix(X_test),
    label = y_test
  )
  
  # XGBoost parameters
  xgb_params <- list(
    objective = "binary:logistic",
    eval_metric = "logloss",
    max_depth = 6,
    eta = 0.1,
    subsample = 0.8,
    colsample_bytree = 0.8,
    min_child_weight = 3,
    scale_pos_weight = weight_fraud / weight_non_fraud,  # Handle imbalance
    gamma = 0.1,
    lambda = 1,
    alpha = 0.1
  )
  
  # Train model
  xgb_model <- xgb.train(
    params = xgb_params,
    data = dtrain,
    nrounds = 500,
    watchlist = list(train = dtrain, validation = dval),
    early_stopping_rounds = 50,
    verbose = 1,
    print_every_n = 50
  )
  
  cat("✓ XGBoost model trained\n")
  
  # Predictions
  xgb_pred_proba_val <- predict(xgb_model, dval)
  xgb_pred_proba_test <- predict(xgb_model, dtest)
  
  # Find optimal threshold
  cat("\nFinding optimal threshold on validation set...\n")
  threshold_opt_xgb <- find_optimal_threshold(y_val, xgb_pred_proba_val)
  cat(sprintf("✓ Optimal threshold: %.3f\n", threshold_opt_xgb$optimal_threshold))
  cat(sprintf("  Minimum cost per transaction: %.4f\n", threshold_opt_xgb$min_cost))
  
  # Evaluate on validation set
  xgb_metrics_val <- calculate_cost_metrics(y_val, xgb_pred_proba_val, threshold_opt_xgb$optimal_threshold)
  
  cat("\nXGBoost - Validation Set Metrics:\n")
  cat(sprintf("  Accuracy: %.4f\n", xgb_metrics_val$accuracy))
  cat(sprintf("  Precision: %.4f\n", xgb_metrics_val$precision))
  cat(sprintf("  Recall (Sensitivity): %.4f\n", xgb_metrics_val$recall))
  cat(sprintf("  Specificity: %.4f\n", xgb_metrics_val$specificity))
  cat(sprintf("  F1-Score: %.4f\n", xgb_metrics_val$f1_score))
  cat(sprintf("  Total Cost: %.2f\n", xgb_metrics_val$total_cost))
  cat(sprintf("  Cost per Transaction: %.4f\n", xgb_metrics_val$cost_per_transaction))
  cat(sprintf("  Confusion Matrix: TP=%d, TN=%d, FP=%d, FN=%d\n", 
              xgb_metrics_val$TP, xgb_metrics_val$TN, xgb_metrics_val$FP, xgb_metrics_val$FN))
  
  # Evaluate on test set
  xgb_metrics_test <- calculate_cost_metrics(y_test, xgb_pred_proba_test, threshold_opt_xgb$optimal_threshold)
  
  cat("\nXGBoost - Test Set Metrics:\n")
  cat(sprintf("  Accuracy: %.4f\n", xgb_metrics_test$accuracy))
  cat(sprintf("  Precision: %.4f\n", xgb_metrics_test$precision))
  cat(sprintf("  Recall (Sensitivity): %.4f\n", xgb_metrics_test$recall))
  cat(sprintf("  Specificity: %.4f\n", xgb_metrics_test$specificity))
  cat(sprintf("  F1-Score: %.4f\n", xgb_metrics_test$f1_score))
  cat(sprintf("  Total Cost: %.2f\n", xgb_metrics_test$total_cost))
  cat(sprintf("  Cost per Transaction: %.4f\n", xgb_metrics_test$cost_per_transaction))
  cat(sprintf("  Confusion Matrix: TP=%d, TN=%d, FP=%d, FN=%d\n\n", 
              xgb_metrics_test$TP, xgb_metrics_test$TN, xgb_metrics_test$FP, xgb_metrics_test$FN))
  
  # Feature importance
  xgb_importance <- xgb.importance(feature_names = feature_cols, model = xgb_model)
  cat("Top 20 Most Important Features (XGBoost):\n")
  print(head(xgb_importance, 20))
}

# =============================================================================
# Step 8: Model Comparison and Summary
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 8: Model Comparison Summary\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Create comparison table
comparison <- data.frame(
  Model = character(),
  Threshold = numeric(),
  Accuracy = numeric(),
  Precision = numeric(),
  Recall = numeric(),
  F1_Score = numeric(),
  Cost_per_Transaction = numeric(),
  stringsAsFactors = FALSE
)

# Add Logistic Regression
comparison <- rbind(comparison, data.frame(
  Model = "Logistic Regression",
  Threshold = threshold_opt_lr$optimal_threshold,
  Accuracy = lr_metrics_test$accuracy,
  Precision = lr_metrics_test$precision,
  Recall = lr_metrics_test$recall,
  F1_Score = lr_metrics_test$f1_score,
  Cost_per_Transaction = lr_metrics_test$cost_per_transaction
))

# Add LightGBM if available
if (!is.null(lgbm_model)) {
  comparison <- rbind(comparison, data.frame(
    Model = "LightGBM",
    Threshold = threshold_opt_lgbm$optimal_threshold,
    Accuracy = lgbm_metrics_test$accuracy,
    Precision = lgbm_metrics_test$precision,
    Recall = lgbm_metrics_test$recall,
    F1_Score = lgbm_metrics_test$f1_score,
    Cost_per_Transaction = lgbm_metrics_test$cost_per_transaction
  ))
}

# Add XGBoost if available
if (!is.null(xgb_model)) {
  comparison <- rbind(comparison, data.frame(
    Model = "XGBoost",
    Threshold = threshold_opt_xgb$optimal_threshold,
    Accuracy = xgb_metrics_test$accuracy,
    Precision = xgb_metrics_test$precision,
    Recall = xgb_metrics_test$recall,
    F1_Score = xgb_metrics_test$f1_score,
    Cost_per_Transaction = xgb_metrics_test$cost_per_transaction
  ))
}

cat("Model Comparison (Test Set):\n")
print(comparison)

# Find best model (lowest cost)
best_model_idx <- which.min(comparison$Cost_per_Transaction)
best_model <- comparison$Model[best_model_idx]

cat(sprintf("\n✓ Best Model (Lowest Cost): %s\n", best_model))
cat(sprintf("  Cost per Transaction: %.4f\n", comparison$Cost_per_Transaction[best_model_idx]))
cat(sprintf("  Recall: %.4f\n", comparison$Recall[best_model_idx]))

# =============================================================================
# Step 9: Save Models and Results
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 9: Saving Models and Results\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Create output directory
output_dir <- "models"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Save models
saveRDS(lr_model, file.path(output_dir, "logistic_regression_model.rds"))
cat("✓ Saved: logistic_regression_model.rds\n")

if (!is.null(lgbm_model)) {
  lgb.save(lgbm_model, file.path(output_dir, "lightgbm_model.txt"))
  cat("✓ Saved: lightgbm_model.txt\n")
}

if (!is.null(xgb_model)) {
  xgb.save(xgb_model, file.path(output_dir, "xgboost_model.model"))
  cat("✓ Saved: xgboost_model.model\n")
}

# Save thresholds
thresholds <- data.frame(
  model = c("logistic_regression", if (!is.null(lgbm_model)) "lightgbm", if (!is.null(xgb_model)) "xgboost"),
  threshold = c(threshold_opt_lr$optimal_threshold, 
                if (!is.null(lgbm_model)) threshold_opt_lgbm$optimal_threshold else NULL,
                if (!is.null(xgb_model)) threshold_opt_xgb$optimal_threshold else NULL)
)
write_csv(thresholds, file.path(output_dir, "optimal_thresholds.csv"))
cat("✓ Saved: optimal_thresholds.csv\n")

# Save comparison results
write_csv(comparison, file.path(output_dir, "model_comparison.csv"))
cat("✓ Saved: model_comparison.csv\n")

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("MODEL TRAINING COMPLETE!\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")
cat(sprintf("\nBest Model: %s\n", best_model))
cat(sprintf("All models and results saved to: %s/\n", output_dir))






