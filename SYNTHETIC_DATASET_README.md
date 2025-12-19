# Synthetic Dataset Generator - README

## Overview

This script generates a realistic synthetic dataset for the CNP (Card Not Present) fraud detection project. The synthetic dataset includes all the fields needed to implement the 9 placeholder features that were identified in the feature engineering step.

## Purpose

The synthetic dataset allows you to:
- **Test feature engineering**: Implement and test all placeholder features without waiting for real data collection
- **Develop models**: Build and test fraud detection models with complete feature sets
- **Validate pipelines**: Test your entire data processing pipeline end-to-end
- **Learn patterns**: Understand how different features relate to fraud patterns

## Generated Dataset Structure

### Main Dataset: `creditcard_synthetic.csv`

**Original Columns (matching CNP dataset):**
- `transaction_id`: Unique transaction identifier
- `Time`: Seconds since first transaction
- `V1` through `V28`: PCA-transformed features (28 features)
- `Amount`: Transaction amount
- `Class`: Fraud label (0 = normal, 1 = fraud)

**New Fields for Placeholder Features:**
- `customer_id`: Unique customer identifier
- `device_id`: Device identifier (some devices shared across customers)
- `ip_address`: IP address of transaction
- `ip_country`: Country derived from IP address
- `billing_country`: Country from billing address
- `shipping_country`: Country from shipping address
- `email`: Customer email address
- `email_domain`: Extracted email domain
- `billing_address`: Billing address
- `shipping_address`: Shipping address
- `card_bin`: First 6 digits of card (Bank Identification Number)

**Derived Time Features:**
- `transaction_timestamp_utc`: Full UTC timestamp
- `hour_of_day`: Hour (0-23)
- `day_of_week`: Day of week
- `day_of_month`: Day of month
- `month`: Month name
- `is_weekend`: Boolean weekend indicator
- `seconds_since_first`: Seconds since first transaction
- `time_of_day`: Categorical time period (Morning/Afternoon/Evening/Night)
- `time_since_previous`: Seconds since previous transaction

### Reference Files:

1. **`customer_profiles.csv`**: Customer attributes including email domain, billing country, address, and fraudster flag
2. **`customer_device_map.csv`**: Mapping of customers to devices (many-to-many relationship)

## Features Included

### ✅ All 9 Placeholder Features Can Be Implemented:

1. **Identity Consistency (3 features):**
   - `device_reuse_count`: Count of other customers using same device
   - `ip_geo_mismatch`: Binary flag (1 if IP country ≠ billing country)
   - `email_domain_risk`: Risk score (0-3) for email domain

2. **Graph Features (3 features):**
   - `shared_device_count`: Count of customers sharing same device
   - `shared_address_count`: Count of customers sharing same address
   - `device_address_network_size`: Size of connected component in device-address graph

3. **Risk Flags (3 features):**
   - `prepaid_bin_flag`: Binary flag (1 if card BIN is prepaid)
   - `disposable_email_flag`: Binary flag (1 if email domain is disposable)
   - `high_risk_geo_flag`: Binary flag (1 if IP country is high-risk)

## Realistic Fraud Patterns

The synthetic dataset includes realistic fraud patterns:

1. **Fraud Probability Factors:**
   - Known fraudsters have higher fraud probability
   - Prepaid cards are more likely to be fraud
   - High-risk countries increase fraud probability
   - Disposable emails increase fraud probability
   - Large transaction amounts increase fraud probability

2. **Fraud Characteristics:**
   - ~40% of fraud cases have IP geo mismatch
   - ~30% of fraud cases use prepaid cards
   - Higher proportion of disposable emails in fraud cases
   - Higher proportion of high-risk countries in fraud cases

3. **Device Sharing:**
   - Some devices are shared across multiple customers (realistic scenario)
   - Fraudsters may use shared devices more frequently

4. **Address Patterns:**
   - Most transactions have matching billing/shipping addresses
   - ~10% have different shipping addresses
   - Some addresses are shared across customers

## Usage

### Step 1: Generate the Synthetic Dataset

```r
# Run the generator script
source("generate_synthetic_dataset.R")
```

This will create:
- `cnp_dataset/synthetic/creditcard_synthetic.csv` (main dataset)
- `cnp_dataset/synthetic/customer_profiles.csv` (reference)
- `cnp_dataset/synthetic/customer_device_map.csv` (reference)

### Step 2: Implement Placeholder Features

Once the synthetic dataset is generated, you can run the placeholder feature implementation script:

```r
# First, update the script to use the synthetic dataset
# Change the input path in implement_placeholder_features.R:
# df <- read_csv("cnp_dataset/synthetic/creditcard_synthetic.csv", ...)

# Then run the implementation
source("implement_placeholder_features.R")
```

### Step 3: Use for Model Development

The complete dataset with all features can now be used for:
- Exploratory data analysis
- Feature importance analysis
- Model training and validation
- Pipeline testing

## Configuration

You can customize the dataset generation by modifying these parameters in `generate_synthetic_dataset.R`:

```r
N_TRANSACTIONS <- 50000      # Number of transactions
FRAUD_RATE <- 0.0017         # Fraud rate (~0.17%)
N_CUSTOMERS <- 2000          # Number of unique customers
N_DEVICES <- 3000            # Number of unique devices
N_ADDRESSES <- 1500          # Number of unique addresses
N_IPS <- 500                 # Number of unique IP addresses
```

## Dataset Characteristics

### Size:
- **Default**: 50,000 transactions
- **Fraud Rate**: ~0.17% (matching original CNP dataset)
- **Date Range**: September 2013 (matching original dataset)

### Entity Relationships:
- **Customers**: 2,000 unique customers
- **Devices**: 3,000 unique devices (some shared)
- **Addresses**: 1,500 unique addresses (some shared)
- **IP Addresses**: 500 unique IPs

### Data Quality:
- ✅ No missing values
- ✅ Realistic distributions
- ✅ Proper relationships between entities
- ✅ Fraud patterns aligned with real-world scenarios

## File Structure

```
cnp_dataset/
└── synthetic/
    ├── creditcard_synthetic.csv      # Main synthetic dataset
    ├── customer_profiles.csv         # Customer attributes
    └── customer_device_map.csv       # Customer-device relationships
```

## Next Steps

1. **Generate the dataset**: Run `generate_synthetic_dataset.R`
2. **Implement features**: Use `implement_placeholder_features.R` with the synthetic dataset
3. **Validate features**: Check that all 9 placeholder features are correctly calculated
4. **Train models**: Use the complete feature set for model development
5. **Compare with real data**: When real data is available, compare patterns and adjust

## Notes

- The synthetic dataset is designed to be realistic but is **not real transaction data**
- Use it for development, testing, and learning purposes
- When real data becomes available, replace the synthetic dataset
- The fraud patterns are simplified but capture key relationships
- All entity relationships are designed to be realistic (device sharing, address sharing, etc.)

## Troubleshooting

### Issue: Script runs slowly
**Solution**: Reduce `N_TRANSACTIONS` for faster generation during testing

### Issue: Too many/few fraud cases
**Solution**: Adjust `FRAUD_RATE` parameter

### Issue: Missing relationships
**Solution**: Increase `N_CUSTOMERS`, `N_DEVICES`, etc. to create more connections

---

*Generated synthetic dataset is ready for feature engineering and model development!*






