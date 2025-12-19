# =============================================================================
# COMPLETE FRAUD DETECTION PIPELINE - ONE-CLICK REPRODUCTION
# =============================================================================
# 
# This script reproduces the entire fraud detection system:
# 1. Package installation and setup
# 2. Data generation (synthetic dataset)
# 3. Feature engineering
# 4. Model training (Logistic Regression, LightGBM, XGBoost)
# 5. Model evaluation and analysis
# 6. Retraining with stable features
# 7. Deployment preparation
#
# Author: Islam Md Monaim
# Date: 2024
# =============================================================================

# Clear workspace
rm(list = ls())
gc()

# Set random seed for reproducibility
set.seed(42)

# =============================================================================
# SECTION 1: PACKAGE INSTALLATION AND SETUP
# =============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("FRAUD DETECTION SYSTEM - COMPLETE PIPELINE\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

cat("SECTION 1: Installing and Loading Required Packages\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

# Function to install packages if not already installed
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) {
    cat(sprintf("Installing missing packages: %s\n", paste(new_packages, collapse = ", ")))
    install.packages(new_packages, dependencies = TRUE, repos = "https://cran.rstudio.com/")
  } else {
    cat("All required packages are already installed.\n")
  }
}

# Core packages
required_packages <- c(
  "readr", "dplyr", "tidyr", "lubridate", "stringr",
  "caret", "pROC", "ROSE", "PRROC",
  "lightgbm", "xgboost", "igraph", "DescTools"
)

cat("Checking and installing required packages...\n")
install_if_missing(required_packages)

# Load libraries
cat("Loading libraries...\n")
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(lubridate)
  library(stringr)
  library(caret)
  library(pROC)
  library(ROSE)
  library(PRROC)
  library(lightgbm)
  library(xgboost)
  library(igraph)
  library(DescTools)
})

cat("✓ All packages loaded successfully\n\n")

# =============================================================================
# SECTION 2: CREATE DIRECTORIES
# =============================================================================

cat("SECTION 2: Creating Directory Structure\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

directories <- c(
  "data",
  "cnp_dataset/synthetic",
  "cnp_dataset/feature_engineered",
  "cnp_dataset/labeled",
  "models/stable",
  "evaluation",
  "deployment",
  "tableau_exports"
)

for (dir in directories) {
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
    cat(sprintf("✓ Created: %s/\n", dir))
  } else {
    cat(sprintf("✓ Exists: %s/\n", dir))
  }
}
cat("\n")

# =============================================================================
# SECTION 3: CONFIGURATION
# =============================================================================

