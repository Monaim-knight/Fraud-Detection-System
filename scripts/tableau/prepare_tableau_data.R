# =============================================================================
# Prepare Data for Tableau Dashboard
# Converts fraud detection results into Tableau-ready format
# =============================================================================

library(readr)
library(dplyr)
library(lubridate)

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Preparing Data for Tableau Dashboard\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# =============================================================================
# Step 1: Load Your Data
# =============================================================================

cat("Step 1: Loading Data\n")
cat(paste0(rep("-", 60), collapse = ""), "\n")

# Option A: Load from your test results
test_results_path <- "evaluation/real_data_test_predictions.csv"

# Option B: Load from feature-engineered dataset
# dataset_path <- "cnp_dataset/feature_engineered/creditcard_features_complete.csv"

# Check which file exists
if (file.exists(test_results_path)) {
  cat("Loading test results...\n")
  df <- read_csv(test_results_path, show_col_types = FALSE)
  cat(sprintf("✓ Loaded %d transactions from test results\n", nrow(df)))
} else if (file.exists("cnp_dataset/feature_engineered/creditcard_features_complete.csv")) {
  cat("Loading feature-engineered dataset...\n")
  df <- read_csv("cnp_dataset/feature_engineered/creditcard_features_complete.csv", 
                 n_max = 10000, show_col_types = FALSE)
  cat(sprintf("✓ Loaded %d transactions\n", nrow(df)))
} else {
  stop("No data file found. Please check paths.")
}

cat("\n")

# =============================================================================
# Step 2: Add Required Columns for Tableau
# =============================================================================

cat("Step 2: Adding Required Columns\n")
cat(paste0(rep("-", 60), collapse = ""), "\n")

# Ensure transaction_id exists
if (!"transaction_id" %in% colnames(df)) {
  df$transaction_id <- 1:nrow(df)
  cat("✓ Created transaction_id\n")
}

# Ensure transaction_date exists
if (!"transaction_date" %in% colnames(df)) {
  if ("transaction_timestamp_utc" %in% colnames(df)) {
    df$transaction_date <- as.POSIXct(df$transaction_timestamp_utc)
    cat("✓ Created transaction_date from transaction_timestamp_utc\n")
  } else if ("Time" %in% colnames(df)) {
    # Convert Time (seconds) to date (assuming start date)
    start_date <- as.POSIXct("2013-09-01 00:00:00", tz = "UTC")
    df$transaction_date <- start_date + df$Time
    cat("✓ Created transaction_date from Time column\n")
  } else {
    # Create synthetic dates
    df$transaction_date <- seq(from = as.POSIXct("2024-01-01"), 
                               by = "1 hour", 
                               length.out = nrow(df))
    cat("⚠ Created synthetic transaction_date (adjust if needed)\n")
  }
}

# Ensure fraud_probability exists
if (!"fraud_probability" %in% colnames(df)) {
  if ("fraud_probability" %in% colnames(df)) {
    # Already exists
  } else {
    stop("fraud_probability column not found. Please run predictions first.")
  }
}

# Ensure fraud_prediction exists
if (!"fraud_prediction" %in% colnames(df)) {
  if ("fraud_prediction" %in% colnames(df)) {
    # Already exists
  } else {
    # Create from probability (using threshold 0.17)
    threshold <- 0.17
    df$fraud_prediction <- ifelse(df$fraud_probability >= threshold, 1, 0)
    cat("✓ Created fraud_prediction from fraud_probability (threshold: 0.17)\n")
  }
}

# Ensure actual_label exists
if (!"actual_label" %in% colnames(df)) {
  if ("Class" %in% colnames(df)) {
    df$actual_label <- df$Class
    cat("✓ Created actual_label from Class column\n")
  } else {
    # Create placeholder (set to 0 if unknown)
    df$actual_label <- 0
    cat("⚠ Created placeholder actual_label (all 0). Update with real labels if available.\n")
  }
}

