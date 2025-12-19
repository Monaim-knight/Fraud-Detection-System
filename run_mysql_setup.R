# =============================================================================
# MySQL Setup Script - Run This File
# This script automatically finds your files and prepares everything
# =============================================================================

# Load required libraries
library(readr)
library(dplyr)
library(lubridate)

cat("=", rep("=", 80), "\n", sep = "")
cat("MYSQL SETUP FOR TABLEAU DASHBOARD\n")
cat("=", rep("=", 80), "\n\n", sep = "")

# =============================================================================
# AUTO-DETECT PROJECT ROOT
# =============================================================================

# Try multiple ways to find the project root
find_project_root <- function() {
  # Method 1: Check current directory
  if (file.exists("cnp_dataset/creditcard.csv")) {
    return(getwd())
  }
  
  # Method 2: Check parent directory
  parent_dir <- dirname(getwd())
  if (file.exists(file.path(parent_dir, "cnp_dataset", "creditcard.csv"))) {
    return(parent_dir)
  }
  
  # Method 3: Try common project root paths
  possible_paths <- c(
    "C:/Users/monai/OneDrive - student.uni-halle.de/Desktop/Billie",
    file.path(dirname(getwd()), "Billie"),
    getwd()
  )
  
  for (path in possible_paths) {
    if (file.exists(file.path(path, "cnp_dataset", "creditcard.csv"))) {
      return(path)
    }
  }
  
  # If nothing found, use current directory and let user know
  return(getwd())
}

PROJECT_ROOT <- find_project_root()
cat("Project root detected:", PROJECT_ROOT, "\n")
cat("Current working directory:", getwd(), "\n\n")

# Set working directory to project root
if (PROJECT_ROOT != getwd()) {
  cat("Changing working directory to project root...\n")
  setwd(PROJECT_ROOT)
  cat("New working directory:", getwd(), "\n\n")
}

# =============================================================================
# CONFIGURATION
# =============================================================================

INPUT_FILE <- file.path(PROJECT_ROOT, "cnp_dataset", "creditcard.csv")
OUTPUT_FILE <- file.path(PROJECT_ROOT, "transactions_for_mysql.csv")
SQL_FILE <- file.path(PROJECT_ROOT, "mysql_setup_commands.sql")
DATABASE_NAME <- "fraud_detection_db"
MAX_ROWS <- NULL  # Set to 10000 for testing (faster import for testing)

# =============================================================================
# CHECK IF INPUT FILE EXISTS
# =============================================================================

if (!file.exists(INPUT_FILE)) {
  cat("❌ ERROR: Cannot find input file!\n")
  cat("   Looking for:", INPUT_FILE, "\n")
  cat("\nPlease either:\n")
  cat("1. Run this script from the Billie project folder, OR\n")
  cat("2. Update INPUT_FILE path in this script\n")
  cat("\nCurrent working directory:", getwd(), "\n")
  stop("Input file not found!")
}

cat("✅ Found input file:", INPUT_FILE, "\n\n")

# =============================================================================
# LOAD AND PROCESS DATA
# =============================================================================

cat("Loading data...\n")
df <- read_csv(INPUT_FILE, show_col_types = FALSE)
cat(sprintf("✅ Loaded %d rows, %d columns\n", nrow(df), ncol(df)))

if (!is.null(MAX_ROWS) && nrow(df) > MAX_ROWS) {
  cat(sprintf("⚠️  Limiting to first %d rows for testing...\n", MAX_ROWS))
  df <- df[1:MAX_ROWS, ]
}

# Create transactions dataframe
cat("\nProcessing data...\n")
transactions <- data.frame(transaction_id = 1:nrow(df))

# Generate customer IDs
n_customers <- min(5000, round(nrow(df) * 0.1))
customer_ids <- sample(1000:(1000 + n_customers - 1), nrow(df), replace = TRUE, 
                       prob = c(rep(2, 100), rep(1, n_customers - 100)))
transactions$customer_id <- customer_ids

# Convert Time to dates
start_date <- as.POSIXct("2013-09-01 00:00:00", tz = "UTC")
transactions$transaction_date <- format(start_date + df$Time, "%Y-%m-%d %H:%M:%S")

# Generate fraud probabilities
set.seed(42)
transactions$fraud_probability <- ifelse(
  df$Class == 1,
  round(runif(sum(df$Class == 1), 0.50, 0.99), 4),
  round(runif(sum(df$Class == 0), 0.01, 0.30), 4)
)

# Generate predictions
transactions$fraud_prediction <- ifelse(transactions$fraud_probability >= 0.5, 1, 0)

# Set labels and amount
transactions$actual_label <- as.integer(df$Class)
transactions$amount <- round(as.numeric(df$Amount), 2)

# Validate
transactions$fraud_probability <- pmax(0, pmin(1, transactions$fraud_probability))
transactions$fraud_prediction <- as.integer(ifelse(transactions$fraud_prediction >= 1, 1, 0))
transactions$actual_label <- as.integer(ifelse(transactions$actual_label >= 1, 1, 0))
transactions$amount <- pmax(0, transactions$amount)

# Save CSV
required_cols <- c("transaction_id", "customer_id", "transaction_date", 
                   "fraud_probability", "fraud_prediction", "actual_label", "amount")
transactions <- transactions[, required_cols]
write_csv(transactions, OUTPUT_FILE)
cat(sprintf("\n✅ Created: %s (%d transactions)\n", OUTPUT_FILE, nrow(transactions)))

# Generate SQL file
sql_commands <- paste0(
"-- MySQL Setup Commands\n",
"-- Generated by run_mysql_setup.R\n\n",
"CREATE DATABASE IF NOT EXISTS ", DATABASE_NAME, ";\n",
"USE ", DATABASE_NAME, ";\n\n",
"CREATE TABLE IF NOT EXISTS transactions (\n",
"    transaction_id INT PRIMARY KEY AUTO_INCREMENT,\n",
"    customer_id INT,\n",
"    transaction_date DATETIME,\n",
"    fraud_probability DECIMAL(5,4),\n",
"    fraud_prediction INT,\n",
"    actual_label INT,\n",
"    amount DECIMAL(10,2),\n",
"    INDEX idx_customer (customer_id),\n",
"    INDEX idx_date (transaction_date)\n",
");\n"
)

writeLines(sql_commands, SQL_FILE)
cat(sprintf("✅ Created: %s\n", SQL_FILE))

# Summary
cat("\n", "=", rep("=", 80), "\n", sep = "")
cat("SUMMARY\n")
cat("=", rep("=", 80), "\n\n", sep = "")
cat(sprintf("Transactions: %d\n", nrow(transactions)))
cat(sprintf("Fraud cases: %d (%.2f%%)\n", 
            sum(transactions$actual_label == 1),
            100 * mean(transactions$actual_label == 1)))
cat(sprintf("Predicted fraud: %d (%.2f%%)\n",
            sum(transactions$fraud_prediction == 1),
            100 * mean(transactions$fraud_prediction == 1)))
cat("\n✅ Setup complete! Files ready for MySQL import.\n")

