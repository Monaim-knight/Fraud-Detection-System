# CNP Dataset Cleaning Report
## Credit Card Fraud Detection Dataset - Data Cleaning Pipeline

**Date:** [Add Date]  
**Author:** [Your Name]

---

## Executive Summary

This report documents the step-by-step data cleaning process for the Credit Card Fraud Detection (CNP) dataset.

**Dataset Information:**
- **Source**: Kaggle - Machine Learning Group - ULB
- **Original Records**: 284,807
- **Features**: 31 (Time, V1-V28, Amount, Class)
- **Target Variable**: Class (0 = Normal, 1 = Fraud)

---

## Step 1: Data Loading

### Results:
- ✓ Dataset loaded successfully
- Original dataset shape: 284,807 rows, 31 columns
- Column names: Time, V1-V28, Amount, Class

---

## Step 2: Normalize Identifiers

### Action Taken:
- Original column names preserved (Time, V1-V28, Amount, Class)
- Transaction ID created for each row

### Results:
- ✓ Identifiers normalized
- ✓ Transaction ID added as first column
- ✓ Original column names preserved

---

## Step 3: Handle Missing Values

### Action Taken:
- Checked for missing values across all columns
- Applied appropriate imputation strategies

### Results:
```
✓ No missing values found in the dataset
✓ Missing values handled. Total remaining: 0
```

### Summary:
- **Total Missing Values**: 0
- **Columns Checked**: All 31 columns
- **Imputation Strategy**: Not required (no missing values)

### Interpretation:
The dataset is complete with no missing values, which is excellent for data quality. No imputation was necessary.

### Code Executed:
```r
# Check for missing values
missing_counts <- sapply(df, function(x) sum(is.na(x)))
missing_summary <- data.frame(
  column = names(missing_counts),
  missing_count = missing_counts,
  stringsAsFactors = FALSE
) %>%
  filter(missing_count > 0)

# Final check
total_missing <- sum(is.na(df))
cat(sprintf("✓ Missing values handled. Total remaining: %d\n", total_missing))
```

---

## Step 4: Convert Timestamps to UTC and Create Derived Fields

### Action Taken:
- Converted Time column (seconds) to UTC timestamps
- Created base timestamp: September 1, 2013 00:00:00 UTC
- Derived time-based features

### Results:
```
✓ Timestamps converted to UTC
✓ Derived time-based fields created:
  - transaction_timestamp_utc: Full UTC timestamp
  - hour_of_day: Hour (0-23)
  - day_of_week: Day of week
  - day_of_month: Day of month
  - month: Month
  - is_weekend: Boolean weekend indicator
  - time_of_day: Categorical time period
  - time_since_previous: Seconds since previous transaction
```

### Derived Fields Created:
- ✓ `transaction_timestamp_utc`: Full UTC timestamp
- ✓ `hour_of_day`: Hour (0-23)
- ✓ `day_of_week`: Day of week (Mon-Sun)
- ✓ `day_of_month`: Day of month (1-31)
- ✓ `month`: Month name
- ✓ `is_weekend`: Boolean (TRUE/FALSE)
- ✓ `time_of_day`: Categorical (Morning/Afternoon/Evening/Night)
- ✓ `time_since_previous`: Seconds since previous transaction

### Summary:
- **Base Timestamp**: September 1, 2013 00:00:00 UTC
- **New Fields Created**: 8 time-based features
- **Total Columns After Step**: 39 (31 original + 1 transaction_id + 8 derived fields - 1 original Time kept)

### Interpretation:
All timestamps have been successfully converted to UTC format, and comprehensive time-based features have been derived. These features will be valuable for:
- Time-based pattern analysis
- Fraud detection models (fraud may have temporal patterns)
- Exploratory data analysis
- Feature engineering for machine learning

### Status: ✓ **COMPLETED**

---

## Step 5: Winsorize Extreme Amounts to Reduce Skew

### Action Taken:
- Analyzed original Amount distribution
- Calculated skewness
- Applied winsorization at 1st and 99th percentiles

### Results:
```
IQR-based bounds: [-101.75, 184.51]
Values outside bounds: 31,904 (11.20%)
Winsorizing at percentiles: 1.0% and 99.0%
Lower bound: 0.12, Upper bound: 1017.97
✓ Skewness reduced from 16.9775 to 3.8093
✓ Extreme values capped at 0.12 and 1017.97
```

### Original Statistics:
*These statistics are from the dataset BEFORE winsorization.*

- **Mean Amount**: 88.30
- **Median Amount**: 22.00
- **Min Amount**: 0.00
- **Max Amount**: 25,691.00
- **Q1 (25th percentile)**: 5.60
- **Q3 (75th percentile)**: 77.20
- **IQR**: 71.60
- **Skewness**: **17.0** (highly right-skewed)

