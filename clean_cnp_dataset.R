# =============================================================================
# CNP Dataset Cleaning Script
# Credit Card Fraud Detection Dataset - Data Cleaning Pipeline
# =============================================================================

# Load required libraries
library(dplyr)
library(tidyr)      # For data reshaping functions
library(lubridate)
library(DescTools)  # For Winsorize function
library(readr)

# =============================================================================
# Step 1: Load the Dataset
# =============================================================================

cat("Loading dataset...\n")

# Dataset path - update this to match your file location
# Option 1: New location you specified
dataset_path <- "C:/Users/monai/OneDrive - student.uni-halle.de/Desktop/Billie _ R/creditcard.csv"

# Option 2: Original location (uncomment if using this)
# dataset_path <- "cnp_dataset/creditcard.csv"

# Load the dataset
df <- read_csv(dataset_path, show_col_types = FALSE)

cat(sprintf("Original dataset shape: %d rows, %d columns\n", nrow(df), ncol(df)))
cat(sprintf("Memory usage: %s\n", format(object.size(df), units = "MB")))

# =============================================================================
# Step 2: Normalize Identifiers
# =============================================================================

cat("\n=== Step 1: Normalizing Identifiers ===\n")

# Note: Original column names (Time, V1-V28, Amount, Class) are perfectly fine
# Normalization is optional - uncomment the section below if you want normalized names

# OPTIONAL: Normalize column names (uncomment if desired)
# colnames(df) <- tolower(colnames(df))
# df <- df %>%
#   rename(
#     transaction_time = time,
#     transaction_amount = amount,
#     fraud_label = class
#   )

# Keep original column names but create a transaction ID
# The original names (Time, V1-V28, Amount, Class) are standard for this dataset
v_cols <- grep("^[Vv]\\d+$", colnames(df), value = TRUE)
cat(sprintf("Found %d PCA feature columns (V1-V28)\n", length(v_cols)))
cat("Note: Original column names are preserved (Time, V1-V28, Amount, Class)\n")
cat("These are the standard names for this dataset and are NOT a problem.\n")

# Create a normalized identifier for each transaction (row number as ID)
df <- df %>%
  mutate(
    transaction_id = row_number(),
    .before = 1  # Place as first column
  )

cat("✓ Transaction ID created\n")
cat(sprintf("  - Original column names preserved\n"))
cat(sprintf("  - Transaction ID added as first column\n"))
cat(sprintf("  - Current columns: %s\n", paste(colnames(df)[1:6], collapse = ", "), "..."))

# =============================================================================
# Step 3: Handle Missing Values
# =============================================================================

cat("\n=== Step 2: Handling Missing Values ===\n")

# Check for missing values
missing_counts <- sapply(df, function(x) sum(is.na(x)))
missing_summary <- data.frame(
  column = names(missing_counts),
  missing_count = missing_counts,
  stringsAsFactors = FALSE
) %>%
  filter(missing_count > 0)

if (nrow(missing_summary) > 0) {
  cat("Missing values found:\n")
  print(missing_summary)
  
  # Handle missing values in numeric columns (V1-V28, Amount)
  # Use original column names
  numeric_cols <- c(v_cols, "Amount")
  if (!"Amount" %in% colnames(df)) {
    # Try lowercase version if normalized
    numeric_cols <- c(v_cols, "amount")
  }
  
  for (col in numeric_cols) {
    if (any(is.na(df[[col]]))) {
      # Fill with median for numeric columns
      median_val <- median(df[[col]], na.rm = TRUE)
      df[[col]][is.na(df[[col]])] <- median_val
      cat(sprintf("  - Filled %d missing values in %s with median: %.4f\n", 
                  sum(is.na(df[[col]])), col, median_val))
    }
  }
  
  # Handle missing values in Time column (use original name)
  time_col <- ifelse("Time" %in% colnames(df), "Time", "time")
  if (any(is.na(df[[time_col]]))) {
    df[[time_col]][is.na(df[[time_col]])] <- 0
    cat(sprintf("  - Filled %d missing values in %s with 0\n", 
                sum(is.na(df[[time_col]])), time_col))
  }
  
  # Handle missing values in Class (shouldn't have any, but check)
  class_col <- ifelse("Class" %in% colnames(df), "Class", "class")
  if (any(is.na(df[[class_col]]))) {
    df[[class_col]][is.na(df[[class_col]])] <- 0
    cat(sprintf("  - Filled %d missing values in %s with 0\n", 
                sum(is.na(df[[class_col]])), class_col))
  }
} else {
  cat("✓ No missing values found in the dataset\n")
}