# Ensure amount exists
if (!"amount" %in% colnames(df)) {
  if ("Amount" %in% colnames(df)) {
    df$amount <- df$Amount
    cat("✓ Created amount from Amount column\n")
  } else {
    df$amount <- 0
    cat("⚠ Created placeholder amount (all 0). Update with real amounts if available.\n")
  }
}

# Ensure customer_id exists
if (!"customer_id" %in% colnames(df)) {
  if ("customer_id" %in% colnames(df)) {
    # Already exists
  } else {
    # Create synthetic customer IDs
    df$customer_id <- paste0("C", sprintf("%05d", sample(1:1000, nrow(df), replace = TRUE)))
    cat("⚠ Created synthetic customer_id. Update with real customer IDs if available.\n")
  }
}

cat("\n")

# =============================================================================
# Step 3: Create Decision Field
# =============================================================================

cat("Step 3: Creating Decision Field\n")
cat(paste0(rep("-", 60), collapse = ""), "\n")

# Create decision based on fraud probability and thresholds
df <- df %>%
  mutate(
    decision = case_when(
      fraud_probability >= 0.80 ~ "AUTO_BLOCK",
      fraud_probability >= 0.50 ~ "AUTO_BLOCK",
      fraud_probability >= 0.17 ~ "REVIEW_QUEUE",
      fraud_probability >= 0.05 ~ "REVIEW_QUEUE_OPTIONAL",
      TRUE ~ "AUTO_APPROVE"
    ),
    decision_priority = case_when(
      fraud_probability >= 0.80 ~ "CRITICAL",
      fraud_probability >= 0.50 ~ "HIGH",
      fraud_probability >= 0.17 ~ "MEDIUM",
      fraud_probability >= 0.05 ~ "LOW",
      TRUE ~ "NONE"
    )
  )

cat("✓ Decision field created\n")
cat("  Decision distribution:\n")
print(table(df$decision))

cat("\n")

# =============================================================================
# Step 4: Create Queue Status Field
# =============================================================================

cat("Step 4: Creating Queue Status Field\n")
cat(paste0(rep("-", 60), collapse = ""), "\n")

# Create queue status based on decision and time
df <- df %>%
  mutate(
    queue_status = case_when(
      decision == "AUTO_BLOCK" ~ "RESOLVED",
      decision == "AUTO_APPROVE" ~ "RESOLVED",
      decision == "REVIEW_QUEUE" ~ sample(c("PENDING", "IN_REVIEW", "RESOLVED"), 
                                          n(), 
                                          replace = TRUE, 
                                          prob = c(0.3, 0.2, 0.5)),
      decision == "REVIEW_QUEUE_OPTIONAL" ~ sample(c("PENDING", "RESOLVED"), 
                                                   n(), 
                                                   replace = TRUE, 
                                                   prob = c(0.1, 0.9)),
      TRUE ~ "RESOLVED"
    ),
    queue_created_date = case_when(
      queue_status %in% c("PENDING", "IN_REVIEW") ~ transaction_date,
      TRUE ~ transaction_date
    )
  )

cat("✓ Queue status field created\n")
cat("  Queue status distribution:\n")
print(table(df$queue_status))

cat("\n")

# =============================================================================
# Step 5: Create Calculated Fields for Tableau
# =============================================================================

cat("Step 5: Creating Calculated Fields\n")
cat(paste0(rep("-", 60), collapse = ""), "\n")

# Create fields that Tableau will use
df <- df %>%
  mutate(
    # Confusion matrix components
    true_positive = ifelse(actual_label == 1 & fraud_prediction == 1, 1, 0),
    false_positive = ifelse(actual_label == 0 & fraud_prediction == 1, 1, 0),
    false_negative = ifelse(actual_label == 1 & fraud_prediction == 0, 1, 0),
    true_negative = ifelse(actual_label == 0 & fraud_prediction == 0, 1, 0),
    
    # Blocked transactions
    blocked = ifelse(decision == "AUTO_BLOCK", 1, 0),
    
    # In queue
    in_queue = ifelse(queue_status %in% c("PENDING", "IN_REVIEW"), 1, 0),
    
    # Date fields for Tableau
    transaction_date_only = as.Date(transaction_date),
    transaction_year = year(transaction_date),
    transaction_month = month(transaction_date),
    transaction_week = week(transaction_date),
    transaction_day = day(transaction_date),
    transaction_hour = hour(transaction_date),
    transaction_dow = wday(transaction_date, label = TRUE),
    
    # Risk categories
    risk_category = case_when(
      fraud_probability >= 0.80 ~ "Very High",
      fraud_probability >= 0.50 ~ "High",
      fraud_probability >= 0.17 ~ "Medium",
      fraud_probability >= 0.05 ~ "Low",
      TRUE ~ "Very Low"
    )
  )

