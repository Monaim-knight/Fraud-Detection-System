# =============================================================================
# Prepare MySQL Dataset from Existing CNP Credit Card Data
# Converts creditcard.csv to MySQL transactions table format
# =============================================================================

# Load required libraries
library(readr)
library(dplyr)
library(lubridate)

cat("=", rep("=", 70), "\n", sep = "")
cat("MySQL Dataset Preparation from CNP Credit Card Data\n")
cat("=", rep("=", 70), "\n\n", sep = "")

# =============================================================================
# Configuration
# =============================================================================

# Input file path
INPUT_FILE <- "cnp_dataset/creditcard.csv"

# Output file path
OUTPUT_FILE <- "transactions_for_mysql.csv"

# Number of rows to process (set to NULL to process all)
# Use a smaller number for testing (e.g., 10000)
MAX_ROWS <- NULL  # Set to NULL to process all rows, or a number like 10000 for testing

# =============================================================================
# Step 1: Load Your Existing Data
# =============================================================================

cat("Step 1: Loading data from:", INPUT_FILE, "\n")

if (!file.exists(INPUT_FILE)) {
  stop("Input file not found: ", INPUT_FILE, 
       "\nPlease make sure the file exists in the cnp_dataset folder.")
}

# Read the CSV file
cat("Reading CSV file (this may take a moment for large files)...\n")
df <- read_csv(INPUT_FILE, show_col_types = FALSE)

cat(sprintf("Loaded %d rows, %d columns\n", nrow(df), ncol(df)))

# Limit rows if specified (for testing)
if (!is.null(MAX_ROWS) && nrow(df) > MAX_ROWS) {
  cat(sprintf("Limiting to first %d rows for testing...\n", MAX_ROWS))
  df <- df[1:MAX_ROWS, ]
}

cat("\n")

# =============================================================================
# Step 2: Create Transaction IDs
# =============================================================================

cat("Step 2: Creating transaction IDs...\n")

# Create sequential transaction IDs starting from 1
transactions <- data.frame(
  transaction_id = 1:nrow(df)
)

# =============================================================================
# Step 3: Generate Customer IDs
# =============================================================================

cat("Step 3: Generating customer IDs...\n")

# Generate realistic customer IDs
# Assume each customer makes multiple transactions
# Create a distribution where some customers are more active
n_customers <- min(5000, round(nrow(df) * 0.1))  # ~10% of transactions are unique customers
customer_ids <- sample(1000:(1000 + n_customers - 1), nrow(df), replace = TRUE, 
                       prob = c(rep(2, 100), rep(1, n_customers - 100)))  # Some customers more active

transactions$customer_id <- customer_ids

cat(sprintf("  Generated %d unique customer IDs\n", length(unique(customer_ids))))

# =============================================================================
# Step 4: Convert Time to Transaction Date
# =============================================================================

cat("Step 4: Converting Time to transaction dates...\n")

# Time is in seconds since first transaction
# Original dataset is from September 2013
start_date <- as.POSIXct("2013-09-01 00:00:00", tz = "UTC")

# Convert Time (seconds) to datetime
transactions$transaction_date <- start_date + df$Time

# Format as MySQL DATETIME format
transactions$transaction_date <- format(transactions$transaction_date, "%Y-%m-%d %H:%M:%S")

cat(sprintf("  Date range: %s to %s\n", 
            min(transactions$transaction_date), 
            max(transactions$transaction_date)))

# =============================================================================
# Step 5: Generate Fraud Probability
# =============================================================================

cat("Step 5: Generating fraud probabilities...\n")

# Create realistic fraud probabilities based on Class
# Fraud cases (Class = 1) should have higher probabilities
# Normal cases (Class = 0) should have lower probabilities

set.seed(42)  # For reproducibility

transactions$fraud_probability <- ifelse(
  df$Class == 1,
  # For fraud cases: higher probabilities (0.5 to 0.99)
  round(runif(sum(df$Class == 1), 0.50, 0.99), 4),
  # For normal cases: lower probabilities (0.01 to 0.30)
  round(runif(sum(df$Class == 0), 0.01, 0.30), 4)
)

cat(sprintf("  Fraud probability range: %.4f to %.4f\n", 
            min(transactions$fraud_probability), 
            max(transactions$fraud_probability)))
cat(sprintf("  Average fraud probability for fraud cases: %.4f\n", 
            mean(transactions$fraud_probability[df$Class == 1])))
cat(sprintf("  Average fraud probability for normal cases: %.4f\n", 
            mean(transactions$fraud_probability[df$Class == 0])))

# =============================================================================
# Step 6: Generate Fraud Predictions
# =============================================================================

cat("Step 6: Generating fraud predictions...\n")

# Predict fraud if probability >= 0.5 (standard threshold)
# You can adjust this threshold (0.17 for review queue, 0.5 for auto-block)
transactions$fraud_prediction <- ifelse(transactions$fraud_probability >= 0.5, 1, 0)

