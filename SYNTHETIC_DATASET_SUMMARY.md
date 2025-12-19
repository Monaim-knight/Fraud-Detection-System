# Synthetic Dataset Creation - Summary

## What Was Created

I've created a complete synthetic dataset generation system that aligns with your CNP fraud detection project. This system allows you to generate realistic synthetic data and implement all 9 placeholder features.

## Files Created

### 1. **`generate_synthetic_dataset.R`** (Main Generator)
   - Generates a realistic synthetic dataset with 50,000 transactions
   - Includes all fields needed for placeholder features:
     - Customer IDs, Device IDs, IP addresses
     - Email addresses and domains
     - Billing/shipping addresses and countries
     - Card BINs (prepaid and regular)
   - Creates realistic fraud patterns and relationships
   - Matches the structure of your original CNP dataset

### 2. **`create_reference_data.R`** (Reference Data Creator)
   - Creates reference lists needed for risk flags:
     - Disposable email domain list
     - Prepaid card BIN list
     - High-risk country list
   - Saves files to `data/` directory

### 3. **`implement_placeholder_features.R`** (Updated)
   - Now works with both synthetic and real datasets
   - Automatically detects which dataset to use
   - Implements all 9 placeholder features when data is available

### 4. **Documentation Files:**
   - **`SYNTHETIC_DATASET_README.md`**: Comprehensive guide to the synthetic dataset
   - **`QUICK_START_SYNTHETIC.md`**: Step-by-step quick start guide
   - **`Data_Collection_Guide.md`**: Guide for collecting real data (already created)

## Quick Start

Run these three scripts in order:

```r
# 1. Create reference data files
source("create_reference_data.R")

# 2. Generate synthetic dataset
source("generate_synthetic_dataset.R")

# 3. Implement placeholder features
source("implement_placeholder_features.R")
```

## What You Get

### Synthetic Dataset Features:

**Base Transaction Data:**
- 50,000 transactions
- ~0.17% fraud rate (matching original dataset)
- All original columns (Time, V1-V28, Amount, Class)
- Derived time features

**New Fields for Placeholder Features:**
- `customer_id`: 2,000 unique customers
- `device_id`: 3,000 unique devices (some shared)
- `ip_address`, `ip_country`: IP geolocation data
- `billing_country`, `shipping_country`: Country information
- `email`, `email_domain`: Email addresses
- `billing_address`, `shipping_address`: Address information
- `card_bin`: Card BIN (first 6 digits)

### All 9 Placeholder Features Implemented:

1. ✅ **device_reuse_count**: Count of other customers using same device
2. ✅ **ip_geo_mismatch**: Binary flag for IP/billing country mismatch
3. ✅ **email_domain_risk**: Risk score (0-3) for email domain
4. ✅ **shared_device_count**: Count of customers sharing device
5. ✅ **shared_address_count**: Count of customers sharing address
6. ✅ **device_address_network_size**: Graph network size (requires igraph)
7. ✅ **prepaid_bin_flag**: Binary flag for prepaid cards
8. ✅ **disposable_email_flag**: Binary flag for disposable emails
9. ✅ **high_risk_geo_flag**: Binary flag for high-risk countries

## Realistic Fraud Patterns

The synthetic dataset includes realistic fraud characteristics:

- **Fraud Probability Factors:**
  - Known fraudsters have 20x higher fraud probability
  - Prepaid cards: 30% of fraud cases
  - High-risk countries: 3x higher fraud probability
  - Disposable emails: 5x higher fraud probability
  - Large amounts: 2x higher fraud probability

- **Fraud Characteristics:**
  - ~40% of fraud cases have IP geo mismatch
  - Device sharing patterns
  - Address sharing patterns
  - Realistic entity relationships

## Output Files

After running all scripts:

```
cnp_dataset/
├── synthetic/
│   ├── creditcard_synthetic.csv      # Main synthetic dataset (50K rows)
│   ├── customer_profiles.csv         # Customer attributes
│   └── customer_device_map.csv       # Customer-device relationships
└── feature_engineered/
    └── creditcard_features_complete.csv  # Complete dataset with all features

data/
├── disposable_email_domains.txt       # 30+ disposable email domains
├── prepaid_bin_list.txt              # 30+ prepaid card BINs
└── high_risk_countries.txt           # High-risk country codes
```

## Benefits

1. **Immediate Testing**: Test all features without waiting for real data
2. **Complete Feature Set**: All 9 placeholder features can be implemented
3. **Realistic Patterns**: Fraud patterns match real-world scenarios
4. **Development Ready**: Use for model development and testing
5. **Pipeline Validation**: Test your entire data processing pipeline

## Next Steps

1. **Generate the Dataset**: Run the three scripts above
2. **Verify Features**: Check that all 9 placeholder features are calculated
3. **Explore Data**: Analyze feature distributions and relationships
4. **Train Models**: Use the complete feature set for model development
5. **Replace with Real Data**: When real data is available, use the same scripts

## Notes

- The synthetic dataset is designed for development and testing
- Fraud patterns are simplified but capture key relationships
- All entity relationships are realistic (device sharing, address sharing)
- When real data becomes available, simply replace the synthetic dataset
- The same feature engineering scripts work with both synthetic and real data

---

**You now have everything needed to implement and test all placeholder features!**