**Key Observations:**
- The original distribution is **extremely right-skewed** (skewness = 17.0)
- **Maximum amount** of 25,691 is significantly higher than the median of 22
- **Mean (88.3)** is much higher than **median (22)**, indicating heavy right tail
- This extreme skewness would negatively impact many statistical methods and machine learning algorithms

### Winsorization Details:
- **Method**: Percentile-based winsorization
- **Percentiles**: 1st and 99th (1.0% and 99.0%)
- **Lower Bound**: 0.12
- **Upper Bound**: 1,017.97
- **Values Capped**: All values below 0.12 set to 0.12, all values above 1,017.97 set to 1,017.97

### IQR Analysis:
- **IQR-based bounds**: [-101.75, 184.51]
- **Values outside IQR bounds**: 31,904 transactions (11.20% of dataset)
- This indicates significant outliers in the Amount distribution

### Winsorized Statistics:
- **Mean Amount**: 80.2
- **Median Amount**: 22.0
- **Min Amount**: 0.12 (capped)
- **Max Amount**: 1,018 (capped)
- **Q1 (25th percentile)**: 5.6
- **Q3 (75th percentile)**: 77.2
- **IQR**: 71.6
- **Skewness**: 3.8093

### Skewness Reduction:
- **Original Skewness**: 17.0 (highly right-skewed)
- **Winsorized Skewness**: 3.8093
- **Reduction**: 13.19 (77.6% reduction)
- **Improvement**: Significant reduction in skewness, making the distribution more suitable for statistical analysis and machine learning

### Before/After Comparison:

| Statistic | Original | Winsorized | Change |
|-----------|----------|------------|--------|
| Mean | 88.30 | 80.20 | -9.2% |
| Median | 22.00 | 22.00 | No change |
| Min | 0.00 | 0.12 | Capped at 1st percentile |
| Max | 25,691.00 | 1,017.97 | Capped at 99th percentile |
| Q1 | 5.60 | 5.60 | No change |
| Q3 | 77.20 | 77.20 | No change |
| IQR | 71.60 | 71.60 | No change |
| Skewness | 17.0 | 3.81 | **-77.6%** |

### Interpretation:
The winsorization process successfully:
1. **Reduced extreme skewness** from 17.0 to 3.81 (77.6% reduction)
2. **Capped extreme outliers**: Maximum amount reduced from 25,691 to 1,018 (96% reduction in max value)
3. **Preserved central tendency**: Median (22.0) and quartiles (Q1=5.6, Q3=77.2) unchanged
4. **Maintained data integrity**: Original values preserved in `Amount_original` column
5. **Improved distribution** making it more suitable for:
   - Statistical analysis
   - Machine learning algorithms
   - Feature scaling and normalization
   - Outlier detection methods

**Impact of Winsorization:**
- The original maximum amount of **25,691** was an extreme outlier
- By capping at the 99th percentile (1,017.97), we removed the most extreme 1% of values
- The mean decreased slightly from 88.3 to 80.2, but the median remained stable at 22.0
- The winsorized Amount column is now more normally distributed while still capturing the variability in transaction amounts

### Status: ✓ **COMPLETED**

---

## Step 6: Additional Data Quality Checks

### Checks Performed:
- Duplicate transactions
- Data types verification
- Fraud label distribution

### Results:
```
Duplicate transactions (excluding ID): 896
```

### Duplicate Transactions:
- **Total Duplicates**: 896 transactions
- **Percentage**: 0.31% of the dataset
- **Note**: Duplicates are identified by comparing all columns except transaction_id
- **Interpretation**: A small number of duplicate transactions exist, which could represent:
  - Legitimate duplicate transactions (same transaction processed twice)
  - Data entry issues
  - System processing duplicates
  - These should be investigated further if needed for modeling

### Data Types Summary:

**Numeric Variables:**
- `transaction_id`: integer
- `Time`, `V1-V28`, `Amount`, `Class`, `seconds_since_first`, `time_since_previous`, `Amount_original`: numeric

**Date/Time Variables:**
- `transaction_timestamp_utc`: POSIXct/POSIXt (datetime)

**Categorical Variables:**
- `day_of_week`: ordered factor (Mon-Sun)
- `month`: ordered factor (month names)
- `time_of_day`: character (Morning/Afternoon/Evening/Night)

**Boolean Variables:**
- `is_weekend`: logical (TRUE/FALSE)
- `hour_of_day`, `day_of_month`: integer

**Data Type Assessment:**
- ✓ All numeric features are properly typed as numeric
- ✓ Timestamps correctly formatted as POSIXct
- ✓ Categorical variables appropriately typed as factors
- ✓ No type conversion issues detected