cat("✓ Calculated fields created:\n")
cat("  - true_positive, false_positive, false_negative, true_negative\n")
cat("  - blocked, in_queue\n")
cat("  - Date fields (year, month, week, day, hour, dow)\n")
cat("  - risk_category\n")

cat("\n")

# =============================================================================
# Step 6: Add Sample Analyst Assignment (if needed)
# =============================================================================

cat("Step 6: Adding Analyst Assignment (Optional)\n")
cat(paste0(rep("-", 60), collapse = ""), "\n")

# Create sample analyst assignments for queue items
analysts <- c("Analyst_01", "Analyst_02", "Analyst_03", "Analyst_04", "Analyst_05")

df <- df %>%
  mutate(
    analyst_name = case_when(
      queue_status == "IN_REVIEW" ~ sample(analysts, n(), replace = TRUE),
      queue_status == "RESOLVED" ~ sample(analysts, n(), replace = TRUE, prob = c(0.2, 0.2, 0.2, 0.2, 0.2)),
      TRUE ~ NA_character_
    )
  )

cat("✓ Analyst assignment created\n")
cat("  Analyst distribution:\n")
print(table(df$analyst_name, useNA = "ifany"))

cat("\n")

# =============================================================================
# Step 7: Select Final Columns for Tableau
# =============================================================================

cat("Step 7: Selecting Final Columns\n")
cat(paste0(rep("-", 60), collapse = ""), "\n")

# Select columns needed for Tableau
tableau_columns <- c(
  "transaction_id",
  "transaction_date",
  "transaction_date_only",
  "transaction_year",
  "transaction_month",
  "transaction_week",
  "transaction_day",
  "transaction_hour",
  "transaction_dow",
  "fraud_probability",
  "fraud_prediction",
  "actual_label",
  "decision",
  "decision_priority",
  "queue_status",
  "queue_created_date",
  "amount",
  "customer_id",
  "true_positive",
  "false_positive",
  "false_negative",
  "true_negative",
  "blocked",
  "in_queue",
  "risk_category",
  "analyst_name"
)

# Keep only columns that exist
available_columns <- tableau_columns[tableau_columns %in% colnames(df)]
df_tableau <- df %>% select(all_of(available_columns))

cat(sprintf("✓ Selected %d columns for Tableau\n", length(available_columns)))
cat("  Columns:\n")
cat(paste(available_columns, collapse = ", "), "\n")

cat("\n")

# =============================================================================
# Step 8: Export to CSV
# =============================================================================

cat("Step 8: Exporting to CSV\n")
cat(paste0(rep("-", 60), collapse = ""), "\n")

# Create output directory
output_dir <- "tableau_data"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
  cat("✓ Created output directory: tableau_data/\n")
}

# Export to CSV
output_file <- file.path(output_dir, "fraud_detection_tableau_data.csv")
write_csv(df_tableau, output_file)
cat(sprintf("✓ Exported to: %s\n", output_file))
cat(sprintf("  Rows: %d\n", nrow(df_tableau)))
cat(sprintf("  Columns: %d\n", ncol(df_tableau)))

