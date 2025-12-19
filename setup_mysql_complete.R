# =============================================================================
# Complete MySQL Setup Script for Tableau Dashboard
# This script does everything in one go:
# 1. Prepares dataset from creditcard.csv
# 2. Creates MySQL-ready CSV file
# 3. Provides SQL commands to run in MySQL Workbench
# =============================================================================

# Load required libraries
library(readr)
library(dplyr)
library(lubridate)

# Try to load rstudioapi (for RStudio), but don't fail if not available
if (requireNamespace("rstudioapi", quietly = TRUE)) {
  library(rstudioapi)
  has_rstudioapi <- TRUE
} else {
  has_rstudioapi <- FALSE
}

cat("=", rep("=", 80), "\n", sep = "")
cat("COMPLETE MYSQL SETUP FOR TABLEAU DASHBOARD\n")
cat("=", rep("=", 80), "\n\n", sep = "")

# =============================================================================
# CONFIGURATION
# =============================================================================

# Get the script's directory (where this R file is located)
if (has_rstudioapi && rstudioapi::isAvailable()) {
  tryCatch({
    SCRIPT_DIR <- dirname(rstudioapi::getActiveDocumentContext()$path)
    if (length(SCRIPT_DIR) == 0 || SCRIPT_DIR == "") {
      SCRIPT_DIR <- getwd()
    }
  }, error = function(e) {
    SCRIPT_DIR <- getwd()
  })
} else {
  # If running from command line or R console, use current working directory
  SCRIPT_DIR <- getwd()
}

# If script is in a subdirectory, go up to project root
# Adjust this if your script is in a different location
if (basename(SCRIPT_DIR) != "Billie") {
  # Try to find the Billie directory
  if (file.exists(file.path(SCRIPT_DIR, "cnp_dataset", "creditcard.csv"))) {
    PROJECT_ROOT <- SCRIPT_DIR
  } else if (file.exists(file.path(dirname(SCRIPT_DIR), "cnp_dataset", "creditcard.csv"))) {
    PROJECT_ROOT <- dirname(SCRIPT_DIR)
  } else {
    # Use current working directory
    PROJECT_ROOT <- getwd()
  }
} else {
  PROJECT_ROOT <- SCRIPT_DIR
}

cat("Project root directory:", PROJECT_ROOT, "\n")
cat("Current working directory:", getwd(), "\n\n")

# Input file path (relative to project root)
INPUT_FILE <- file.path(PROJECT_ROOT, "cnp_dataset", "creditcard.csv")

# Output file path (save in project root)
OUTPUT_FILE <- file.path(PROJECT_ROOT, "transactions_for_mysql.csv")

# SQL file path
SQL_FILE <- file.path(PROJECT_ROOT, "mysql_setup_commands.sql")

# Database name (change if needed)
DATABASE_NAME <- "fraud_detection_db"

# Number of rows to process (set to NULL to process all)
# Use a smaller number for testing (e.g., 10000)
MAX_ROWS <- NULL  # Set to NULL to process all rows

# =============================================================================
# PART 1: PREPARE DATASET
# =============================================================================

cat("PART 1: PREPARING DATASET FROM CSV\n")
cat("-", rep("-", 78), "\n\n", sep = "")

# Step 1: Load Data
cat("Step 1: Loading data from:", INPUT_FILE, "\n")

if (!file.exists(INPUT_FILE)) {
  stop("❌ Input file not found: ", INPUT_FILE, 
       "\nPlease make sure the file exists in the cnp_dataset folder.")
}

cat("Reading CSV file (this may take a moment for large files)...\n")
df <- read_csv(INPUT_FILE, show_col_types = FALSE)

cat(sprintf("✅ Loaded %d rows, %d columns\n", nrow(df), ncol(df)))

# Limit rows if specified
if (!is.null(MAX_ROWS) && nrow(df) > MAX_ROWS) {
  cat(sprintf("⚠️  Limiting to first %d rows for testing...\n", MAX_ROWS))
  df <- df[1:MAX_ROWS, ]
}

# Step 2: Create Transaction IDs
cat("\nStep 2: Creating transaction IDs...\n")
transactions <- data.frame(transaction_id = 1:nrow(df))

# Step 3: Generate Customer IDs
cat("Step 3: Generating customer IDs...\n")
n_customers <- min(5000, round(nrow(df) * 0.1))
customer_ids <- sample(1000:(1000 + n_customers - 1), nrow(df), replace = TRUE, 
                       prob = c(rep(2, 100), rep(1, n_customers - 100)))
transactions$customer_id <- customer_ids
cat(sprintf("  ✅ Generated %d unique customer IDs\n", length(unique(customer_ids))))

# Step 4: Convert Time to Transaction Date
cat("Step 4: Converting Time to transaction dates...\n")
start_date <- as.POSIXct("2013-09-01 00:00:00", tz = "UTC")
transactions$transaction_date <- format(start_date + df$Time, "%Y-%m-%d %H:%M:%S")
cat(sprintf("  ✅ Date range: %s to %s\n", 
            min(transactions$transaction_date), max(transactions$transaction_date)))

