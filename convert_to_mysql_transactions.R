# =============================================================================
# Convert Existing CSV Data to MySQL Transactions Table Format
# This script helps convert your existing data to the format needed for MySQL
# =============================================================================

# Load required libraries
library(readr)
library(dplyr)
library(lubridate)

cat("=", rep("=", 60), "\n", sep = "")
cat("CSV to MySQL Transactions Converter\n")
cat("=", rep("=", 60), "\n\n", sep = "")

# =============================================================================
# Configuration
# =============================================================================

# Input file path (adjust to your CSV file)
INPUT_FILE <- "cnp_dataset/creditcard.csv"

# Output file path
OUTPUT_FILE <- "transactions_for_mysql.csv"

# =============================================================================
# Step 1: Load Your Existing Data
# =============================================================================

cat("Step 1: Loading data from:", INPUT_FILE, "\n")

if (!file.exists(INPUT_FILE)) {
  stop("Input file not found: ", INPUT_FILE, 
       "\nPlease update INPUT_FILE path in this script.")
}

# Read the CSV file
df <- read_csv(INPUT_FILE, show_col_types = FALSE)

cat(sprintf("Loaded %d rows, %d columns\n\n", nrow(df), ncol(df)))

# =============================================================================
# Step 2: Map Columns to MySQL Transactions Table
# =============================================================================

cat("Step 2: Mapping columns to MySQL transactions table format...\n")

# Create the transactions dataframe
transactions <- data.frame(
  transaction_id = if ("transaction_id" %in% names(df)) {
    df$transaction_id
  } else if ("Time" %in% names(df)) {
    # Use Time as transaction_id if no transaction_id exists
    1:nrow(df)
  } else {
    1:nrow(df)
  },
  
  customer_id = if ("customer_id" %in% names(df)) {
    df$customer_id
  } else {
    # Generate customer IDs if not present
    sample(1000:9999, nrow(df), replace = TRUE)
  },
  
  transaction_date = if ("transaction_date" %in% names(df)) {
    as.POSIXct(df$transaction_date)
  } else if ("Time" %in% names(df)) {
    # Convert Time (seconds) to datetime
    # Assuming Time is seconds since first transaction
    start_date <- as.POSIXct("2013-09-01 00:00:00", tz = "UTC")
    start_date + df$Time
  } else {
    # Use current date if no date available
    Sys.time()
  },
  
  fraud_probability = if ("fraud_probability" %in% names(df)) {
    df$fraud_probability
  } else if ("Class" %in% names(df)) {
    # If you have Class but no probability, create mock probabilities
    # Higher probability for fraud cases (Class = 1)
    ifelse(df$Class == 1, 
           runif(nrow(df), 0.5, 0.95),  # Fraud: 50-95% probability
           runif(nrow(df), 0.01, 0.2))  # Normal: 1-20% probability
  } else {
    # Generate random probabilities
    runif(nrow(df), 0.01, 0.3)
  },
  
  fraud_prediction = if ("fraud_prediction" %in% names(df)) {
    df$fraud_prediction
  } else if ("fraud_probability" %in% names(df)) {
    # Predict fraud if probability >= 0.5
    ifelse(df$fraud_probability >= 0.5, 1, 0)
  } else if ("Class" %in% names(df)) {
    # Use Class as prediction (if you have actual labels)
    df$Class
  } else {
    # Generate random predictions
    sample(0:1, nrow(df), replace = TRUE, prob = c(0.95, 0.05))
  },
  
  actual_label = if ("actual_label" %in% names(df)) {
    df$actual_label
  } else if ("Class" %in% names(df)) {
    # Use Class as actual_label
    df$Class
  } else {
    # Generate random labels (for testing)
    sample(0:1, nrow(df), replace = TRUE, prob = c(0.98, 0.02))
  },
  
  amount = if ("amount" %in% names(df)) {
    df$amount
  } else if ("Amount" %in% names(df)) {
    df$Amount
  } else {
    # Generate random amounts if not present
    round(runif(nrow(df), 1, 1000), 2)
  }
)

# =============================================================================
# Step 3: Clean and Format Data
# =============================================================================

cat("Step 3: Cleaning and formatting data...\n")

# Ensure fraud_probability is between 0 and 1
transactions$fraud_probability <- pmax(0, pmin(1, transactions$fraud_probability))

# Ensure fraud_prediction and actual_label are 0 or 1
transactions$fraud_prediction <- ifelse(transactions$fraud_prediction >= 1, 1, 0)
transactions$actual_label <- ifelse(transactions$actual_label >= 1, 1, 0)

# Format transaction_date as MySQL DATETIME format
transactions$transaction_date <- format(transactions$transaction_date, "%Y-%m-%d %H:%M:%S")

# Round fraud_probability to 4 decimal places
transactions$fraud_probability <- round(transactions$fraud_probability, 4)

# Round amount to 2 decimal places
transactions$amount <- round(transactions$amount, 2)

# =============================================================================
# Step 4: Save to CSV
# =============================================================================

cat("Step 4: Saving to:", OUTPUT_FILE, "\n")

write_csv(transactions, OUTPUT_FILE)

cat(sprintf("\n✅ Success! Created %s with %d transactions\n", OUTPUT_FILE, nrow(transactions)))
cat("\nColumn summary:\n")
cat(sprintf("  - transaction_id: %d to %d\n", 
            min(transactions$transaction_id), max(transactions$transaction_id)))
cat(sprintf("  - customer_id: %d unique customers\n", 
            length(unique(transactions$customer_id))))
cat(sprintf("  - transaction_date: %s to %s\n", 
            min(transactions$transaction_date), max(transactions$transaction_date)))
cat(sprintf("  - fraud_probability: %.4f to %.4f\n", 
            min(transactions$fraud_probability), max(transactions$fraud_probability)))
cat(sprintf("  - fraud_prediction: %d fraud, %d normal\n", 
            sum(transactions$fraud_prediction == 1), sum(transactions$fraud_prediction == 0)))
cat(sprintf("  - actual_label: %d fraud, %d normal\n", 
            sum(transactions$actual_label == 1), sum(transactions$actual_label == 0)))
cat(sprintf("  - amount: $%.2f to $%.2f\n", 
            min(transactions$amount), max(transactions$amount)))

cat("\n📋 Next Steps:\n")
cat("1. Review the generated CSV file:", OUTPUT_FILE, "\n")
cat("2. Import it into MySQL using MySQL Workbench Import Wizard\n")
cat("3. Or use the LOAD DATA command in MySQL\n")
cat("\n")