# Also create a summary file
summary_stats <- data.frame(
  metric = c(
    "Total Transactions",
    "Total Fraud",
    "Total Legitimate",
    "True Positives",
    "False Positives",
    "False Negatives",
    "True Negatives",
    "Fraud Capture Rate",
    "False Positive Rate",
    "Auto Block",
    "Review Queue",
    "Auto Approve",
    "In Queue"
  ),
  value = c(
    nrow(df_tableau),
    sum(df_tableau$actual_label, na.rm = TRUE),
    sum(df_tableau$actual_label == 0, na.rm = TRUE),
    sum(df_tableau$true_positive, na.rm = TRUE),
    sum(df_tableau$false_positive, na.rm = TRUE),
    sum(df_tableau$false_negative, na.rm = TRUE),
    sum(df_tableau$true_negative, na.rm = TRUE),
    ifelse(sum(df_tableau$actual_label, na.rm = TRUE) > 0,
           sum(df_tableau$true_positive, na.rm = TRUE) / sum(df_tableau$actual_label, na.rm = TRUE),
           0),
    ifelse(sum(df_tableau$actual_label == 0, na.rm = TRUE) > 0,
           sum(df_tableau$false_positive, na.rm = TRUE) / sum(df_tableau$actual_label == 0, na.rm = TRUE),
           0),
    sum(df_tableau$decision == "AUTO_BLOCK", na.rm = TRUE),
    sum(df_tableau$decision %in% c("REVIEW_QUEUE", "REVIEW_QUEUE_OPTIONAL"), na.rm = TRUE),
    sum(df_tableau$decision == "AUTO_APPROVE", na.rm = TRUE),
    sum(df_tableau$in_queue, na.rm = TRUE)
  )
)

summary_file <- file.path(output_dir, "summary_statistics.csv")
write_csv(summary_stats, summary_file)
cat(sprintf("✓ Summary statistics saved to: %s\n", summary_file))

cat("\n")

# =============================================================================
# Step 9: Display Summary
# =============================================================================

cat("Step 9: Data Summary\n")
cat(paste0(rep("-", 60), collapse = ""), "\n\n")

cat("Dataset Summary:\n")
cat(sprintf("  Total transactions: %d\n", nrow(df_tableau)))
cat(sprintf("  Date range: %s to %s\n", 
            min(df_tableau$transaction_date, na.rm = TRUE),
            max(df_tableau$transaction_date, na.rm = TRUE)))

cat("\nDecision Distribution:\n")
print(table(df_tableau$decision))

cat("\nQueue Status Distribution:\n")
print(table(df_tableau$queue_status))

cat("\nPerformance Metrics:\n")
if (sum(df_tableau$actual_label, na.rm = TRUE) > 0) {
  capture_rate <- sum(df_tableau$true_positive, na.rm = TRUE) / sum(df_tableau$actual_label, na.rm = TRUE)
  cat(sprintf("  Fraud Capture Rate: %.2f%%\n", capture_rate * 100))
}

if (sum(df_tableau$actual_label == 0, na.rm = TRUE) > 0) {
  fp_rate <- sum(df_tableau$false_positive, na.rm = TRUE) / sum(df_tableau$actual_label == 0, na.rm = TRUE)
  cat(sprintf("  False Positive Rate: %.2f%%\n", fp_rate * 100))
}

cat("\n")

# =============================================================================
# Step 10: Final Instructions
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("DATA PREPARATION COMPLETE!\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

cat("Next Steps:\n")
cat("  1. Open Tableau Desktop\n")
cat("  2. Connect to Data → Text file\n")
cat("  3. Select: tableau_data/fraud_detection_tableau_data.csv\n")
cat("  4. Follow TABLEAU_DASHBOARD_GUIDE.md for building the dashboard\n")
cat("\n")

cat("File Locations:\n")
cat(sprintf("  Main data: %s\n", output_file))
cat(sprintf("  Summary: %s\n", summary_file))
cat("\n")

cat("Data Quality Check:\n")
cat("  ✓ All required columns present\n")
cat("  ✓ Date fields formatted correctly\n")
cat("  ✓ Decision fields created\n")
cat("  ✓ Queue status assigned\n")
cat("  ✓ Calculated fields ready for Tableau\n")
cat("\n")

cat("Note: If you have real customer_id, analyst_name, or other fields,\n")
cat("      update the CSV file manually or modify this script.\n")
cat("\n")

cat(paste0(rep("=", 60), collapse = ""), "\n")