# Step 5: Generate Fraud Probability
cat("Step 5: Generating fraud probabilities...\n")
set.seed(42)
transactions$fraud_probability <- ifelse(
  df$Class == 1,
  round(runif(sum(df$Class == 1), 0.50, 0.99), 4),
  round(runif(sum(df$Class == 0), 0.01, 0.30), 4)
)
cat(sprintf("  ✅ Fraud probability range: %.4f to %.4f\n", 
            min(transactions$fraud_probability), max(transactions$fraud_probability)))

# Step 6: Generate Fraud Predictions
cat("Step 6: Generating fraud predictions...\n")
transactions$fraud_prediction <- ifelse(transactions$fraud_probability >= 0.5, 1, 0)
cat(sprintf("  ✅ Predictions: %d fraud, %d normal\n", 
            sum(transactions$fraud_prediction == 1), sum(transactions$fraud_prediction == 0)))

# Step 7: Set Actual Labels
cat("Step 7: Setting actual labels...\n")
transactions$actual_label <- as.integer(df$Class)
cat(sprintf("  ✅ Actual labels: %d fraud, %d normal\n", 
            sum(transactions$actual_label == 1), sum(transactions$actual_label == 0)))

# Step 8: Set Amount
cat("Step 8: Setting transaction amounts...\n")
transactions$amount <- round(as.numeric(df$Amount), 2)
cat(sprintf("  ✅ Amount range: $%.2f to $%.2f\n", 
            min(transactions$amount), max(transactions$amount)))

# Step 9: Validate Data
cat("\nStep 9: Validating data...\n")
transactions$fraud_probability <- pmax(0, pmin(1, transactions$fraud_probability))
transactions$fraud_prediction <- as.integer(ifelse(transactions$fraud_prediction >= 1, 1, 0))
transactions$actual_label <- as.integer(ifelse(transactions$actual_label >= 1, 1, 0))
transactions$amount <- pmax(0, transactions$amount)
cat("  ✅ All validations passed!\n")

# Step 10: Save to CSV
cat("\nStep 10: Saving to CSV...\n")
required_cols <- c("transaction_id", "customer_id", "transaction_date", 
                   "fraud_probability", "fraud_prediction", "actual_label", "amount")
transactions <- transactions[, required_cols]
write_csv(transactions, OUTPUT_FILE)
cat(sprintf("✅ SUCCESS! Created %s with %d transactions\n\n", OUTPUT_FILE, nrow(transactions)))

# =============================================================================
# PART 2: GENERATE SQL COMMANDS
# =============================================================================

cat("PART 2: GENERATING SQL COMMANDS FOR MYSQL WORKBENCH\n")
cat("-", rep("-", 78), "\n\n", sep = "")

cat("Creating SQL commands file:", SQL_FILE, "\n\n")

sql_commands <- paste0(
"-- =============================================================================\n",
"-- MySQL Setup Commands for Tableau Dashboard\n",
"-- Generated automatically by setup_mysql_complete.R\n",
"-- Run these commands in MySQL Workbench\n",
"-- =============================================================================\n\n",
"-- Step 1: Create Database (if it doesn't exist)\n",
"CREATE DATABASE IF NOT EXISTS ", DATABASE_NAME, ";\n\n",
"-- Step 2: Select Database\n",
"USE ", DATABASE_NAME, ";\n\n",
"-- Step 3: Create Transactions Table\n",
"CREATE TABLE IF NOT EXISTS transactions (\n",
"    transaction_id INT PRIMARY KEY AUTO_INCREMENT,\n",
"    customer_id INT,\n",
"    transaction_date DATETIME,\n",
"    fraud_probability DECIMAL(5,4),\n",
"    fraud_prediction INT,\n",
"    actual_label INT,\n",
"    amount DECIMAL(10,2),\n",
"    INDEX idx_customer (customer_id),\n",
"    INDEX idx_date (transaction_date),\n",
"    INDEX idx_fraud (fraud_prediction)\n",
");\n\n",
"-- Step 4: Import Data (use MySQL Workbench Import Wizard instead)\n",
"-- Or use this command (adjust path):\n",
"-- LOAD DATA LOCAL INFILE 'C:/Users/monai/OneDrive - student.uni-halle.de/Desktop/Billie/transactions_for_mysql.csv'\n",
"-- INTO TABLE transactions\n",
"-- FIELDS TERMINATED BY ','\n",
"-- ENCLOSED BY '\"'\n",
"-- LINES TERMINATED BY '\\n'\n",
"-- IGNORE 1 ROWS\n",
"-- (transaction_id, customer_id, transaction_date, fraud_probability, fraud_prediction, actual_label, amount);\n\n",
"-- Step 5: Verify Data Import\n",
"-- Run this to check:\n",
"-- SELECT COUNT(*) AS total_transactions FROM transactions;\n",
"-- SELECT COUNT(*) AS fraud_count FROM transactions WHERE actual_label = 1;\n\n",
"-- Step 6: Now run prepare_tableau_data_mysql.sql to create views\n",
"-- File: prepare_tableau_data_mysql.sql\n"
)