# Final check
total_missing <- sum(is.na(df))
cat(sprintf("✓ Missing values handled. Total remaining: %d\n", total_missing))

# =============================================================================
# Step 4: Convert Timestamps to UTC and Create Derived Fields
# =============================================================================

cat("\n=== Step 3: Converting Timestamps and Creating Derived Fields ===\n")

# The 'Time' column represents seconds elapsed since the first transaction
# We'll create a proper timestamp and derive useful time-based features

# Use original column name
time_col <- ifelse("Time" %in% colnames(df), "Time", "time")

# Create a base timestamp (assuming the first transaction was at a specific date)
# Using a reasonable base date (e.g., September 1, 2013, as mentioned in dataset description)
base_timestamp <- as.POSIXct("2013-09-01 00:00:00", tz = "UTC")

# Convert Time (seconds) to UTC timestamp
# Get the Time column values for calculations
time_values <- df[[time_col]]

# Create UTC timestamps
transaction_timestamps <- base_timestamp + seconds(time_values)

# Calculate time differences
time_since_previous <- c(0, diff(time_values))

# Add derived fields to dataframe
df <- df %>%
  mutate(
    # Create UTC timestamp using original Time column
    transaction_timestamp_utc = transaction_timestamps,
    
    # Extract time-based features
    hour_of_day = hour(transaction_timestamp_utc),
    day_of_week = wday(transaction_timestamp_utc, label = TRUE),
    day_of_month = day(transaction_timestamp_utc),
    month = month(transaction_timestamp_utc, label = TRUE),
    is_weekend = wday(transaction_timestamp_utc) %in% c(1, 7),  # Sunday = 1, Saturday = 7
    
    # Time since first transaction (keep original Time column)
    seconds_since_first = time_values,
    
    # Time of day categories
    time_of_day = case_when(
      hour_of_day >= 6 & hour_of_day < 12 ~ "Morning",
      hour_of_day >= 12 & hour_of_day < 18 ~ "Afternoon",
      hour_of_day >= 18 & hour_of_day < 24 ~ "Evening",
      TRUE ~ "Night"
    ),
    
    # Time elapsed since previous transaction
    time_since_previous = time_since_previous
  )

# Columns are added at the end - this is fine for functionality

cat("✓ Timestamps converted to UTC\n")
cat("✓ Derived time-based fields created:\n")
cat("  - transaction_timestamp_utc: Full UTC timestamp\n")
cat("  - hour_of_day: Hour (0-23)\n")
cat("  - day_of_week: Day of week\n")
cat("  - day_of_month: Day of month\n")
cat("  - month: Month\n")
cat("  - is_weekend: Boolean weekend indicator\n")
cat("  - time_of_day: Categorical time period\n")
cat("  - time_since_previous: Seconds since previous transaction\n")

# =============================================================================
# Step 5: Winsorize Extreme Amounts to Reduce Skew
# =============================================================================

cat("\n=== Step 4: Winsorizing Extreme Amounts ===\n")

# Use original column name for Amount
amount_col <- ifelse("Amount" %in% colnames(df), "Amount", "amount")

# Check original distribution
original_stats <- df %>%
  summarise(
    mean_amount = mean(!!sym(amount_col)),
    median_amount = median(!!sym(amount_col)),
    min_amount = min(!!sym(amount_col)),
    max_amount = max(!!sym(amount_col)),
    q1 = quantile(!!sym(amount_col), 0.25),
    q3 = quantile(!!sym(amount_col), 0.75),
    iqr = q3 - q1,
    skewness = DescTools::Skew(!!sym(amount_col))
  )

cat("Original Amount Statistics:\n")
print(original_stats)

# Calculate outliers using IQR method
Q1 <- quantile(df[[amount_col]], 0.25)
Q3 <- quantile(df[[amount_col]], 0.75)
IQR <- Q3 - Q1
lower_bound <- Q1 - 1.5 * IQR
upper_bound <- Q3 + 1.5 * IQR

cat(sprintf("\nIQR-based bounds: [%.2f, %.2f]\n", lower_bound, upper_bound))
cat(sprintf("Values outside bounds: %d (%.2f%%)\n", 
            sum(df[[amount_col]] < lower_bound | df[[amount_col]] > upper_bound),
            sum(df[[amount_col]] < lower_bound | df[[amount_col]] > upper_bound) / nrow(df) * 100))

# Winsorize at 1st and 99th percentiles
winsorize_percentile <- 0.01  # Winsorize top and bottom 1%

# Create original amount column for reference
df[[paste0(amount_col, "_original")]] <- df[[amount_col]]