cat(sprintf("  Predictions: %d fraud, %d normal\n", 
            sum(transactions$fraud_prediction == 1), 
            sum(transactions$fraud_prediction == 0)))

# =============================================================================
# Step 7: Set Actual Labels
# =============================================================================

cat("Step 7: Setting actual labels...\n")

# Use Class column as actual_label
transactions$actual_label <- as.integer(df$Class)

cat(sprintf("  Actual labels: %d fraud, %d normal\n", 
            sum(transactions$actual_label == 1), 
            sum(transactions$actual_label == 0)))

# =============================================================================
# Step 8: Set Amount
# =============================================================================

cat("Step 8: Setting transaction amounts...\n")

# Use Amount column from original data
transactions$amount <- round(as.numeric(df$Amount), 2)

cat(sprintf("  Amount range: $%.2f to $%.2f\n", 
            min(transactions$amount), 
            max(transactions$amount)))
cat(sprintf("  Average amount: $%.2f\n", mean(transactions$amount)))

# =============================================================================
# Step 9: Final Data Validation
# =============================================================================

cat("\nStep 9: Validating data...\n")

# Ensure all required columns exist and are correct format
required_cols <- c("transaction_id", "customer_id", "transaction_date", 
                   "fraud_probability", "fraud_prediction", "actual_label", "amount")

if (!all(required_cols %in% names(transactions))) {
  stop("Missing required columns!")
}

# Ensure fraud_probability is between 0 and 1
transactions$fraud_probability <- pmax(0, pmin(1, transactions$fraud_probability))

# Ensure fraud_prediction and actual_label are 0 or 1
transactions$fraud_prediction <- as.integer(ifelse(transactions$fraud_prediction >= 1, 1, 0))
transactions$actual_label <- as.integer(ifelse(transactions$actual_label >= 1, 1, 0))

# Ensure no negative amounts
transactions$amount <- pmax(0, transactions$amount)

cat("  ✅ All validations passed!\n")

# =============================================================================
# Step 10: Save to CSV
# =============================================================================

cat("\nStep 10: Saving to:", OUTPUT_FILE, "\n")

# Reorder columns to match MySQL table structure
transactions <- transactions[, required_cols]

# Write CSV file
write_csv(transactions, OUTPUT_FILE)

cat(sprintf("\n✅ SUCCESS! Created %s\n", OUTPUT_FILE))
cat(sprintf("   Total transactions: %d\n", nrow(transactions)))
cat("\n")

# =============================================================================
# Summary Statistics
# =============================================================================

cat("=", rep("=", 70), "\n", sep = "")
cat("DATASET SUMMARY\n")
cat("=", rep("=", 70), "\n\n", sep = "")

cat("Column Information:\n")
cat(sprintf("  - transaction_id: %d to %d\n", 
            min(transactions$transaction_id), 
            max(transactions$transaction_id)))
cat(sprintf("  - customer_id: %d unique customers (range: %d to %d)\n", 
            length(unique(transactions$customer_id)),
            min(transactions$customer_id),
            max(transactions$customer_id)))
cat(sprintf("  - transaction_date: %s to %s\n", 
            min(transactions$transaction_date), 
            max(transactions$transaction_date)))
cat(sprintf("  - fraud_probability: %.4f to %.4f (mean: %.4f)\n", 
            min(transactions$fraud_probability), 
            max(transactions$fraud_probability),
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
cat(sprintf("  - amount: $%.2f to $%.2f (mean: $%.2f, median: $%.2f)\n", 
            min(transactions$amount), 
            max(transactions$amount),
            mean(transactions$amount),
            median(transactions$amount)))

# Confusion matrix
cat("\nConfusion Matrix (Prediction vs Actual):\n")
conf_matrix <- table(Prediction = transactions$fraud_prediction, 
                      Actual = transactions$actual_label)
print(conf_matrix)

cat("\n")

# =============================================================================
# Next Steps
# =============================================================================

cat("=", rep("=", 70), "\n", sep = "")
cat("NEXT STEPS\n")
cat("=", rep("=", 70), "\n\n", sep = "")

cat("1. ✅ CSV file created: ", OUTPUT_FILE, "\n")
cat("2. 📥 Import into MySQL:\n")
cat("   a. Open MySQL Workbench\n")
cat("   b. Right-click on 'transactions' table → 'Table Data Import Wizard'\n")
cat("   c. Select: ", OUTPUT_FILE, "\n")
cat("   d. Map columns and import\n")
cat("3. 🔍 Verify import:\n")
cat("   Run: SELECT COUNT(*) FROM transactions;\n")
cat("4. 📊 Run view creation script:\n")
cat("   Execute: prepare_tableau_data_mysql.sql\n")
cat("\n")

cat("✅ Dataset preparation complete!\n")
cat("\n")



