# Quick Start Guide: Synthetic Dataset & Placeholder Features

## Overview

This guide will help you quickly generate a synthetic dataset and implement all 9 placeholder features.

## Step-by-Step Instructions

### Step 1: Create Reference Data Files

First, create the reference data files needed for risk flags:

```r
source("create_reference_data.R")
```

This creates:
- `data/disposable_email_domains.txt`
- `data/prepaid_bin_list.txt`
- `data/high_risk_countries.txt`

### Step 2: Generate Synthetic Dataset

Generate the synthetic dataset with all required fields:

```r
source("generate_synthetic_dataset.R")
```

This will create:
- `cnp_dataset/synthetic/creditcard_synthetic.csv` (main dataset)
- `cnp_dataset/synthetic/customer_profiles.csv` (reference)
- `cnp_dataset/synthetic/customer_device_map.csv` (reference)

**Expected Output:**
- 50,000 transactions
- ~0.17% fraud rate (matching original dataset)
- All fields needed for placeholder features

### Step 3: Implement Placeholder Features

Run the implementation script to calculate all 9 placeholder features:

```r
source("implement_placeholder_features.R")
```

This will:
- Load the synthetic dataset
- Calculate all 9 placeholder features
- Update risk_flag_count
- Save the complete dataset

**Output:**
- `cnp_dataset/feature_engineered/creditcard_features_complete.csv`

## Complete Workflow

```r
# 1. Create reference data
source("create_reference_data.R")

# 2. Generate synthetic dataset
source("generate_synthetic_dataset.R")

# 3. Implement placeholder features
source("implement_placeholder_features.R")
```

## What You Get

### Complete Dataset with All Features:

**Original Features:**
- Transaction ID, Time, V1-V28, Amount, Class
- Derived time features (hour, day, month, etc.)

**New Placeholder Features (9 total):**

1. **Identity Consistency:**
   - `device_reuse_count`
   - `ip_geo_mismatch`
   - `email_domain_risk`

2. **Graph Features:**
   - `shared_device_count`
   - `shared_address_count`
   - `device_address_network_size`

3. **Risk Flags:**
   - `prepaid_bin_flag`
   - `disposable_email_flag`
   - `high_risk_geo_flag`

**Updated:**
- `risk_flag_count` (now includes all 7 risk flags)

## Dataset Statistics

After running all scripts, you should have:

- **Total Rows**: 50,000 transactions
- **Total Columns**: ~70+ (original + derived + placeholder features)
- **Fraud Rate**: ~0.17%
- **All Features**: Fully implemented and ready for modeling

## Verification

Check that all features are implemented:

```r
# Load the complete dataset
df <- read_csv("cnp_dataset/feature_engineered/creditcard_features_complete.csv")

# Check placeholder features
placeholder_features <- c(
  "device_reuse_count", "ip_geo_mismatch", "email_domain_risk",
  "shared_device_count", "shared_address_count", "device_address_network_size",
  "prepaid_bin_flag", "disposable_email_flag", "high_risk_geo_flag"
)

# Verify all features exist
missing <- setdiff(placeholder_features, colnames(df))
if (length(missing) == 0) {
  cat("✓ All placeholder features implemented!\n")
} else {
  cat("⚠ Missing features:", paste(missing, collapse = ", "), "\n")
}

# Check feature statistics
cat("\nFeature Statistics:\n")
for (feat in placeholder_features) {
  if (feat %in% colnames(df)) {
    cat(sprintf("  %s: min=%.2f, max=%.2f, mean=%.2f\n",
                feat, min(df[[feat]], na.rm=TRUE), 
                max(df[[feat]], na.rm=TRUE), 
                mean(df[[feat]], na.rm=TRUE)))
  }
}
```

## Troubleshooting

### Issue: "No dataset found"
**Solution**: Make sure you've run `generate_synthetic_dataset.R` first

### Issue: "Missing columns for identity features"
**Solution**: The synthetic dataset should include all required columns. Check that the generation script completed successfully.

### Issue: "igraph package not installed"
**Solution**: Install with `install.packages("igraph")` for graph network features

### Issue: Reference data files not found
**Solution**: Run `create_reference_data.R` first to create the reference files

## Next Steps

Once all features are implemented:

1. **Exploratory Data Analysis**: Analyze feature distributions and relationships
2. **Feature Importance**: Identify which features are most predictive
3. **Model Training**: Train fraud detection models with complete feature set
4. **Validation**: Test model performance on synthetic data
5. **Real Data Integration**: When real data is available, replace synthetic dataset

## Files Created

```
cnp_dataset/
├── synthetic/
│   ├── creditcard_synthetic.csv      # Main synthetic dataset
│   ├── customer_profiles.csv         # Customer attributes
│   └── customer_device_map.csv       # Customer-device relationships
└── feature_engineered/
    └── creditcard_features_complete.csv  # Complete dataset with all features

data/
├── disposable_email_domains.txt       # Disposable email domain list
├── prepaid_bin_list.txt              # Prepaid card BIN list
└── high_risk_countries.txt           # High-risk country codes
```

---

**You're all set! The synthetic dataset is ready for feature engineering and model development.**