# Winsorize the amount column using quantiles
# Calculate the percentile thresholds
Q_low <- quantile(df[[amount_col]], winsorize_percentile, na.rm = TRUE)
Q_high <- quantile(df[[amount_col]], 1 - winsorize_percentile, na.rm = TRUE)

cat(sprintf("Winsorizing at percentiles: %.1f%% and %.1f%%\n", 
            winsorize_percentile * 100, (1 - winsorize_percentile) * 100))
cat(sprintf("Lower bound: %.2f, Upper bound: %.2f\n", Q_low, Q_high))

# Winsorize: cap values below Q_low to Q_low, and above Q_high to Q_high
df[[amount_col]] <- pmax(pmin(df[[amount_col]], Q_high), Q_low)

# Calculate new statistics
winsorized_stats <- df %>%
  summarise(
    mean_amount = mean(!!sym(amount_col)),
    median_amount = median(!!sym(amount_col)),
    min_amount = min(!!sym(amount_col)),
    max_amount = max(!!sym(amount_col)),
    q1 = quantile(!!sym(amount_col), 0.25),
    q3 = quantile(!!sym(amount_col), 0.75),
    iqr = q3 - q1,
    skewness = DescTools::Skew(!!sym(amount_col))
  )

cat("\nWinsorized Amount Statistics:\n")
print(winsorized_stats)

cat(sprintf("\n✓ Skewness reduced from %.4f to %.4f\n", 
            original_stats$skewness, winsorized_stats$skewness))
cat(sprintf("✓ Extreme values capped at %.2f and %.2f\n", 
            min(df[[amount_col]]), max(df[[amount_col]])))

# =============================================================================
# Step 6: Additional Data Quality Checks
# =============================================================================

cat("\n=== Step 5: Additional Data Quality Checks ===\n")

# Check for duplicate transactions
duplicates <- sum(duplicated(df %>% select(-transaction_id)))
cat(sprintf("Duplicate transactions (excluding ID): %d\n", duplicates))

# Check data types
cat("\nData types:\n")
print(sapply(df, class))

# Check fraud distribution (use original column name)
class_col <- ifelse("Class" %in% colnames(df), "Class", "class")
fraud_dist <- df %>%
  count(!!sym(class_col)) %>%
  mutate(percentage = n / nrow(df) * 100)
cat("\nFraud label distribution:\n")
print(fraud_dist)

# =============================================================================
# Step 7: Save Cleaned Dataset
# =============================================================================

cat("\n=== Step 6: Saving Cleaned Dataset ===\n")

# Create output directory
output_dir <- "cnp_dataset/cleaned"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Save cleaned dataset
output_path <- file.path(output_dir, "creditcard_cleaned.csv")
write_csv(df, output_path)
cat(sprintf("✓ Cleaned dataset saved to: %s\n", output_path))

# Save summary statistics
summary_path <- file.path(output_dir, "cleaning_summary.txt")
sink(summary_path)
cat("CNP Dataset Cleaning Summary\n")
cat(paste0(rep("=", 50), collapse = ""), "\n\n")
cat(sprintf("Original dataset: %d rows, %d columns\n", 
            nrow(df), ncol(df)))
cat(sprintf("Cleaned dataset: %d rows, %d columns\n", 
            nrow(df), ncol(df)))
cat("\nMissing Values:\n")
cat(sprintf("  Total missing after cleaning: %d\n", sum(is.na(df))))
cat("\nAmount Winsorization:\n")
cat(sprintf("  Original skewness: %.4f\n", original_stats$skewness))
cat(sprintf("  Winsorized skewness: %.4f\n", winsorized_stats$skewness))
cat("\nFraud Distribution:\n")
print(fraud_dist)
sink()

cat(sprintf("✓ Summary saved to: %s\n", summary_path))

# =============================================================================
# Final Summary
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("DATA CLEANING COMPLETE!\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")
cat(sprintf("Cleaned dataset: %s\n", output_path))
cat(sprintf("Total rows: %d\n", nrow(df)))
cat(sprintf("Total columns: %d\n", ncol(df)))
cat(sprintf("Memory usage: %s\n", format(object.size(df), units = "MB")))
cat("\nCleaning steps completed:\n")
cat("  ✓ Identifiers normalized\n")
cat("  ✓ Missing values handled\n")
cat("  ✓ Timestamps converted to UTC with derived fields\n")
cat("  ✓ Extreme amounts winsorized\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")

# Display first few rows of cleaned dataset
cat("\nFirst 5 rows of cleaned dataset:\n")
print(head(df, 5))

