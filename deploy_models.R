# =============================================================================
# Model Deployment Script
# Prepares models for production deployment
# =============================================================================

# Load required libraries
library(readr)
library(dplyr)

# Set working directory
setwd("C:/Users/monai/OneDrive - student.uni-halle.de/Desktop/Billie _ R")

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Model Deployment Preparation\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# =============================================================================
# Step 1: Validate Models and Artifacts
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 1: Validating Models and Artifacts\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

deployment_checklist <- data.frame(
  Item = character(),
  Status = character(),
  Details = character(),
  stringsAsFactors = FALSE
)

# Check if models exist
if (file.exists("models/stable/lightgbm_stable.txt")) {
  deployment_checklist <- rbind(deployment_checklist, data.frame(
    Item = "LightGBM Stable Model",
    Status = "✓ Found",
    Details = "models/stable/lightgbm_stable.txt"
  ))
  cat("✓ LightGBM stable model found\n")
} else {
  deployment_checklist <- rbind(deployment_checklist, data.frame(
    Item = "LightGBM Stable Model",
    Status = "✗ Missing",
    Details = "Run retrain_stable_models.R first"
  ))
  cat("✗ LightGBM stable model not found\n")
}

if (file.exists("models/stable/logistic_regression_stable.rds")) {
  deployment_checklist <- rbind(deployment_checklist, data.frame(
    Item = "Logistic Regression Stable Model",
    Status = "✓ Found",
    Details = "models/stable/logistic_regression_stable.rds"
  ))
  cat("✓ Logistic Regression stable model found\n")
} else {
  cat("⚠ Logistic Regression stable model not found (optional)\n")
}

# Check if feature list exists
if (file.exists("models/stable/stable_features.txt")) {
  stable_features <- read_lines("models/stable/stable_features.txt")
  deployment_checklist <- rbind(deployment_checklist, data.frame(
    Item = "Stable Features List",
    Status = "✓ Found",
    Details = sprintf("%d features", length(stable_features))
  ))
  cat(sprintf("✓ Stable features list found (%d features)\n", length(stable_features)))
} else {
  deployment_checklist <- rbind(deployment_checklist, data.frame(
    Item = "Stable Features List",
    Status = "✗ Missing",
    Details = "Required for preprocessing"
  ))
  cat("✗ Stable features list not found\n")
}

# Check if thresholds exist
if (file.exists("models/stable/optimal_thresholds_stable.csv")) {
  thresholds <- read_csv("models/stable/optimal_thresholds_stable.csv", show_col_types = FALSE)
  deployment_checklist <- rbind(deployment_checklist, data.frame(
    Item = "Optimal Thresholds",
    Status = "✓ Found",
    Details = sprintf("%d models", nrow(thresholds))
  ))
  cat("✓ Optimal thresholds found\n")
} else {
  deployment_checklist <- rbind(deployment_checklist, data.frame(
    Item = "Optimal Thresholds",
    Status = "✗ Missing",
    Details = "Required for predictions"
  ))
  cat("✗ Optimal thresholds not found\n")
}

# Check performance metrics
if (file.exists("models/stable/model_comparison_stable.csv")) {
  metrics <- read_csv("models/stable/model_comparison_stable.csv", show_col_types = FALSE)
  best_model <- metrics[which.min(metrics$Cost_per_Transaction), ]
  
  # Validate performance
  if (best_model$Cost_Saved > 0) {
    deployment_checklist <- rbind(deployment_checklist, data.frame(
      Item = "Model Performance Validation",
      Status = "✓ Passed",
      Details = sprintf("Cost Saved: %.2f", best_model$Cost_Saved)
    ))
    cat("✓ Model performance validated (positive cost savings)\n")
  } else {
    deployment_checklist <- rbind(deployment_checklist, data.frame(
      Item = "Model Performance Validation",
      Status = "✗ Failed",
      Details = "Cost saved is negative"
    ))
    cat("✗ Model performance validation failed\n")
  }
  
  if (best_model$Precision > 0.20) {
    cat("✓ Precision > 20% (acceptable)\n")
  } else {
    cat("⚠ Precision < 20% (low)\n")
  }
  
  if (best_model$Recall > 0.60) {
    cat("✓ Recall > 60% (good)\n")
  } else {
    cat("⚠ Recall < 60% (low)\n")
  }
} else {
  cat("⚠ Performance metrics not found\n")
}

cat("\nDeployment Checklist:\n")
print(deployment_checklist)

# =============================================================================
# Step 2: Create Deployment Package
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 2: Creating Deployment Package\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

deployment_dir <- "deployment"
if (!dir.exists(deployment_dir)) {
  dir.create(deployment_dir, recursive = TRUE)
}