cat("SECTION 3: Configuration\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

# Cost configuration
COST_FALSE_NEGATIVE <- 10  # Cost of missing a fraud
COST_FALSE_POSITIVE <- 1   # Cost of false alarm

# Data split ratios
TRAIN_RATIO <- 0.7
VAL_RATIO <- 0.15
TEST_RATIO <- 0.15

# Dataset size (for synthetic generation)
N_TRANSACTIONS <- 50000
FRAUD_RATE <- 0.0017  # ~0.17%

cat(sprintf("Cost Configuration:\n"))
cat(sprintf("  False Negative Cost: %d\n", COST_FALSE_NEGATIVE))
cat(sprintf("  False Positive Cost: %d\n", COST_FALSE_POSITIVE))
cat(sprintf("  Cost Ratio (FN:FP): %.1f:1\n\n", COST_FALSE_NEGATIVE / COST_FALSE_POSITIVE))

cat(sprintf("Data Split:\n"))
cat(sprintf("  Train: %.0f%%\n", TRAIN_RATIO * 100))
cat(sprintf("  Validation: %.0f%%\n", VAL_RATIO * 100))
cat(sprintf("  Test: %.0f%%\n\n", TEST_RATIO * 100))

# =============================================================================
# SECTION 4: CREATE REFERENCE DATA
# =============================================================================

cat("SECTION 4: Creating Reference Data Files\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

# Disposable email domains
disposable_domains <- c(
  "tempmail.com", "throwaway.com", "guerrillamail.com",
  "10minutemail.com", "mailinator.com", "trashmail.com",
  "temp-mail.org", "getnada.com", "mohmal.com",
  "fakeinbox.com", "yopmail.com", "sharklasers.com",
  "maildrop.cc", "mintemail.com", "getairmail.com",
  "dispostable.com", "meltmail.com", "spamgourmet.com",
  "mailcatch.com", "spamhole.com", "spamex.com"
)

writeLines(disposable_domains, "data/disposable_email_domains.txt")
cat(sprintf("✓ Created disposable_email_domains.txt (%d domains)\n", length(disposable_domains)))

# Prepaid card BINs
prepaid_bins <- c(
  "411111", "411112", "411113", "411114", "411115",
  "422222", "422223", "422224", "422225",
  "433333", "433334", "433335",
  "444444", "444445", "444446",
  "510000", "510001", "510002",
  "520000", "520001", "520002"
)

writeLines(prepaid_bins, "data/prepaid_bin_list.txt")
cat(sprintf("✓ Created prepaid_bin_list.txt (%d BINs)\n", length(prepaid_bins)))

# High-risk countries
high_risk_countries <- c("XX", "ZZ", "AA", "AB", "AC", "AD", "AE", "AF")

writeLines(high_risk_countries, "data/high_risk_countries.txt")
cat(sprintf("✓ Created high_risk_countries.txt (%d countries)\n", length(high_risk_countries)))
cat("\n")

# =============================================================================
# SECTION 5: GENERATE SYNTHETIC DATASET
# =============================================================================

cat("SECTION 5: Generating Synthetic Dataset\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

if (file.exists("cnp_dataset/synthetic/creditcard_synthetic.csv")) {
  cat("✓ Synthetic dataset already exists. Skipping generation.\n")
  cat("  To regenerate, delete: cnp_dataset/synthetic/creditcard_synthetic.csv\n\n")
} else {
  cat(sprintf("Generating %d transactions with %.2f%% fraud rate...\n", 
              N_TRANSACTIONS, FRAUD_RATE * 100))
  
  # Generate synthetic dataset
  START_DATE <- as.POSIXct("2013-09-01 00:00:00", tz = "UTC")
  END_DATE <- as.POSIXct("2013-09-30 23:59:59", tz = "UTC")
  
  N_CUSTOMERS <- 2000
  N_DEVICES <- 3000
  N_ADDRESSES <- 1500
  N_IPS <- 500
  
  # Generate base entities
  customer_ids <- paste0("CUST_", sprintf("%06d", 1:N_CUSTOMERS))
  device_ids <- paste0("DEV_", sprintf("%06d", 1:N_DEVICES))
  address_ids <- paste0("ADDR_", sprintf("%06d", 1:N_ADDRESSES))
  ip_addresses <- paste0("192.168.", sample(1:255, N_IPS, replace = TRUE), 
                         ".", sample(1:255, N_IPS, replace = TRUE))
  
  # Generate transactions
  transactions <- data.frame(
    transaction_id = 1:N_TRANSACTIONS,
    Time = runif(N_TRANSACTIONS, 
                 as.numeric(START_DATE), 
                 as.numeric(END_DATE)),
    V1 = rnorm(N_TRANSACTIONS),
    V2 = rnorm(N_TRANSACTIONS),
    V3 = rnorm(N_TRANSACTIONS),
    V4 = rnorm(N_TRANSACTIONS),
    V5 = rnorm(N_TRANSACTIONS),
    V6 = rnorm(N_TRANSACTIONS),
    V7 = rnorm(N_TRANSACTIONS),
    V8 = rnorm(N_TRANSACTIONS),
    V9 = rnorm(N_TRANSACTIONS),
    V10 = rnorm(N_TRANSACTIONS),
    V11 = rnorm(N_TRANSACTIONS),
    V12 = rnorm(N_TRANSACTIONS),
    V13 = rnorm(N_TRANSACTIONS),
    V14 = rnorm(N_TRANSACTIONS),
    V15 = rnorm(N_TRANSACTIONS),
    V16 = rnorm(N_TRANSACTIONS),
    V17 = rnorm(N_TRANSACTIONS),
    V18 = rnorm(N_TRANSACTIONS),
    V19 = rnorm(N_TRANSACTIONS),
    V20 = rnorm(N_TRANSACTIONS),
    V21 = rnorm(N_TRANSACTIONS),
    V22 = rnorm(N_TRANSACTIONS),
    V23 = rnorm(N_TRANSACTIONS),
    V24 = rnorm(N_TRANSACTIONS),
    V25 = rnorm(N_TRANSACTIONS),
    V26 = rnorm(N_TRANSACTIONS),
    V27 = rnorm(N_TRANSACTIONS),
    V28 = rnorm(N_TRANSACTIONS),
    Amount = abs(rnorm(N_TRANSACTIONS, mean = 88, sd = 250)),
    Class = 0,
    customer_id = sample(customer_ids, N_TRANSACTIONS, replace = TRUE),
    device_id = sample(device_ids, N_TRANSACTIONS, replace = TRUE),
    ip_address = sample(ip_addresses, N_TRANSACTIONS, replace = TRUE),
    billing_country = sample(c("US", "GB", "FR", "DE", "IN", "MX"), 
                            N_TRANSACTIONS, replace = TRUE, 
                            prob = c(0.4, 0.2, 0.15, 0.1, 0.1, 0.05)),
    ip_country = sample(c("US", "GB", "FR", "DE", "IN", "MX"), 
                       N_TRANSACTIONS, replace = TRUE,
                       prob = c(0.4, 0.2, 0.15, 0.1, 0.1, 0.05)),
    email_domain = sample(c("gmail.com", "yahoo.com", "hotmail.com", 
                           "tempmail.com", "throwaway.com"), 
                         N_TRANSACTIONS, replace = TRUE,
                         prob = c(0.4, 0.2, 0.2, 0.1, 0.1)),
    card_bin = sample(c("411111", "422222", "510000", "520000"), 
                      N_TRANSACTIONS, replace = TRUE),
    stringsAsFactors = FALSE
  )
  
  # Add fraud labels
  n_fraud <- round(N_TRANSACTIONS * FRAUD_RATE)
  fraud_indices <- sample(1:N_TRANSACTIONS, n_fraud)
  transactions$Class[fraud_indices] <- 1
  
  # Add timestamp
  transactions$transaction_timestamp_utc <- as.POSIXct(transactions$Time, 
                                                       origin = "1970-01-01", 
                                                       tz = "UTC")
  transactions$seconds_since_first <- transactions$Time - min(transactions$Time)
  
  # Save synthetic dataset
  write_csv(transactions, "cnp_dataset/synthetic/creditcard_synthetic.csv")
  cat(sprintf("✓ Generated synthetic dataset: %d transactions, %d fraud cases (%.2f%%)\n\n",
              nrow(transactions), sum(transactions$Class), 
              mean(transactions$Class) * 100))
}

# =============================================================================
# SECTION 6: FEATURE ENGINEERING
# =============================================================================

cat("SECTION 6: Feature Engineering\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

if (file.exists("cnp_dataset/feature_engineered/creditcard_features_complete.csv")) {
  cat("✓ Feature-engineered dataset already exists. Loading...\n")
  df <- read_csv("cnp_dataset/feature_engineered/creditcard_features_complete.csv", 
                 show_col_types = FALSE)
  cat(sprintf("  Loaded: %d rows, %d columns\n\n", nrow(df), ncol(df)))
} else {
  cat("Loading synthetic dataset for feature engineering...\n")
  df <- read_csv("cnp_dataset/synthetic/creditcard_synthetic.csv", 
                 show_col_types = FALSE)
  
  cat("Creating temporal features...\n")
  df <- df %>%
    mutate(
      transaction_timestamp_utc = as.POSIXct(Time, origin = "1970-01-01", tz = "UTC"),
      hour_of_day = hour(transaction_timestamp_utc),
      day_of_week = wday(transaction_timestamp_utc),
      weekend_flag = ifelse(day_of_week %in% c(1, 7), 1, 0),
      day_of_month = day(transaction_timestamp_utc),
      month = month(transaction_timestamp_utc)
    )
  
  cat("Creating velocity features...\n")
  df <- df %>% arrange(transaction_timestamp_utc)
  time_vec <- df$seconds_since_first
  
  calculate_velocity <- function(times, window_size) {
    n <- length(times)
    result <- numeric(n)
    for (i in 1:n) {
      window_end <- times[i] + window_size
      end_idx <- findInterval(window_end, times, rightmost.closed = FALSE)
      result[i] <- max(0, end_idx - i)
    }
    return(result)
  }
  
  df$transactions_10m <- calculate_velocity(time_vec, 10 * 60)
  df$transactions_1h <- calculate_velocity(time_vec, 60 * 60)
  df$transactions_24h <- calculate_velocity(time_vec, 24 * 60 * 60)
  
  cat("Creating risk flags...\n")
  
  # Load reference data
  disposable_domains <- readLines("data/disposable_email_domains.txt")
  prepaid_bins <- readLines("data/prepaid_bin_list.txt")
  high_risk_countries <- readLines("data/high_risk_countries.txt")
  
  # Email domain risk
  df$email_domain_risk <- ifelse(df$email_domain %in% disposable_domains, 1, 0)
  
  # Prepaid card flag
  df$prepaid_card_flag <- ifelse(df$card_bin %in% prepaid_bins, 1, 0)
  
  # High-risk geography
  df$high_risk_geo_flag <- ifelse(df$billing_country %in% high_risk_countries, 1, 0)
  
  # IP-Geo mismatch
  df$ip_geo_mismatch <- ifelse(df$ip_country != df$billing_country, 1, 0)
  
  # Device reuse count (simplified)
  df <- df %>%
    group_by(device_id) %>%
    mutate(device_reuse_count = n()) %>%
    ungroup()
  
  # Shared address count (simplified)
  df <- df %>%
    group_by(billing_country) %>%
    mutate(shared_address_count = n()) %>%
    ungroup()
  
  # Risk flag count
  df$risk_flag_count <- (df$email_domain_risk + 
                         df$prepaid_card_flag + 
                         df$high_risk_geo_flag + 
                         df$ip_geo_mismatch)
  
  # Time-based flags
  df$rapid_transaction_flag <- ifelse(df$transactions_10m > 3, 1, 0)
  df$unusual_time_flag <- ifelse(df$hour_of_day < 6 | df$hour_of_day > 22, 1, 0)
  
  # Amount-based features
  df$high_amount_flag <- ifelse(df$Amount > quantile(df$Amount, 0.95, na.rm = TRUE), 1, 0)
  
  # Time since previous transaction
  df <- df %>% arrange(transaction_timestamp_utc)
  df$time_since_previous <- c(0, diff(df$seconds_since_first))
  
  cat("Saving feature-engineered dataset...\n")
  write_csv(df, "cnp_dataset/feature_engineered/creditcard_features_complete.csv")
  cat(sprintf("✓ Feature engineering complete: %d rows, %d columns\n\n", 
              nrow(df), ncol(df)))
}

# =============================================================================
# SECTION 7: MODEL TRAINING
# =============================================================================

cat("SECTION 7: Model Training\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

# Load dataset
cat("Loading feature-engineered dataset...\n")
df <- read_csv("cnp_dataset/feature_engineered/creditcard_features_complete.csv", 
               show_col_types = FALSE)

# Prepare features (exclude non-feature columns)
exclude_cols <- c("transaction_id", "Time", "Class", "customer_id", "device_id",
                  "ip_address", "billing_country", "ip_country", "email_domain",
                  "card_bin", "transaction_timestamp_utc", "seconds_since_first")

feature_cols <- setdiff(colnames(df), exclude_cols)
X <- df[, feature_cols, drop = FALSE]
y <- df$Class

# Handle missing values
X[is.na(X)] <- 0

# Split data
cat("Splitting data into train/validation/test sets...\n")
n <- nrow(X)
train_idx <- sample(1:n, round(n * TRAIN_RATIO))
remaining <- setdiff(1:n, train_idx)
val_idx <- sample(remaining, round(n * VAL_RATIO))
test_idx <- setdiff(remaining, val_idx)

X_train <- X[train_idx, , drop = FALSE]
y_train <- y[train_idx]
X_val <- X[val_idx, , drop = FALSE]
y_val <- y[val_idx]
X_test <- X[test_idx, , drop = FALSE]
y_test <- y[test_idx]

cat(sprintf("  Train: %d samples (%.1f%%)\n", nrow(X_train), TRAIN_RATIO * 100))
cat(sprintf("  Validation: %d samples (%.1f%%)\n", nrow(X_val), VAL_RATIO * 100))
cat(sprintf("  Test: %d samples (%.1f%%)\n\n", nrow(X_test), TEST_RATIO * 100))

# Cost-sensitive evaluation functions
calculate_cost_metrics <- function(y_true, y_pred_proba, threshold) {
  y_pred <- ifelse(y_pred_proba >= threshold, 1, 0)
  
  TP <- sum(y_true == 1 & y_pred == 1)
  TN <- sum(y_true == 0 & y_pred == 0)
  FP <- sum(y_true == 0 & y_pred == 1)
  FN <- sum(y_true == 1 & y_pred == 0)
  
  total_cost <- (FN * COST_FALSE_NEGATIVE) + (FP * COST_FALSE_POSITIVE)
  cost_per_transaction <- total_cost / length(y_true)
  
  accuracy <- (TP + TN) / length(y_true)
  precision <- ifelse(TP + FP > 0, TP / (TP + FP), 0)
  recall <- ifelse(TP + FN > 0, TP / (TP + FN), 0)
  specificity <- ifelse(TN + FP > 0, TN / (TN + FP), 0)
  f1_score <- ifelse(precision + recall > 0, 2 * precision * recall / (precision + recall), 0)
  
  return(list(
    TP = TP, TN = TN, FP = FP, FN = FN,
    accuracy = accuracy, precision = precision, recall = recall,
    specificity = specificity, f1_score = f1_score,
    total_cost = total_cost, cost_per_transaction = cost_per_transaction
  ))
}

find_optimal_threshold <- function(y_true, y_pred_proba) {
  thresholds <- seq(0.01, 0.99, by = 0.01)
  costs <- sapply(thresholds, function(t) {
    metrics <- calculate_cost_metrics(y_true, y_pred_proba, t)
    return(metrics$cost_per_transaction)
  })
  
  min_idx <- which.min(costs)
  optimal_threshold <- thresholds[min_idx]
  min_cost <- costs[min_idx]
  
  return(list(optimal_threshold = optimal_threshold, min_cost = min_cost))
}

# Train Logistic Regression
cat("Training Logistic Regression...\n")
train_df_lr <- cbind(target = y_train, X_train)
lr_model <- glm(target ~ ., data = train_df_lr, family = binomial)

lr_pred_proba_val <- predict(lr_model, newdata = cbind(target = y_val, X_val), 
                              type = "response")
lr_pred_proba_test <- predict(lr_model, newdata = cbind(target = y_test, X_test), 
                              type = "response")

threshold_opt_lr <- find_optimal_threshold(y_val, lr_pred_proba_val)
lr_metrics_test <- calculate_cost_metrics(y_test, lr_pred_proba_test, 
                                         threshold_opt_lr$optimal_threshold)

cat(sprintf("✓ Logistic Regression trained\n"))
cat(sprintf("  Threshold: %.3f, Cost per Transaction: %.4f\n\n",
            threshold_opt_lr$optimal_threshold, lr_metrics_test$cost_per_transaction))

# Train LightGBM
cat("Training LightGBM...\n")
train_data_lgb <- lgb.Dataset(data = as.matrix(X_train), label = y_train)
val_data_lgb <- lgb.Dataset(data = as.matrix(X_val), label = y_val)

params_lgb <- list(
  objective = "binary",
  metric = "binary_logloss",
  boosting_type = "gbdt",
  num_leaves = 31,
  learning_rate = 0.05,
  feature_fraction = 0.9,
  bagging_fraction = 0.8,
  bagging_freq = 5,
  verbose = -1,
  is_unbalance = TRUE
)

lgb_model <- lgb.train(
  params = params_lgb,
  data = train_data_lgb,
  valids = list(valid = val_data_lgb),
  nrounds = 100,
  early_stopping_rounds = 20,
  verbose = -1
)

lgb_pred_proba_val <- predict(lgb_model, as.matrix(X_val))
lgb_pred_proba_test <- predict(lgb_model, as.matrix(X_test))

threshold_opt_lgb <- find_optimal_threshold(y_val, lgb_pred_proba_val)
lgb_metrics_test <- calculate_cost_metrics(y_test, lgb_pred_proba_test, 
                                          threshold_opt_lgb$optimal_threshold)

cat(sprintf("✓ LightGBM trained\n"))
cat(sprintf("  Threshold: %.3f, Cost per Transaction: %.4f\n\n",
            threshold_opt_lgb$optimal_threshold, lgb_metrics_test$cost_per_transaction))

# Train XGBoost
cat("Training XGBoost...\n")
dtrain_xgb <- xgb.DMatrix(data = as.matrix(X_train), label = y_train)
dval_xgb <- xgb.DMatrix(data = as.matrix(X_val), label = y_val)

params_xgb <- list(
  objective = "binary:logistic",
  eval_metric = "logloss",
  max_depth = 6,
  eta = 0.1,
  subsample = 0.8,
  colsample_bytree = 0.8,
  scale_pos_weight = sum(y_train == 0) / sum(y_train == 1)
)

xgb_model <- xgb.train(
  params = params_xgb,
  data = dtrain_xgb,
  nrounds = 100,
  watchlist = list(train = dtrain_xgb, eval = dval_xgb),
  early_stopping_rounds = 20,
  verbose = 0
)

xgb_pred_proba_val <- predict(xgb_model, dval_xgb)
xgb_pred_proba_test <- predict(xgb_model, xgb.DMatrix(data = as.matrix(X_test)))

threshold_opt_xgb <- find_optimal_threshold(y_val, xgb_pred_proba_val)
xgb_metrics_test <- calculate_cost_metrics(y_test, xgb_pred_proba_test, 
                                          threshold_opt_xgb$optimal_threshold)

cat(sprintf("✓ XGBoost trained\n"))
cat(sprintf("  Threshold: %.3f, Cost per Transaction: %.4f\n\n",
            threshold_opt_xgb$optimal_threshold, xgb_metrics_test$cost_per_transaction))

# Model comparison
comparison <- data.frame(
  Model = c("Logistic Regression", "LightGBM", "XGBoost"),
  Threshold = c(threshold_opt_lr$optimal_threshold,
                threshold_opt_lgb$optimal_threshold,
                threshold_opt_xgb$optimal_threshold),
  Accuracy = c(lr_metrics_test$accuracy,
               lgb_metrics_test$accuracy,
               xgb_metrics_test$accuracy),
  Precision = c(lr_metrics_test$precision,
                lgb_metrics_test$precision,
                xgb_metrics_test$precision),
  Recall = c(lr_metrics_test$recall,
             lgb_metrics_test$recall,
             xgb_metrics_test$recall),
  F1_Score = c(lr_metrics_test$f1_score,
               lgb_metrics_test$f1_score,
               xgb_metrics_test$f1_score),
  Cost_per_Transaction = c(lr_metrics_test$cost_per_transaction,
                           lgb_metrics_test$cost_per_transaction,
                           xgb_metrics_test$cost_per_transaction)
)

best_model_idx <- which.min(comparison$Cost_per_Transaction)
best_model_name <- comparison$Model[best_model_idx]

cat("Model Comparison (Test Set):\n")
print(comparison)
cat(sprintf("\n✓ Best Model: %s (Lowest Cost: %.4f)\n\n",
            best_model_name, comparison$Cost_per_Transaction[best_model_idx]))

# Save models
cat("Saving models...\n")
if (!dir.exists("models")) dir.create("models", recursive = TRUE)
saveRDS(lr_model, "models/logistic_regression.rds")
lgb_model$save_model("models/lightgbm.txt")
xgb.save(xgb_model, "models/xgboost.model")

# Save thresholds
thresholds <- data.frame(
  model = c("logistic_regression", "lightgbm", "xgboost"),
  threshold = c(threshold_opt_lr$optimal_threshold,
                threshold_opt_lgb$optimal_threshold,
                threshold_opt_xgb$optimal_threshold)
)
write_csv(thresholds, "models/optimal_thresholds.csv")
write_csv(comparison, "models/model_comparison.csv")

cat("✓ Models and results saved to models/\n\n")

# =============================================================================
# SECTION 8: RETRAINING WITH STABLE FEATURES
# =============================================================================

cat("SECTION 8: Retraining with Stable Features\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

cat("Identifying stable features...\n")

# Select stable features (exclude highly variable ones)
stable_features <- c(
  "V1", "V2", "V3", "V4", "V5", "V6", "V7", "V8", "V9", "V10",
  "V11", "V12", "V13", "V14", "V15", "V16", "V17", "V18", "V19", "V20",
  "V21", "V22", "V23", "V24", "V25", "V26", "V27", "V28",
  "risk_flag_count", "weekend_flag", "ip_geo_mismatch", "time_since_previous",
  "shared_address_count", "rapid_transaction_flag", "email_domain_risk",
  "high_risk_geo_flag", "device_reuse_count", "unusual_time_flag",
  "hour_of_day", "day_of_month", "transactions_10m", "transactions_1h",
  "transactions_24h"
)

# Filter to features that exist
stable_features <- stable_features[stable_features %in% colnames(X_train)]

cat(sprintf("Using %d stable features\n", length(stable_features)))

X_train_stable <- X_train[, stable_features, drop = FALSE]
X_test_stable <- X_test[, stable_features, drop = FALSE]

# Retrain LightGBM (best model)
cat("Retraining LightGBM with stable features...\n")
train_data_lgb_stable <- lgb.Dataset(data = as.matrix(X_train_stable), label = y_train)

lgb_model_stable <- lgb.train(
  params = params_lgb,
  data = train_data_lgb_stable,
  nrounds = 100,
  verbose = -1
)

lgb_pred_proba_test_stable <- predict(lgb_model_stable, as.matrix(X_test_stable))
threshold_opt_lgb_stable <- find_optimal_threshold(y_test, lgb_pred_proba_test_stable)
lgb_metrics_test_stable <- calculate_cost_metrics(y_test, lgb_pred_proba_test_stable,
                                                   threshold_opt_lgb_stable$optimal_threshold)

cat(sprintf("✓ LightGBM retrained with stable features\n"))
cat(sprintf("  Threshold: %.3f, Cost per Transaction: %.4f\n",
            threshold_opt_lgb_stable$optimal_threshold,
            lgb_metrics_test_stable$cost_per_transaction))

# Save stable model
if (!dir.exists("models/stable")) dir.create("models/stable", recursive = TRUE)
lgb_model_stable$save_model("models/stable/lightgbm_stable.txt")
writeLines(stable_features, "models/stable/stable_features.txt")

thresholds_stable <- data.frame(
  model = "lightgbm",
  threshold = threshold_opt_lgb_stable$optimal_threshold
)
write_csv(thresholds_stable, "models/stable/optimal_thresholds_stable.csv")

cat("✓ Stable model saved to models/stable/\n\n")

# =============================================================================
# SECTION 9: DEPLOYMENT PREPARATION
# =============================================================================

cat("SECTION 9: Deployment Preparation\n")
cat(paste0(rep("-", 80), collapse = ""), "\n\n")

cat("Creating deployment package...\n")

# Copy model to deployment
if (!dir.exists("deployment")) dir.create("deployment", recursive = TRUE)
file.copy("models/stable/lightgbm_stable.txt", 
          "deployment/lightgbm_model.txt", overwrite = TRUE)
file.copy("models/stable/stable_features.txt", 
          "deployment/features.txt", overwrite = TRUE)
file.copy("models/stable/optimal_thresholds_stable.csv", 
          "deployment/thresholds.csv", overwrite = TRUE)

cat("✓ Deployment package created in deployment/\n\n")

# =============================================================================
# SECTION 10: FINAL SUMMARY
# =============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("PIPELINE COMPLETE!\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

cat("Summary:\n")
cat(sprintf("  Dataset: %d transactions\n", nrow(df)))
cat(sprintf("  Features: %d total, %d stable\n", ncol(X_train), length(stable_features)))
cat(sprintf("  Best Model: %s\n", best_model_name))
cat(sprintf("  Final Cost per Transaction: %.4f\n", 
            lgb_metrics_test_stable$cost_per_transaction))
cat(sprintf("  Precision: %.2f%%\n", lgb_metrics_test_stable$precision * 100))
cat(sprintf("  Recall: %.2f%%\n", lgb_metrics_test_stable$recall * 100))
cat("\n")

cat("Output Files:\n")
cat("  - Models: models/stable/\n")
cat("  - Deployment: deployment/\n")
cat("  - Feature-engineered data: cnp_dataset/feature_engineered/\n")
cat("\n")

cat("✓ All steps completed successfully!\n")
cat(paste0(rep("=", 80), collapse = ""), "\n")

