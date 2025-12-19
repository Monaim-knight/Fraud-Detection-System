# R Data Cleaning Script for CNP Dataset

This script performs comprehensive data cleaning on the Credit Card Fraud Detection (CNP) dataset.

## Prerequisites

### Install Required R Packages

Run the following in R or RStudio:

```r
install.packages(c("dplyr", "tidyr", "lubridate", "DescTools", "readr"))
```

Or install individually:

```r
install.packages("dplyr")      # Data manipulation
install.packages("tidyr")      # Data reshaping
install.packages("lubridate")  # Date/time handling
install.packages("DescTools")  # Winsorize function
install.packages("readr")      # Fast CSV reading
```

## Usage

1. **Make sure the dataset is in the correct location:**
   - The script expects: `cnp_dataset/creditcard.csv`

2. **Run the cleaning script:**
   ```r
   source("clean_cnp_dataset.R")
   ```

   Or in RStudio, open the script and click "Source" or press `Ctrl+Shift+S`.

## Cleaning Steps Performed

### 1. Normalize Identifiers
- Converts all column names to lowercase
- Renames columns to standardized format:
  - `Time` → `transaction_time`
  - `Amount` → `transaction_amount`
  - `Class` → `fraud_label`
- Creates a unique `transaction_id` for each row

### 2. Handle Missing Values
- Checks for missing values in all columns
- Fills missing numeric values (V1-V28, Amount) with median
- Fills missing Time values with 0
- Fills missing Class values with 0 (non-fraud)

### 3. Convert Timestamps to UTC and Create Derived Fields
- Converts `transaction_time` (seconds) to UTC timestamps
- Creates base timestamp: September 1, 2013 00:00:00 UTC
- Derives time-based features:
  - `transaction_timestamp_utc`: Full UTC timestamp
  - `hour_of_day`: Hour (0-23)
  - `day_of_week`: Day of week (Mon-Sun)
  - `day_of_month`: Day of month (1-31)
  - `month`: Month name
  - `is_weekend`: Boolean (TRUE/FALSE)
  - `time_of_day`: Categorical (Morning/Afternoon/Evening/Night)
  - `time_since_previous`: Seconds since previous transaction

### 4. Winsorize Extreme Amounts to Reduce Skew
- Calculates original skewness of transaction amounts
- Winsorizes at 1st and 99th percentiles (caps extreme values)
- Preserves original amounts in `transaction_amount_original` column
- Reports reduction in skewness

### 5. Additional Data Quality Checks
- Checks for duplicate transactions
- Verifies data types
- Reports fraud label distribution

## Output

The script creates:

1. **Cleaned Dataset**: `cnp_dataset/cleaned/creditcard_cleaned.csv`
   - All cleaning steps applied
   - Ready for analysis or modeling

2. **Cleaning Summary**: `cnp_dataset/cleaned/cleaning_summary.txt`
   - Summary statistics
   - Missing value counts
   - Winsorization results
   - Fraud distribution

## Output Columns

The cleaned dataset includes:

**Original Columns:**
- `transaction_id`: Unique identifier
- `transaction_time`: Seconds since first transaction
- `v1` through `v28`: PCA-transformed features
- `transaction_amount`: Winsorized transaction amount
- `fraud_label`: 0 (normal) or 1 (fraud)

**New Derived Columns:**
- `transaction_timestamp_utc`: UTC timestamp
- `hour_of_day`: Hour (0-23)
- `day_of_week`: Day name
- `day_of_month`: Day number
- `month`: Month name
- `is_weekend`: Boolean
- `time_of_day`: Categorical period
- `time_since_previous`: Seconds since previous transaction
- `transaction_amount_original`: Original amount (before winsorization)

## Example Output

```
=== Step 1: Normalizing Identifiers ===
✓ Identifiers normalized

=== Step 2: Handling Missing Values ===
✓ No missing values found in the dataset

=== Step 3: Converting Timestamps and Creating Derived Fields ===
✓ Timestamps converted to UTC
✓ Derived time-based fields created

=== Step 4: Winsorizing Extreme Amounts ===
✓ Skewness reduced from 16.9776 to 2.3456
✓ Extreme values capped at 0.00 and 25691.16

=== Step 5: Additional Data Quality Checks ===
Duplicate transactions: 0

=== Step 6: Saving Cleaned Dataset ===
✓ Cleaned dataset saved to: cnp_dataset/cleaned/creditcard_cleaned.csv
```

## Notes

- The dataset is large (284,807 rows), so processing may take a few minutes
- Memory usage is reported during execution
- All original data is preserved (original amounts saved separately)
- The script is idempotent - can be run multiple times safely

## Troubleshooting

**Error: "package 'X' is not installed"**
- Install missing packages using `install.packages("X")`

**Error: "cannot open file"**
- Check that `cnp_dataset/creditcard.csv` exists
- Verify you're running the script from the correct directory

**Memory issues:**
- The dataset is ~150MB in memory
- Close other applications if you encounter memory errors
- Consider processing in chunks for very large datasets