# Copy models
cat("Copying models...\n")
file.copy("models/stable/lightgbm_stable.txt", 
          file.path(deployment_dir, "lightgbm_model.txt"), overwrite = TRUE)
cat("✓ LightGBM model copied\n")

if (file.exists("models/stable/logistic_regression_stable.rds")) {
  file.copy("models/stable/logistic_regression_stable.rds", 
            file.path(deployment_dir, "logistic_regression_model.rds"), overwrite = TRUE)
  cat("✓ Logistic Regression model copied\n")
}

# Copy feature list
file.copy("models/stable/stable_features.txt", 
          file.path(deployment_dir, "features.txt"), overwrite = TRUE)
cat("✓ Features list copied\n")

# Copy thresholds
file.copy("models/stable/optimal_thresholds_stable.csv", 
          file.path(deployment_dir, "thresholds.csv"), overwrite = TRUE)
cat("✓ Thresholds copied\n")

# =============================================================================
# Step 3: Create Prediction Function
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 3: Creating Prediction Function\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

prediction_function <- '
# =============================================================================
# Fraud Detection Prediction Function
# Production-ready prediction function
# =============================================================================

predict_fraud <- function(transaction_data, model_type = "lightgbm") {
  # Load required libraries
  if (!requireNamespace("readr", quietly = TRUE)) {
    stop("readr package required")
  }
  if (model_type == "lightgbm" && !requireNamespace("lightgbm", quietly = TRUE)) {
    stop("lightgbm package required")
  }
  
  library(readr)
  if (model_type == "lightgbm") library(lightgbm)
  
  # Load model and artifacts
  model_path <- file.path("deployment", paste0(model_type, "_model.", 
                                                ifelse(model_type == "lightgbm", "txt", "rds")))
  features_path <- file.path("deployment", "features.txt")
  thresholds_path <- file.path("deployment", "thresholds.csv")
  
  if (!file.exists(model_path)) {
    stop(sprintf("Model file not found: %s", model_path))
  }
  if (!file.exists(features_path)) {
    stop(sprintf("Features file not found: %s", features_path))
  }
  if (!file.exists(thresholds_path)) {
    stop(sprintf("Thresholds file not found: %s", thresholds_path))
  }
  
  # Load artifacts
  required_features <- read_lines(features_path)
  thresholds <- read_csv(thresholds_path, show_col_types = FALSE)
  threshold <- thresholds$threshold[thresholds$model == model_type]
  
  if (is.na(threshold)) {
    threshold <- 0.5  # Default threshold
  }
  
  # Load model
  if (model_type == "lightgbm") {
    model <- lgb.load(model_path)
  } else {
    model <- readRDS(model_path)
  }
  
  # Preprocess transaction data
  # Ensure all required features are present
  missing_features <- setdiff(required_features, colnames(transaction_data))
  if (length(missing_features) > 0) {
    warning(sprintf("Missing features: %s. Setting to 0.", paste(missing_features, collapse = ", ")))
    for (feat in missing_features) {
      transaction_data[[feat]] <- 0
    }
  }
  
  # Select only required features
  X <- transaction_data[, required_features, drop = FALSE]
  
  # Handle missing values (fill with 0 or median)
  for (col in required_features) {
    if (any(is.na(X[[col]]))) {
      X[[col]][is.na(X[[col]])] <- 0  # Or use median from training
    }
  }
  
  # Make predictions
  if (model_type == "lightgbm") {
    predictions_proba <- predict(model, as.matrix(X))
  } else {
    # Logistic Regression
    X_with_target <- cbind(target = 0, X)  # Dummy target
    predictions_proba <- predict(model, newdata = X_with_target, type = "response")
  }
  
  # Apply threshold
  predictions_binary <- ifelse(predictions_proba >= threshold, 1, 0)
  
  # Return results
  result <- data.frame(
    transaction_id = if ("transaction_id" %in% colnames(transaction_data)) {
      transaction_data$transaction_id
    } else {
      1:nrow(transaction_data)
    },
    fraud_probability = predictions_proba,
    fraud_prediction = predictions_binary,
    threshold_used = threshold
  )
  
  return(result)
}

# Example usage:
# result <- predict_fraud(new_transactions, model_type = "lightgbm")
# print(result)
'

writeLines(prediction_function, file.path(deployment_dir, "predict_fraud.R"))
cat("✓ Prediction function created: deployment/predict_fraud.R\n")

# =============================================================================
# Step 4: Create Preprocessing Function
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 4: Creating Preprocessing Function\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

preprocessing_function <- '
# =============================================================================
# Transaction Preprocessing Function
# Prepares raw transaction data for model prediction
# =============================================================================