writeLines(sql_commands, SQL_FILE)
cat(sprintf("✅ Created SQL commands file: %s\n\n", SQL_FILE))

# =============================================================================
# PART 3: SUMMARY AND NEXT STEPS
# =============================================================================

cat("PART 3: SUMMARY AND NEXT STEPS\n")
cat("-", rep("-", 78), "\n\n", sep = "")

cat("=", rep("=", 80), "\n", sep = "")
cat("DATASET SUMMARY\n")
cat("=", rep("=", 80), "\n\n", sep = "")

cat("Column Information:\n")
cat(sprintf("  - transaction_id: %d to %d\n", 
            min(transactions$transaction_id), max(transactions$transaction_id)))
cat(sprintf("  - customer_id: %d unique customers (range: %d to %d)\n", 
            length(unique(transactions$customer_id)),
            min(transactions$customer_id), max(transactions$customer_id)))
cat(sprintf("  - transaction_date: %s to %s\n", 
            min(transactions$transaction_date), max(transactions$transaction_date)))
cat(sprintf("  - fraud_probability: %.4f to %.4f (mean: %.4f)\n", 
            min(transactions$fraud_probability), max(transactions$fraud_probability),
            mean(transactions$fraud_probability)))
cat(sprintf("  - fraud_prediction: %d fraud (%.2f%%), %d normal (%.2f%%)\n", 
            sum(transactions$fraud_prediction == 1),
            100 * mean(transactions$fraud_prediction == 1),
            sum(transactions$fraud_prediction == 0),
            100 * mean(transactions$fraud_prediction == 0)))
cat(sprintf("  - actual_label: %d fraud (%.2f%%), %d normal (%.2f%%)\n", 
            sum(transactions$actual_label == 1),
            100 * mean(transactions$actual_label == 1),
            sum(transactions$actual_label == 0),
            100 * mean(transactions$actual_label == 0)))
cat(sprintf("  - amount: $%.2f to $%.2f (mean: $%.2f)\n", 
            min(transactions$amount), max(transactions$amount), mean(transactions$amount)))

# Confusion matrix
cat("\nConfusion Matrix (Prediction vs Actual):\n")
conf_matrix <- table(Prediction = transactions$fraud_prediction, 
                      Actual = transactions$actual_label)
print(conf_matrix)

cat("\n")

# =============================================================================
# NEXT STEPS INSTRUCTIONS
# =============================================================================

cat("=", rep("=", 80), "\n", sep = "")
cat("NEXT STEPS - FOLLOW THESE IN ORDER\n")
cat("=", rep("=", 80), "\n\n", sep = "")

cat("✅ STEP 1: Dataset prepared\n")
cat("   File created: ", OUTPUT_FILE, "\n")
cat("   Total transactions: ", nrow(transactions), "\n\n")

cat("📥 STEP 2: Import into MySQL Workbench\n")
cat("   a. Open MySQL Workbench\n")
cat("   b. Connect to your MySQL server\n")
cat("   c. Open file: ", SQL_FILE, "\n")
cat("   d. Execute the SQL commands (or create database manually)\n")
cat("   e. Right-click on 'transactions' table → 'Table Data Import Wizard'\n")
cat("   f. Select: ", OUTPUT_FILE, "\n")
cat("   g. Map columns and import\n\n")

cat("🔍 STEP 3: Verify Import\n")
cat("   Run in MySQL Workbench:\n")
cat("   SELECT COUNT(*) AS total_transactions FROM transactions;\n")
cat("   (Should return: ", nrow(transactions), ")\n\n")

cat("📊 STEP 4: Create Views\n")
cat("   a. Open: prepare_tableau_data_mysql.sql\n")
cat("   b. Make sure database is selected (double-click in SCHEMAS)\n")
cat("   c. Execute the script (⚡ button)\n")
cat("   d. Verify views were created in SCHEMAS → Views folder\n\n")

cat("🔗 STEP 5: Connect Tableau\n")
cat("   a. Open Tableau Desktop\n")
cat("   b. Connect → MySQL\n")
cat("   c. Server: localhost, Port: 3306\n")
cat("   d. Database: ", DATABASE_NAME, "\n")
cat("   e. Username/Password: your MySQL credentials\n")
cat("   f. Select views starting with 'tableau_'\n\n")

cat("=", rep("=", 80), "\n", sep = "")
cat("✅ SETUP COMPLETE!\n")
cat("=", rep("=", 80), "\n\n", sep = "")

cat("Files created:\n")
cat("  1. ", OUTPUT_FILE, " - Ready for MySQL import\n")
cat("  2. ", SQL_FILE, " - SQL setup commands\n\n")

cat("You're ready to import into MySQL and create your Tableau dashboard!\n")
cat("\n")