### Fraud Distribution:

| Class | Count | Percentage |
|-------|-------|------------|
| **Normal (0)** | 284,315 | 99.83% |
| **Fraud (1)** | 492 | 0.17% |

**Key Observations:**
- **Highly Imbalanced Dataset**: The dataset is extremely imbalanced with only 0.17% fraud cases
- **Class Imbalance Ratio**: Approximately 578:1 (normal:fraud)
- **Implications for Modeling**:
  - Standard accuracy metrics will be misleading (99.83% accuracy by predicting all as normal)
  - Need specialized techniques:
    - Resampling (SMOTE, undersampling, oversampling)
    - Class weights in models
    - Focus on precision, recall, F1-score, and AUC-ROC
    - Cost-sensitive learning
  - This imbalance is typical for fraud detection datasets

### Status: ✓ **COMPLETED**

---

## Step 7: Final Dataset Summary

### Final Dataset Information:

```
DATA CLEANING COMPLETE!
============================================================
Cleaned dataset: cnp_dataset/cleaned/creditcard_cleaned.csv
Total rows: 284,807
Total columns: 42
Memory usage: 84.8 MB
============================================================
```

### Dataset Dimensions:
- **Total Rows**: 284,807 (same as original - no rows removed)
- **Total Columns**: 42 (31 original + 11 new columns)
- **Memory Usage**: 84.8 MB
- **Output Location**: `cnp_dataset/cleaned/creditcard_cleaned.csv`

### Column Breakdown (42 total):

**Original Columns (31):**
1. `transaction_id` (new - added in Step 2)
2. `Time`
3. `V1` through `V28` (28 PCA features)
4. `Amount` (winsorized in Step 5)
5. `Class` (fraud label: 0 = normal, 1 = fraud)

**New Derived Columns (11):**
6. `Amount_original` (original Amount values before winsorization)
7. `transaction_timestamp_utc` (UTC timestamp)
8. `hour_of_day` (0-23)
9. `day_of_week` (Mon-Sun, ordered factor)
10. `day_of_month` (1-31)
11. `month` (month names, ordered factor)
12. `is_weekend` (TRUE/FALSE)
13. `seconds_since_first` (same as Time, kept for reference)
14. `time_of_day` (Morning/Afternoon/Evening/Night)
15. `time_since_previous` (seconds since previous transaction)

### Data Quality Summary:

**Completeness:**
- ✓ No missing values (0 total)
- ✓ All 284,807 rows preserved
- ✓ All original data maintained

**Data Integrity:**
- ✓ Original Amount values preserved in `Amount_original`
- ✓ All original features (V1-V28) unchanged
- ✓ Transaction IDs created for tracking

**Enhancements:**
- ✓ 8 time-based features derived
- ✓ Amount distribution improved (skewness reduced 77.6%)
- ✓ UTC timestamps for temporal analysis

### Status: ✓ **COMPLETED**

---

## Conclusions

### Summary of Cleaning Steps

1. ✓ **Identifiers Normalized**: Transaction ID created, original names preserved
2. ✓ **Missing Values Handled**: No missing values found (0 total)
3. ✓ **Timestamps Converted**: UTC timestamps and 8 time-based features created
4. ✓ **Amounts Winsorized**: Skewness reduced from 16.98 to 3.81 (77.6% reduction)
5. ✓ **Quality Checks**: 896 duplicates found, data types verified, fraud distribution analyzed (0.17% fraud)
6. ✓ **Dataset Saved**: Final cleaned dataset with 284,807 rows and 42 columns saved successfully

### Data Quality Assessment

**Strengths:**
- No missing values
- Complete dataset
- Standard column format

**Improvements Made:**
- Transaction IDs added
- Timestamps converted to UTC
- Time-based features derived
- Extreme amounts winsorized

**Dataset Ready For:**
- Exploratory Data Analysis (EDA)
- Feature Engineering
- Machine Learning Modeling (with appropriate handling for class imbalance)
- Statistical Analysis
- Temporal Pattern Analysis
- Fraud Detection Model Development

**Final Dataset Statistics:**
- **Rows**: 284,807 (all original rows preserved)
- **Columns**: 42 (31 original + 11 new derived columns)
- **Size**: 84.8 MB
- **Output File**: `cnp_dataset/cleaned/creditcard_cleaned.csv`
- **Data Quality**: Excellent - no missing values, all data types correct

---

## Appendix

### A. Code Repository
- `clean_cnp_dataset.R`: Main cleaning script
- `load_dataset.R`: Dataset loading script

### B. References
- Dataset Source: https://www.kaggle.com/mlg-ulb/creditcardfraud/
- License: Open Data Commons Database License (DbCL) v1.0

---

*Report generated on [Date]*

