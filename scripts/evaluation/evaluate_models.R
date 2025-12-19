# =============================================================================
# Comprehensive Model Evaluation and Analysis
# Step 5: Advanced Evaluation, Segment Analysis, and Temporal Validation
# =============================================================================

# Load required libraries
library(readr)
library(dplyr)
library(caret)
library(pROC)
library(PRROC)
library(ggplot2)
library(gridExtra)

# Set random seed for reproducibility
set.seed(42)

# =============================================================================
# Configuration
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Comprehensive Model Evaluation and Analysis\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Cost configuration (must match training)
COST_FALSE_NEGATIVE <- 10
COST_FALSE_POSITIVE <- 1

# Output directory
output_dir <- "evaluation"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

cat("Configuration:\n")
cat(sprintf("  Cost of False Negative: %d\n", COST_FALSE_NEGATIVE))
cat(sprintf("  Cost of False Positive: %d\n", COST_FALSE_POSITIVE))
cat(sprintf("  Output directory: %s/\n\n", output_dir))

# =============================================================================
# Step 1: Load Data and Models
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 1: Loading Data and Models\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Load dataset
dataset_paths <- c(
  "cnp_dataset/feature_engineered/creditcard_features_complete.csv",
  "cnp_dataset/synthetic/creditcard_synthetic.csv",
  "cnp_dataset/feature_engineered/creditcard_features.csv"
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

# Load models
cat("Loading trained models...\n")
lr_model <- readRDS("models/logistic_regression_model.rds")
cat("✓ Logistic Regression model loaded\n")

# Load LightGBM if available
if (file.exists("models/lightgbm_model.txt")) {
  library(lightgbm)
  lgbm_model <- lgb.load("models/lightgbm_model.txt")
  cat("✓ LightGBM model loaded\n")
} else {
  lgbm_model <- NULL
}

# Load XGBoost if available
if (file.exists("models/xgboost_model.model")) {
  library(xgboost)
  xgb_model <- xgb.load("models/xgboost_model.model")
  cat("✓ XGBoost model loaded\n")
} else {
  xgb_model <- NULL
}

# Load optimal thresholds
thresholds_df <- read_csv("models/optimal_thresholds.csv", show_col_types = FALSE)
cat("✓ Optimal thresholds loaded\n\n")

# =============================================================================
# Step 2: Prepare Data
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 2: Data Preparation\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Identify target variable
target_col <- ifelse("Class" %in% colnames(df), "Class", "fraud_label")
if (!target_col %in% colnames(df)) {
  stop("Target variable not found")
}

# Identify feature columns (same as training)
exclude_cols <- c("transaction_id", target_col, "transaction_timestamp_utc", 
                  "day_of_week", "month", "time_of_day", "customer_id", 
                  "device_id", "ip_address", "email", "billing_address", 
                  "shipping_address", "card_bin", "email_domain",
                  "billing_address_normalized")

feature_cols <- setdiff(colnames(df), exclude_cols)
numeric_cols <- sapply(df[, feature_cols], is.numeric)
feature_cols <- feature_cols[numeric_cols]

# Prepare feature matrix
X <- df[, feature_cols]
y <- df[[target_col]]

# Handle missing values
for (col in feature_cols) {
  if (any(is.na(X[[col]]))) {
    X[[col]][is.na(X[[col]])] <- median(X[[col]], na.rm = TRUE)
  }
}

cat(sprintf("✓ Prepared %d features for evaluation\n\n", length(feature_cols)))

# =============================================================================
# Step 3: Advanced Metrics Calculation
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 3: Advanced Metrics Calculation\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Function to calculate comprehensive metrics
calculate_comprehensive_metrics <- function(y_true, y_pred_proba, threshold, model_name) {
  # Binary predictions
  y_pred_binary <- ifelse(y_pred_proba >= threshold, 1, 0)
  
  # Confusion matrix
  cm <- table(Actual = y_true, Predicted = y_pred_binary)
  TN <- cm[1, 1]
  FP <- cm[1, 2]
  FN <- cm[2, 1]
  TP <- cm[2, 2]
  
  # Standard metrics
  accuracy <- (TP + TN) / (TP + TN + FP + FN)
  precision <- ifelse(TP + FP > 0, TP / (TP + FP), 0)
  recall <- ifelse(TP + FN > 0, TP / (TP + FN), 0)
  specificity <- ifelse(TN + FP > 0, TN / (TN + FP), 0)
  f1_score <- ifelse(precision + recall > 0, 2 * (precision * recall) / (precision + recall), 0)
  
  # Cost metrics
  total_cost <- (FN * COST_FALSE_NEGATIVE) + (FP * COST_FALSE_POSITIVE)
  cost_per_transaction <- total_cost / length(y_true)
  
  # Expected cost saved (compared to no model - all transactions approved)
  # Without model: all frauds would be approved = FN cost only
  cost_without_model <- sum(y_true) * COST_FALSE_NEGATIVE
  cost_saved <- cost_without_model - total_cost
  cost_saved_percentage <- (cost_saved / cost_without_model) * 100
  
  # ROC AUC
  roc_obj <- roc(y_true, y_pred_proba, quiet = TRUE)
  roc_auc <- as.numeric(auc(roc_obj))
  
  # PR AUC (Precision-Recall AUC)
  pr_obj <- pr.curve(scores.class0 = y_pred_proba[y_true == 1],
                     scores.class1 = y_pred_proba[y_true == 0],
                     curve = TRUE)
  pr_auc <- pr_obj$auc.integral
  
  return(list(
    model_name = model_name,
    threshold = threshold,
    TP = TP, TN = TN, FP = FP, FN = FN,
    accuracy = accuracy,
    precision = precision,
    recall = recall,
    specificity = specificity,
    f1_score = f1_score,
    roc_auc = roc_auc,
    pr_auc = pr_auc,
    total_cost = total_cost,
    cost_per_transaction = cost_per_transaction,
    cost_without_model = cost_without_model,
    cost_saved = cost_saved,
    cost_saved_percentage = cost_saved_percentage,
    roc_obj = roc_obj,
    pr_obj = pr_obj
  ))
}

# Get predictions from all models
cat("Generating predictions from all models...\n")

# Logistic Regression predictions
lr_pred_proba <- predict(lr_model, newdata = cbind(y, X), type = "response")
lr_threshold <- thresholds_df$threshold[thresholds_df$model == "logistic_regression"]

# LightGBM predictions
if (!is.null(lgbm_model)) {
  lgbm_pred_proba <- predict(lgbm_model, as.matrix(X))
  lgbm_threshold <- thresholds_df$threshold[thresholds_df$model == "lightgbm"]
} else {
  lgbm_pred_proba <- NULL
  lgbm_threshold <- NULL
}

# XGBoost predictions
if (!is.null(xgb_model)) {
  xgb_pred_proba <- predict(xgb_model, xgb.DMatrix(data = as.matrix(X)))
  xgb_threshold <- thresholds_df$threshold[thresholds_df$model == "xgboost"]
} else {
  xgb_pred_proba <- NULL
  xgb_threshold <- NULL
}

cat("✓ Predictions generated\n\n")

# Calculate comprehensive metrics for all models
cat("Calculating comprehensive metrics...\n")

metrics_list <- list()

# Logistic Regression
lr_metrics <- calculate_comprehensive_metrics(y, lr_pred_proba, lr_threshold, "Logistic Regression")
metrics_list[[1]] <- lr_metrics
cat("✓ Logistic Regression metrics calculated\n")

# LightGBM
if (!is.null(lgbm_model)) {
  lgbm_metrics <- calculate_comprehensive_metrics(y, lgbm_pred_proba, lgbm_threshold, "LightGBM")
  metrics_list[[2]] <- lgbm_metrics
  cat("✓ LightGBM metrics calculated\n")
}

# XGBoost
if (!is.null(xgb_model)) {
  xgb_metrics <- calculate_comprehensive_metrics(y, xgb_pred_proba, xgb_threshold, "XGBoost")
  metrics_list[[3]] <- xgb_metrics
  cat("✓ XGBoost metrics calculated\n")
}

# Create metrics summary table
metrics_summary <- data.frame(
  Model = sapply(metrics_list, function(x) x$model_name),
  Threshold = sapply(metrics_list, function(x) x$threshold),
  Recall = sapply(metrics_list, function(x) x$recall),
  Precision = sapply(metrics_list, function(x) x$precision),
  F1_Score = sapply(metrics_list, function(x) x$f1_score),
  ROC_AUC = sapply(metrics_list, function(x) x$roc_auc),
  PR_AUC = sapply(metrics_list, function(x) x$pr_auc),
  Cost_per_Transaction = sapply(metrics_list, function(x) x$cost_per_transaction),
  Cost_Saved = sapply(metrics_list, function(x) x$cost_saved),
  Cost_Saved_Percentage = sapply(metrics_list, function(x) x$cost_saved_percentage)
)

cat("\nComprehensive Metrics Summary:\n")
print(metrics_summary)

# Save metrics summary
write_csv(metrics_summary, file.path(output_dir, "comprehensive_metrics.csv"))
cat(sprintf("\n✓ Metrics saved to: %s/comprehensive_metrics.csv\n\n", output_dir))

# =============================================================================
# Step 4: Segment Analysis
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 4: Segment Analysis\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Check which segment columns are available
segment_cols <- c("merchant_id", "merchant", "geography", "country", "ip_country", 
                  "billing_country", "account_age", "customer_age_days", 
                  "days_since_registration")

available_segments <- intersect(segment_cols, colnames(df))

if (length(available_segments) == 0) {
  cat("⚠ No segment columns found in dataset.\n")
  cat("Available columns:", paste(head(colnames(df), 10), collapse = ", "), "...\n")
  cat("Skipping segment analysis.\n\n")
  
  # Create placeholder segment analysis
  segment_analysis <- data.frame(
    Segment_Type = "Not Available",
    Segment_Value = "N/A",
    Total_Transactions = nrow(df),
    Fraud_Count = sum(y),
    Fraud_Rate = mean(y),
    stringsAsFactors = FALSE
  )
} else {
  cat(sprintf("Found %d segment columns: %s\n\n", length(available_segments), 
              paste(available_segments, collapse = ", ")))
  
  # Use best model (LightGBM) for segment analysis
  best_model_pred <- if (!is.null(lgbm_model)) {
    lgbm_pred_proba
  } else if (!is.null(xgb_model)) {
    xgb_pred_proba
  } else {
    lr_pred_proba
  }
  
  best_model_threshold <- if (!is.null(lgbm_model)) {
    lgbm_threshold
  } else if (!is.null(xgb_model)) {
    xgb_threshold
  } else {
    lr_threshold
  }
  
  best_model_name <- if (!is.null(lgbm_model)) {
    "LightGBM"
  } else if (!is.null(xgb_model)) {
    "XGBoost"
  } else {
    "Logistic Regression"
  }
  
  cat(sprintf("Using %s for segment analysis\n", best_model_name))
  
  # Perform segment analysis for each available segment
  segment_analysis_list <- list()
  
  for (seg_col in available_segments) {
    cat(sprintf("Analyzing segment: %s\n", seg_col))
    
    # Get unique segment values (limit to top 20 to avoid too many segments)
    unique_segments <- unique(df[[seg_col]])
    unique_segments <- unique_segments[!is.na(unique_segments)]
    
    if (length(unique_segments) > 20) {
      # Use top 20 by transaction count
      seg_counts <- table(df[[seg_col]])
      top_segments <- names(sort(seg_counts, decreasing = TRUE)[1:20])
      unique_segments <- unique_segments[unique_segments %in% top_segments]
    }
    
    for (seg_value in unique_segments) {
      seg_mask <- df[[seg_col]] == seg_value & !is.na(df[[seg_col]])
      seg_y_true <- y[seg_mask]
      seg_y_pred_proba <- best_model_pred[seg_mask]
      
      if (sum(seg_mask) > 0 && sum(seg_y_true) > 0) {
        seg_metrics <- calculate_comprehensive_metrics(
          seg_y_true, seg_y_pred_proba, best_model_threshold, 
          paste0(best_model_name, " - ", seg_col, ": ", seg_value)
        )
        
        segment_analysis_list[[length(segment_analysis_list) + 1]] <- data.frame(
          Segment_Type = seg_col,
          Segment_Value = as.character(seg_value),
          Total_Transactions = sum(seg_mask),
          Fraud_Count = sum(seg_y_true),
          Fraud_Rate = mean(seg_y_true),
          Recall = seg_metrics$recall,
          Precision = seg_metrics$precision,
          F1_Score = seg_metrics$f1_score,
          ROC_AUC = seg_metrics$roc_auc,
          Cost_per_Transaction = seg_metrics$cost_per_transaction,
          Cost_Saved = seg_metrics$cost_saved,
          stringsAsFactors = FALSE
        )
      }
    }
  }
  
  if (length(segment_analysis_list) > 0) {
    segment_analysis <- do.call(rbind, segment_analysis_list)
    segment_analysis <- segment_analysis %>%
      arrange(Segment_Type, desc(Fraud_Rate))
    
    cat(sprintf("✓ Analyzed %d segments\n", nrow(segment_analysis)))
  } else {
    segment_analysis <- data.frame(
      Segment_Type = "No Segments",
      Segment_Value = "N/A",
      Total_Transactions = 0,
      Fraud_Count = 0,
      Fraud_Rate = 0,
      stringsAsFactors = FALSE
    )
  }
}

# Save segment analysis
write_csv(segment_analysis, file.path(output_dir, "segment_analysis.csv"))
cat(sprintf("✓ Segment analysis saved to: %s/segment_analysis.csv\n\n", output_dir))

# Display top segments by fraud rate
if (nrow(segment_analysis) > 0 && "Fraud_Rate" %in% colnames(segment_analysis)) {
  cat("Top 10 Segments by Fraud Rate:\n")
  top_segments <- segment_analysis %>%
    filter(Total_Transactions >= 10) %>%  # Minimum transactions
    arrange(desc(Fraud_Rate)) %>%
    head(10)
  print(top_segments)
  cat("\n")
}

# =============================================================================
# Step 5: Temporal Validation
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 5: Temporal Validation\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Check if timestamp column exists
timestamp_col <- ifelse("transaction_timestamp_utc" %in% colnames(df), 
                        "transaction_timestamp_utc",
                        ifelse("Time" %in% colnames(df), "Time", NULL))

if (is.null(timestamp_col)) {
  cat("⚠ No timestamp column found. Skipping temporal validation.\n")
  cat("Creating temporal validation placeholder...\n\n")
  
  temporal_results <- data.frame(
    Train_Period = "N/A",
    Test_Period = "N/A",
    Train_Size = nrow(df),
    Test_Size = 0,
    Model = "N/A",
    Recall = 0,
    PR_AUC = 0,
    Cost_per_Transaction = 0,
    stringsAsFactors = FALSE
  )
} else {
  cat(sprintf("Using timestamp column: %s\n", timestamp_col))
  
  # Convert to date if needed
  if (timestamp_col == "transaction_timestamp_utc") {
    df$date <- as.Date(df[[timestamp_col]])
  } else {
    # Assume Time is seconds since first transaction
    first_time <- min(df[[timestamp_col]], na.rm = TRUE)
    base_date <- as.Date("2013-09-01")  # Adjust based on your data
    df$date <- base_date + as.integer((df[[timestamp_col]] - first_time) / 86400)
  }
  
  # Get date range
  min_date <- min(df$date, na.rm = TRUE)
  max_date <- max(df$date, na.rm = TRUE)
  date_range <- as.numeric(max_date - min_date)
  
  cat(sprintf("Date range: %s to %s (%d days)\n", min_date, max_date, date_range))
  
  # Split into temporal periods (train on past, test on future)
  # Use 70% for training (earlier dates), 30% for testing (later dates)
  split_date <- min_date + as.integer(date_range * 0.7)
  
  train_mask <- df$date <= split_date
  test_mask <- df$date > split_date
  
  cat(sprintf("Training period: %s to %s\n", min_date, split_date))
  cat(sprintf("Testing period: %s to %s\n", split_date + 1, max_date))
  cat(sprintf("Training samples: %d\n", sum(train_mask)))
  cat(sprintf("Testing samples: %d\n", sum(test_mask)))
  
  if (sum(train_mask) == 0 || sum(test_mask) == 0) {
    cat("⚠ Insufficient data for temporal split. Skipping temporal validation.\n\n")
    temporal_results <- data.frame(
      Train_Period = "N/A",
      Test_Period = "N/A",
      stringsAsFactors = FALSE
    )
  } else {
    # Prepare temporal train/test sets
    X_train_temp <- X[train_mask, ]
    y_train_temp <- y[train_mask]
    X_test_temp <- X[test_mask, ]
    y_test_temp <- y[test_mask]
    
    cat("\nTraining models on temporal training set...\n")
    
    temporal_results_list <- list()
    
    # Train and evaluate Logistic Regression
    cat("Training Logistic Regression...\n")
    train_df_lr <- cbind(y_train_temp, X_train_temp)
    colnames(train_df_lr)[1] <- "target"
    
    # Calculate class weights
    fraud_count <- sum(y_train_temp)
    non_fraud_count <- sum(y_train_temp == 0)
    total_count <- length(y_train_temp)
    weight_fraud <- total_count / (2 * fraud_count)
    weight_non_fraud <- total_count / (2 * non_fraud_count)
    train_weights <- ifelse(y_train_temp == 1, weight_fraud, weight_non_fraud)
    
    lr_model_temp <- glm(target ~ ., data = train_df_lr, 
                         family = binomial(link = "logit"),
                         weights = train_weights)
    
    lr_pred_temp <- predict(lr_model_temp, newdata = cbind(y_test_temp, X_test_temp), 
                           type = "response")
    
    # Find optimal threshold
    thresholds_temp <- seq(0.01, 0.99, by = 0.01)
    costs_temp <- sapply(thresholds_temp, function(t) {
      y_pred <- ifelse(lr_pred_temp >= t, 1, 0)
      cm <- table(Actual = y_test_temp, Predicted = y_pred)
      FN <- ifelse(2 %in% rownames(cm) && 1 %in% colnames(cm), 
                   cm[2, 1], 0)
      FP <- ifelse(1 %in% rownames(cm) && 2 %in% colnames(cm), 
                   cm[1, 2], 0)
      (FN * COST_FALSE_NEGATIVE + FP * COST_FALSE_POSITIVE) / length(y_test_temp)
    })
    optimal_threshold_lr <- thresholds_temp[which.min(costs_temp)]
    
    lr_metrics_temp <- calculate_comprehensive_metrics(
      y_test_temp, lr_pred_temp, optimal_threshold_lr, "Logistic Regression"
    )
    
    temporal_results_list[[1]] <- data.frame(
      Train_Period = paste0(min_date, " to ", split_date),
      Test_Period = paste0(split_date + 1, " to ", max_date),
      Train_Size = sum(train_mask),
      Test_Size = sum(test_mask),
      Model = "Logistic Regression",
      Threshold = optimal_threshold_lr,
      Recall = lr_metrics_temp$recall,
      Precision = lr_metrics_temp$precision,
      PR_AUC = lr_metrics_temp$pr_auc,
      ROC_AUC = lr_metrics_temp$roc_auc,
      Cost_per_Transaction = lr_metrics_temp$cost_per_transaction,
      Cost_Saved = lr_metrics_temp$cost_saved,
      stringsAsFactors = FALSE
    )
    
    cat("✓ Logistic Regression trained and evaluated\n")
    
    # Train and evaluate LightGBM if available
    if (!is.null(lgbm_model) && requireNamespace("lightgbm", quietly = TRUE)) {
      cat("Training LightGBM...\n")
      
      lgb_train_temp <- lgb.Dataset(
        data = as.matrix(X_train_temp),
        label = y_train_temp,
        weight = train_weights,
        free_raw_data = FALSE
      )
      
      lgb_val_temp <- lgb.Dataset(
        data = as.matrix(X_test_temp),
        label = y_test_temp,
        free_raw_data = FALSE
      )
      
      lgbm_params <- list(
        objective = "binary",
        metric = "binary_logloss",
        boosting_type = "gbdt",
        num_leaves = 31,
        learning_rate = 0.05,
        scale_pos_weight = weight_fraud / weight_non_fraud,
        verbose = -1
      )
      
      lgbm_model_temp <- lgb.train(
        params = lgbm_params,
        data = lgb_train_temp,
        valids = list(validation = lgb_val_temp),
        nrounds = 200,
        early_stopping_rounds = 50,
        verbose = -1
      )
      
      lgbm_pred_temp <- predict(lgbm_model_temp, as.matrix(X_test_temp))
      
      # Find optimal threshold
      costs_temp <- sapply(thresholds_temp, function(t) {
        y_pred <- ifelse(lgbm_pred_temp >= t, 1, 0)
        cm <- table(Actual = y_test_temp, Predicted = y_pred)
        FN <- ifelse(2 %in% rownames(cm) && 1 %in% colnames(cm), 
                     cm[2, 1], 0)
        FP <- ifelse(1 %in% rownames(cm) && 2 %in% colnames(cm), 
                     cm[1, 2], 0)
        (FN * COST_FALSE_NEGATIVE + FP * COST_FALSE_POSITIVE) / length(y_test_temp)
      })
      optimal_threshold_lgbm <- thresholds_temp[which.min(costs_temp)]
      
      lgbm_metrics_temp <- calculate_comprehensive_metrics(
        y_test_temp, lgbm_pred_temp, optimal_threshold_lgbm, "LightGBM"
      )
      
      temporal_results_list[[2]] <- data.frame(
        Train_Period = paste0(min_date, " to ", split_date),
        Test_Period = paste0(split_date + 1, " to ", max_date),
        Train_Size = sum(train_mask),
        Test_Size = sum(test_mask),
        Model = "LightGBM",
        Threshold = optimal_threshold_lgbm,
        Recall = lgbm_metrics_temp$recall,
        Precision = lgbm_metrics_temp$precision,
        PR_AUC = lgbm_metrics_temp$pr_auc,
        ROC_AUC = lgbm_metrics_temp$roc_auc,
        Cost_per_Transaction = lgbm_metrics_temp$cost_per_transaction,
        Cost_Saved = lgbm_metrics_temp$cost_saved,
        stringsAsFactors = FALSE
      )
      
      cat("✓ LightGBM trained and evaluated\n")
    }
    
    temporal_results <- do.call(rbind, temporal_results_list)
    
    cat("\nTemporal Validation Results:\n")
    print(temporal_results)
  }
}

# Save temporal validation results
write_csv(temporal_results, file.path(output_dir, "temporal_validation.csv"))
cat(sprintf("\n✓ Temporal validation saved to: %s/temporal_validation.csv\n\n", output_dir))

# =============================================================================
# Step 6: Generate Visualizations
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 6: Generating Visualizations\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# ROC Curves
cat("Generating ROC curves...\n")
roc_plots <- list()

if (!is.null(lr_metrics$roc_obj)) {
  roc_data_lr <- data.frame(
    FPR = 1 - lr_metrics$roc_obj$specificities,
    TPR = lr_metrics$roc_obj$sensitivities,
    Model = "Logistic Regression"
  )
  roc_plots[[1]] <- roc_data_lr
}

if (!is.null(lgbm_model) && !is.null(lgbm_metrics$roc_obj)) {
  roc_data_lgbm <- data.frame(
    FPR = 1 - lgbm_metrics$roc_obj$specificities,
    TPR = lgbm_metrics$roc_obj$sensitivities,
    Model = "LightGBM"
  )
  roc_plots[[length(roc_plots) + 1]] <- roc_data_lgbm
}

if (!is.null(xgb_model) && !is.null(xgb_metrics$roc_obj)) {
  roc_data_xgb <- data.frame(
    FPR = 1 - xgb_metrics$roc_obj$specificities,
    TPR = xgb_metrics$roc_obj$sensitivities,
    Model = "XGBoost"
  )
  roc_plots[[length(roc_plots) + 1]] <- roc_data_xgb
}

if (length(roc_plots) > 0) {
  roc_data_all <- do.call(rbind, roc_plots)
  
  p_roc <- ggplot(roc_data_all, aes(x = FPR, y = TPR, color = Model)) +
    geom_line(size = 1) +
    geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray") +
    labs(title = "ROC Curves - Model Comparison",
         x = "False Positive Rate (1 - Specificity)",
         y = "True Positive Rate (Sensitivity/Recall)") +
    theme_minimal() +
    theme(legend.position = "bottom")
  
  ggsave(file.path(output_dir, "roc_curves.png"), p_roc, width = 10, height = 6)
  cat("✓ ROC curves saved\n")
}

# PR Curves
cat("Generating Precision-Recall curves...\n")
pr_plots <- list()

if (!is.null(lr_metrics$pr_obj)) {
  pr_data_lr <- data.frame(
    Recall = lr_metrics$pr_obj$curve[, 1],
    Precision = lr_metrics$pr_obj$curve[, 2],
    Model = "Logistic Regression"
  )
  pr_plots[[1]] <- pr_data_lr
}

if (!is.null(lgbm_model) && !is.null(lgbm_metrics$pr_obj)) {
  pr_data_lgbm <- data.frame(
    Recall = lgbm_metrics$pr_obj$curve[, 1],
    Precision = lgbm_metrics$pr_obj$curve[, 2],
    Model = "LightGBM"
  )
  pr_plots[[length(pr_plots) + 1]] <- pr_data_lgbm
}

if (!is.null(xgb_model) && !is.null(xgb_metrics$pr_obj)) {
  pr_data_xgb <- data.frame(
    Recall = xgb_metrics$pr_obj$curve[, 1],
    Precision = xgb_metrics$pr_obj$curve[, 2],
    Model = "XGBoost"
  )
  pr_plots[[length(pr_plots) + 1]] <- pr_data_xgb
}

if (length(pr_plots) > 0) {
  pr_data_all <- do.call(rbind, pr_plots)
  
  p_pr <- ggplot(pr_data_all, aes(x = Recall, y = Precision, color = Model)) +
    geom_line(size = 1) +
    labs(title = "Precision-Recall Curves - Model Comparison",
         x = "Recall (Sensitivity)",
         y = "Precision") +
    theme_minimal() +
    theme(legend.position = "bottom")
  
  ggsave(file.path(output_dir, "pr_curves.png"), p_pr, width = 10, height = 6)
  cat("✓ Precision-Recall curves saved\n")
}

# Metrics comparison bar chart
cat("Generating metrics comparison chart...\n")
metrics_long <- metrics_summary %>%
  select(Model, Recall, Precision, F1_Score, ROC_AUC, PR_AUC) %>%
  tidyr::pivot_longer(cols = -Model, names_to = "Metric", values_to = "Value")

p_metrics <- ggplot(metrics_long, aes(x = Model, y = Value, fill = Metric)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Model Performance Metrics Comparison",
       x = "Model",
       y = "Score") +
  theme_minimal() +
  theme(legend.position = "bottom",
        axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(output_dir, "metrics_comparison.png"), p_metrics, width = 10, height = 6)
cat("✓ Metrics comparison chart saved\n")

cat("\n✓ All visualizations saved to: ", output_dir, "/\n\n")

# =============================================================================
# Step 7: Summary Report
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("EVALUATION COMPLETE!\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

cat("Summary:\n")
cat(sprintf("  Comprehensive metrics calculated for %d models\n", length(metrics_list)))
cat(sprintf("  Segment analysis: %d segments analyzed\n", nrow(segment_analysis)))
cat(sprintf("  Temporal validation: %d models evaluated\n", 
            ifelse(exists("temporal_results"), nrow(temporal_results), 0)))
cat(sprintf("  Visualizations generated: 3 plots\n"))
cat(sprintf("\nAll results saved to: %s/\n", output_dir))
cat("\nFiles generated:\n")
cat("  - comprehensive_metrics.csv\n")
cat("  - segment_analysis.csv\n")
cat("  - temporal_validation.csv\n")
cat("  - roc_curves.png\n")
cat("  - pr_curves.png\n")
cat("  - metrics_comparison.png\n")