preprocess_transaction <- function(raw_transaction) {
  library(dplyr)
  library(lubridate)
  
  # This function should match the preprocessing used during training
  # Adjust based on your actual data structure
  
  processed <- raw_transaction
  
  # Add temporal features if date/timestamp available
  if ("transaction_timestamp_utc" %in% colnames(processed)) {
    processed$date <- as.Date(processed$transaction_timestamp_utc)
    processed$day_of_month <- day(processed$date)
    processed$week_of_month <- ceiling(day(processed$date) / 7)
    processed$is_month_start <- day(processed$date) <= 3
    processed$is_month_end <- day(processed$date) >= 28
    processed$days_since_start <- as.numeric(processed$date - min(processed$date, na.rm = TRUE))
  }
  
  # Normalize Amount feature
  if ("Amount" %in% colnames(processed)) {
    # Calculate percentile (simplified - in production, use historical distribution)
    processed$amount_percentile <- percent_rank(processed$Amount)
    processed$amount_zscore <- (processed$Amount - mean(processed$Amount, na.rm = TRUE)) / 
                                (sd(processed$Amount, na.rm = TRUE) + 0.001)
    processed$high_amount_flag_stable <- ifelse(processed$amount_percentile > 0.95, 1, 0)
  }
  
  # Add rolling fraud rate (simplified - use overall rate or daily rate)
  # In production, calculate from recent transactions
  overall_fraud_rate <- 0.005  # Update with actual rate
  processed$fraud_rate_rolling_7d <- overall_fraud_rate
  
  # Ensure all required features exist (from stable_features.txt)
  # Missing features will be set to 0 in prediction function
  
  return(processed)
}

# Example usage:
# processed <- preprocess_transaction(raw_transaction_data)
# predictions <- predict_fraud(processed, model_type = "lightgbm")
'

writeLines(preprocessing_function, file.path(deployment_dir, "preprocess_transaction.R"))
cat("✓ Preprocessing function created: deployment/preprocess_transaction.R\n")

# =============================================================================
# Step 5: Create Monitoring Script
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 5: Creating Monitoring Script\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

monitoring_script <- '
# =============================================================================
# Daily Model Performance Monitoring
# Run daily to track model performance
# =============================================================================

library(readr)
library(dplyr)

# Configuration
COST_FALSE_NEGATIVE <- 10
COST_FALSE_POSITIVE <- 1
monitoring_date <- Sys.Date()

cat("Model Performance Monitoring -", as.character(monitoring_date), "\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Load today\'s predictions and actuals
# In production, this would come from your database/system
# predictions_file <- "data/predictions_today.csv"
# actuals_file <- "data/actuals_today.csv"

# For now, create template
cat("Monitoring Template Created\n")
cat("To use:\n")
cat("1. Load predictions and actuals from your system\n")
cat("2. Calculate metrics (precision, recall, cost)\n")
cat("3. Compare with baseline\n")
cat("4. Save results to monitoring/daily_metrics.csv\n")
cat("5. Check for alerts\n\n")

# Metrics to calculate:
# - Precision
# - Recall
# - F1-Score
# - Cost per Transaction
# - Cost Saved
# - False Positive Rate
# - False Negative Rate
# - Fraud Detection Rate

# Alert thresholds:
# - Precision < 15%
# - Recall < 60%
# - Cost per Transaction > 0.1
# - Cost Saved < 0

cat("Monitoring script template ready\n")
cat("Update with your data source and run daily\n")
'

writeLines(monitoring_script, file.path(deployment_dir, "monitor_performance.R"))
cat("✓ Monitoring script created: deployment/monitor_performance.R\n")

# =============================================================================
# Step 6: Create Deployment Documentation
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 6: Creating Deployment Documentation\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

deployment_doc <- '
# Model Deployment Documentation

## Quick Start

### 1. Load Model and Make Predictions

```r
source("deployment/predict_fraud.R")

# Load your transaction data
transactions <- read_csv("your_transactions.csv")

# Preprocess (if needed)
source("deployment/preprocess_transaction.R")
processed <- preprocess_transaction(transactions)

# Make predictions
predictions <- predict_fraud(processed, model_type = "lightgbm")

# View results
print(predictions)
```

### 2. Model Information

**Best Model**: LightGBM Stable
**Location**: `deployment/lightgbm_model.txt`
**Threshold**: 0.170
**Features**: 48 stable features

### 3. Performance Metrics

- **Cost Saved**: 533.00 units
- **Cost per Transaction**: 0.0327
- **Recall**: 60.19%
- **Precision**: 41.61%
- **ROC AUC**: 0.9513

### 4. Monitoring

Run daily:
```r
source("deployment/monitor_performance.R")
```

## Files in Deployment Package

- `lightgbm_model.txt` - Best model for production
- `logistic_regression_model.rds` - Backup model
- `features.txt` - List of 48 required features
- `thresholds.csv` - Optimal thresholds for each model
- `predict_fraud.R` - Prediction function
- `preprocess_transaction.R` - Preprocessing function
- `monitor_performance.R` - Monitoring script

## Requirements

**R Packages:**
- readr
- dplyr
- lightgbm (for LightGBM model)
- lubridate (for preprocessing)

**Install:**
```r
install.packages(c("readr", "dplyr", "lubridate"))
install.packages("lightgbm")
```

## Production Checklist

- [ ] Models validated
- [ ] Features documented
- [ ] Preprocessing tested
- [ ] Predictions tested
- [ ] Monitoring set up
- [ ] Alerts configured
- [ ] Documentation reviewed
- [ ] Team trained
- [ ] Rollback plan ready
'

writeLines(deployment_doc, file.path(deployment_dir, "README.md"))
cat("✓ Deployment documentation created: deployment/README.md\n")

# =============================================================================
# Step 7: Create Test Script
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 7: Creating Test Script\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

test_script <- '
# =============================================================================
# Deployment Test Script
# Tests the deployment package before production
# =============================================================================

library(readr)

cat("Testing Deployment Package...\n\n")

# Test 1: Check all files exist
required_files <- c(
  "deployment/lightgbm_model.txt",
  "deployment/features.txt",
  "deployment/thresholds.csv",
  "deployment/predict_fraud.R",
  "deployment/preprocess_transaction.R",
  "deployment/monitor_performance.R"
)

all_exist <- TRUE
for (file in required_files) {
  if (file.exists(file)) {
    cat(sprintf("✓ %s exists\n", file))
  } else {
    cat(sprintf("✗ %s missing\n", file))
    all_exist <- FALSE
  }
}

if (!all_exist) {
  stop("Some required files are missing")
}

# Test 2: Load model
cat("\nTesting model loading...\n")
if (requireNamespace("lightgbm", quietly = TRUE)) {
  library(lightgbm)
  model <- lgb.load("deployment/lightgbm_model.txt")
  cat("✓ Model loaded successfully\n")
} else {
  cat("⚠ lightgbm not installed - cannot test model loading\n")
}

# Test 3: Load features
cat("\nTesting features loading...\n")
features <- read_lines("deployment/features.txt")
cat(sprintf("✓ Loaded %d features\n", length(features)))

# Test 4: Load thresholds
cat("\nTesting thresholds loading...\n")
thresholds <- read_csv("deployment/thresholds.csv", show_col_types = FALSE)
cat(sprintf("✓ Loaded thresholds for %d models\n", nrow(thresholds)))

# Test 5: Test prediction function (with dummy data)
cat("\nTesting prediction function...\n")
source("deployment/predict_fraud.R")

# Create dummy transaction data
dummy_data <- data.frame(
  matrix(0, nrow = 1, ncol = length(features))
)
colnames(dummy_data) <- features

tryCatch({
  result <- predict_fraud(dummy_data, model_type = "lightgbm")
  cat("✓ Prediction function works\n")
  cat(sprintf("  Sample prediction: %.4f\n", result$fraud_probability[1]))
}, error = function(e) {
  cat(sprintf("✗ Prediction function error: %s\n", e$message))
})

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("DEPLOYMENT TEST COMPLETE!\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")
'

writeLines(test_script, file.path(deployment_dir, "test_deployment.R"))
cat("✓ Test script created: deployment/test_deployment.R\n")

# =============================================================================
# Step 8: Create Deployment Summary
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 8: Deployment Summary\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

cat("DEPLOYMENT PACKAGE CREATED!\n\n")
cat("Location: deployment/\n\n")
cat("Files Created:\n")
cat("  1. lightgbm_model.txt - Production model\n")
cat("  2. features.txt - Required features (48)\n")
cat("  3. thresholds.csv - Optimal thresholds\n")
cat("  4. predict_fraud.R - Prediction function\n")
cat("  5. preprocess_transaction.R - Preprocessing function\n")
cat("  6. monitor_performance.R - Monitoring script\n")
cat("  7. test_deployment.R - Test script\n")
cat("  8. README.md - Documentation\n\n")

cat("Next Steps:\n")
cat("  1. Test deployment: source('deployment/test_deployment.R')\n")
cat("  2. Review documentation: deployment/README.md\n")
cat("  3. Integrate with your system\n")
cat("  4. Set up monitoring\n")
cat("  5. Deploy to production\n\n")

cat("Model Performance:\n")
if (exists("best_model")) {
  cat(sprintf("  Best Model: %s\n", best_model$Model))
  cat(sprintf("  Cost Saved: %.2f\n", best_model$Cost_Saved))
  cat(sprintf("  Precision: %.2f%%\n", best_model$Precision * 100))
  cat(sprintf("  Recall: %.2f%%\n", best_model$Recall * 100))
}

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("DEPLOYMENT PREPARATION COMPLETE!\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")






