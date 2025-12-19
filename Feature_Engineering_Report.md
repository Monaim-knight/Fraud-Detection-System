# Feature Engineering Report
## Step 3: Advanced Feature Creation for Fraud Detection

**Date:** [Add Date]  
**Author:** [Your Name]

---

## Executive Summary

This report documents the feature engineering process for the CNP dataset. Advanced features were created across four categories: Velocity Features, Identity Consistency, Graph Features, and Risk Flags. These features enhance the dataset's predictive power for fraud detection models.

---

## Step 1: Load Labeled Dataset

### Dataset Loading:

**Results:**
*[Add results when you run the script]*

**Dataset Information:**
- **Source**: Labeled dataset from Step 2
- **Location**: `cnp_dataset/labeled/creditcard_labeled.csv`
- **Expected Rows**: 284,807
- **Expected Columns**: 42 (before feature engineering)
- **Status**: ✓ Successfully loaded

---

## Step 2: Velocity Features

### Feature Description:

Velocity features measure transaction frequency within time windows, which is a strong indicator of fraudulent behavior.

**Features Created:**
1. **transactions_10m**: Count of transactions within 10-minute window
2. **transactions_1h**: Count of transactions within 1-hour window
3. **transactions_24h**: Count of transactions within 24-hour window

**Implementation:**
- Time windows: 10 minutes (600s), 1 hour (3600s), 24 hours (86400s)
- Calculated based on `seconds_since_first` column
- **Note**: Without `customer_id`, these are time-based velocity features
- In production, group by `customer_id` first for customer-level velocity

**Results:**
```
Calculating 10-minute window (this may take a few minutes for large datasets)...
Calculating 1-hour window...
Calculating 24-hour window...
✓ Velocity features calculated
✓ Velocity features created:
  - transactions_10m: Transactions in 10-minute window
  - transactions_1h: Transactions in 1-hour window
  - transactions_24h: Transactions in 24-hour window
```

**Implementation Details:**
- **Method**: Optimized using `findInterval` with binary search (O(log n) complexity)
- **Time Windows**: 10 minutes (600s), 1 hour (3600s), 24 hours (86400s)
- **Calculation**: Count of transactions within each time window after the current transaction
- **Note**: These are time-based velocity features (not customer-based, since customer_id is not available)

**Interpretation:**
- **High velocity** (many transactions in short time) may indicate fraud
- Fraudsters often make multiple rapid transactions
- Legitimate customers typically have lower transaction velocity
- **transactions_10m**: Detects very rapid transaction bursts
- **transactions_1h**: Captures short-term transaction patterns
- **transactions_24h**: Identifies daily transaction frequency

**Status**: ✓ **COMPLETED**

---

## Step 3: Identity Consistency Features

### Feature Description:

Identity consistency features detect mismatches or suspicious patterns in user identity information.

**Features Created (Placeholders):**
1. **device_reuse_count**: Count of other accounts using the same device
2. **ip_geo_mismatch**: 1 if IP country ≠ billing country, else 0
3. **email_domain_risk**: Risk score for email domain (0-3 scale)

**Implementation Status:**
- ⚠ **Placeholder Features**: These require additional data columns not available in CNP dataset
- Required columns: `device_id`, `ip_address`, `ip_country`, `billing_country`, `email`, `email_domain`

**When Available, Would Calculate:**
- **device_reuse_count**: Count unique customer_ids sharing same device_id
- **ip_geo_mismatch**: Binary flag for geographic inconsistency
- **email_domain_risk**: 
  - 0 = Corporate domain (low risk)
  - 1 = Standard domain (medium risk)
  - 2 = Free email domain (higher risk)
  - 3 = Disposable email domain (highest risk)

**Results:**
```
Identity consistency features structure created:
  - device_reuse_count: Count of other accounts using same device (placeholder)
  - ip_geo_mismatch: 1 if IP country != billing country (placeholder)
  - email_domain_risk: Risk score for email domain (placeholder)

⚠ Note: These require additional data columns (device_id, IP, email)
```

**Implementation Status:**
- ✓ **Feature structure created**: All 3 features initialized with placeholder values (0)
- ⚠ **Data requirements**: These features require columns not available in CNP dataset:
  - `device_id` or `device_fingerprint`: For device reuse detection
  - `ip_address`, `ip_country`, `billing_country`: For geolocation mismatch
  - `email`, `email_domain`: For email domain risk scoring

**Future Implementation (when data available):**
- **device_reuse_count**: Count unique customer_ids sharing same device_id
- **ip_geo_mismatch**: Binary flag (1 if billing_country ≠ ip_country)
- **email_domain_risk**: Risk score based on email domain type:
  - 0 = Corporate domain (low risk)
  - 1 = Standard domain (medium risk)
  - 2 = Free email (gmail, yahoo, etc.) (higher risk)
  - 3 = Disposable email (10minutemail, etc.) (highest risk)

**Status**: ✓ **STRUCTURE CREATED** (Placeholders ready for future data)

---

## Step 4: Graph Features

### Feature Description:

Graph features identify connections and shared resources across multiple accounts, detecting organized fraud networks.

**Features Created (Placeholders):**
1. **shared_device_count**: Count of accounts sharing the same device
2. **shared_address_count**: Count of accounts sharing the same address
3. **device_address_network_size**: Size of connected component in device-address graph

**Implementation Status:**
- ⚠ **Placeholder Features**: These require additional data columns not available in CNP dataset
- Required columns: `customer_id`, `device_id`, `billing_address`, `shipping_address`

**When Available, Would Calculate:**
- **shared_device_count**: Number of unique customer_ids per device_id
- **shared_address_count**: Number of unique customer_ids per address
- **device_address_network_size**: Graph analysis of device-address connections

**Graph Analysis Approach:**
- Build bipartite graph: customers ↔ devices, customers ↔ addresses
- Identify connected components
- Calculate network metrics (degree, clustering coefficient)

**Results:**
```
Graph features structure created:
  - shared_device_count: Count of accounts sharing same device (placeholder)
  - shared_address_count: Count of accounts sharing same address (placeholder)
  - device_address_network_size: Size of connected component (placeholder)

⚠ Note: These require customer_id, device_id, and address columns
```

**Implementation Status:**
- ✓ **Feature structure created**: All 3 features initialized with placeholder values (0)
- ⚠ **Data requirements**: These features require columns not available in CNP dataset:
  - `customer_id`: For grouping transactions by customer/account
  - `device_id` or `device_fingerprint`: For device-based graph analysis
  - `billing_address`, `shipping_address`: For address-based graph analysis

**Future Implementation (when data available):**
- **shared_device_count**: 
  - Count unique customer_ids per device_id
  - High values indicate device sharing (potential fraud network)
  
- **shared_address_count**: 
  - Count unique customer_ids per address
  - Identifies address sharing across accounts
  
- **device_address_network_size**: 
  - Build bipartite graph: customers ↔ devices, customers ↔ addresses
  - Calculate size of connected components
  - Large networks may indicate organized fraud

**Graph Analysis Approach:**
1. Create edges: customer-device and customer-address relationships
2. Build graph structure using igraph or networkx
3. Identify connected components
4. Calculate network metrics (degree, clustering, component size)

**Status**: ✓ **STRUCTURE CREATED** (Placeholders ready for future data)

---

## Step 5: Risk Flags

### Feature Description:

Risk flags are binary indicators of suspicious patterns or high-risk characteristics.

**Features Created:**

**Implemented (4 features):**
1. **high_amount_flag**: 1 if transaction amount > 95th percentile, else 0
2. **unusual_time_flag**: 1 if transaction time is 2 AM - 5 AM, else 0
3. **weekend_flag**: 1 if transaction is on weekend, else 0
4. **rapid_transaction_flag**: 1 if time since previous transaction < 1 minute, else 0

**Placeholders (3 features):**
5. **prepaid_bin_flag**: 1 if card BIN is prepaid, else 0
6. **disposable_email_flag**: 1 if email domain is disposable, else 0
7. **high_risk_geo_flag**: 1 if IP country is high-risk, else 0

**Implementation:**
- Risk flags are binary (0 or 1)
- Multiple flags can be active simultaneously
- Combined into `risk_flag_count` feature

**Results:**
```
✓ Risk flags created:
  - high_amount_flag: Transactions above 95th percentile
  - unusual_time_flag: Transactions between 2 AM - 5 AM
  - weekend_flag: Weekend transactions
  - rapid_transaction_flag: Transactions < 1 minute apart
  - prepaid_bin_flag: Prepaid card BIN (placeholder)
  - disposable_email_flag: Disposable email domain (placeholder)
  - high_risk_geo_flag: High-risk geographic location (placeholder)
```

**Implemented Risk Flags (4 features):**
1. **high_amount_flag**: 
   - Logic: 1 if Amount > 95th percentile, else 0
   - Purpose: Flags unusually high-value transactions
   - Threshold: 95th percentile of Amount distribution
   
2. **unusual_time_flag**: 
   - Logic: 1 if hour_of_day is between 2 AM - 5 AM, else 0
   - Purpose: Flags transactions during low-activity hours
   - Rationale: Fraud often occurs during off-peak hours
   
3. **weekend_flag**: 
   - Logic: 1 if is_weekend == TRUE, else 0
   - Purpose: Flags weekend transactions
   - Rationale: Different fraud patterns may occur on weekends
   
4. **rapid_transaction_flag**: 
   - Logic: 1 if time_since_previous < 60 seconds, else 0
   - Purpose: Flags very rapid successive transactions
   - Rationale: Fraudsters often make multiple quick transactions

**Placeholder Risk Flags (3 features):**
5. **prepaid_bin_flag**: Requires card BIN data
6. **disposable_email_flag**: Requires email domain data
7. **high_risk_geo_flag**: Requires IP geolocation data

**Risk Flag Statistics:**
*[Add statistics when available - can calculate after script completes]*

**Status**: ✓ **COMPLETED** (4 implemented, 3 placeholders)

---

## Step 6: Additional Derived Features

### Feature Description:

Derived features combine existing features to capture interactions and non-linear relationships.

**Results:**
```
✓ Additional derived features created:
  - amount_log: Log-transformed amount
  - amount_squared: Squared amount
  - hour_amount_interaction: Hour × Amount interaction
  - weekend_amount_interaction: Weekend × Amount interaction
  - velocity_risk_score: Combined velocity risk score
  - risk_flag_count: Count of risk flags triggered
```

**Features Created (6 features):**

1. **amount_log**: 
   - Formula: `log1p(Amount)`
   - Purpose: Log transformation to reduce skewness and handle non-linear relationships
   - Benefits: Makes amount distribution more normal, improves model performance

2. **amount_squared**: 
   - Formula: `Amount^2`
   - Purpose: Captures quadratic relationships with amount
   - Benefits: Allows models to learn non-linear patterns

3. **hour_amount_interaction**: 
   - Formula: `hour_of_day × Amount`
   - Purpose: Captures interaction between time of day and transaction amount
   - Benefits: Identifies if high amounts are more common at certain hours

4. **weekend_amount_interaction**: 
   - Formula: `is_weekend × Amount` (Amount if weekend, 0 otherwise)
   - Purpose: Captures interaction between weekend and transaction amount
   - Benefits: Identifies if transaction patterns differ on weekends

5. **velocity_risk_score**: 
   - Formula: `(transactions_10m × 3 + transactions_1h × 2 + transactions_24h × 1) / 6`
   - Purpose: Weighted combination of velocity features
   - Weights: 10m window (3x), 1h window (2x), 24h window (1x)
   - Benefits: Single score representing overall transaction velocity risk

6. **risk_flag_count**: 
   - Formula: `sum(high_amount_flag + unusual_time_flag + weekend_flag + rapid_transaction_flag)`
   - Purpose: Count of active risk flags (0-4)
   - Benefits: Aggregated risk indicator, higher counts = higher risk

**Feature Engineering Rationale:**
- **Transformations**: Log and squared terms capture non-linear relationships
- **Interactions**: Capture combined effects of multiple features
- **Aggregations**: Combine multiple signals into single features
- **All features**: Designed to improve model's ability to detect fraud patterns

**Status**: ✓ **COMPLETED**

---

## Step 7: Feature Summary

### Feature Count:

**Results:**
```
============================================================
Feature Engineering Summary
============================================================
Original columns: 42
New features created: 22
Total columns: 64

Feature Categories:
  1. Velocity Features: 3 features
  2. Identity Consistency: 3 features (placeholders)
  3. Graph Features: 3 features (placeholders)
  4. Risk Flags: 7 features (4 implemented, 3 placeholders)
  5. Derived Features: 6 features
  Total New Features: 22
```

**Feature Breakdown:**
- **Original columns**: 42 (from cleaned dataset)
- **New features created**: 22
- **Total columns**: 64

**Feature Categories Summary:**

| Category | Count | Status |
|----------|-------|--------|
| **Velocity Features** | 3 | ✓ Implemented |
| **Identity Consistency** | 3 | ⚠ Placeholders |
| **Graph Features** | 3 | ⚠ Placeholders |
| **Risk Flags** | 7 | ✓ 4 Implemented, 3 Placeholders |
| **Derived Features** | 6 | ✓ Implemented |
| **Total New Features** | **22** | **13 Implemented, 9 Placeholders** |

**Implementation Status:**
- ✓ **13 features fully implemented** and calculated
- ⚠ **9 features structured as placeholders** (ready for future data)
- ✓ **All 22 features** added to dataset structure

**Status**: ✓ **COMPLETED**

---

## Step 8: Save Feature-Engineered Dataset

### Output Information:

**Results:**
```
✓ Feature-engineered dataset saved to: cnp_dataset/feature_engineered/creditcard_features.csv
  Rows: 284807
  Columns: 64
```

**Saved Dataset:**
- **Location**: `cnp_dataset/feature_engineered/creditcard_features.csv`
- **Rows**: 284,807 (all transactions preserved)
- **Columns**: 64 (42 original + 22 new features)
- **Status**: ✓ Successfully saved

**Dataset Details:**
- **Total Transactions**: 284,807
- **Original Features**: 42 (from cleaned dataset)
- **New Features**: 22 (13 implemented + 9 placeholders)
- **Total Features**: 64
- **File Size**: *[Can be checked after save]*

**Feature Composition:**
- Original cleaned features: 42
- Velocity features: 3
- Identity consistency (placeholders): 3
- Graph features (placeholders): 3
- Risk flags: 7 (4 implemented + 3 placeholders)
- Derived features: 6
- **Total**: 64 columns

**Status**: ✓ **COMPLETED**

---

## Step 9: Feature Documentation

### Documentation Files:

1. **Feature-Engineered Dataset**: `cnp_dataset/feature_engineered/creditcard_features.csv`
2. **Feature Documentation**: `cnp_dataset/feature_engineered/feature_documentation.txt`

**Status**: ✓ Successfully generated

---

## Final Summary

### Feature Engineering Process Complete:

**Results:**
```
============================================================
FEATURE ENGINEERING COMPLETE!
============================================================
Feature-engineered dataset: cnp_dataset/feature_engineered/creditcard_features.csv
Total rows: 284807
Total columns: 64
New features: 22
============================================================
```

### Final Dataset Summary:

- **Total Rows**: 284,807 (all transactions preserved)
- **Total Columns**: 64 (42 original + 22 new features)
- **New Features Created**: 22
- **Output Location**: `cnp_dataset/feature_engineered/creditcard_features.csv`

### Feature Implementation Summary:

**Fully Implemented (13 features):**
- ✓ 3 Velocity features (transactions_10m, transactions_1h, transactions_24h)
- ✓ 4 Risk flags (high_amount, unusual_time, weekend, rapid_transaction)
- ✓ 6 Derived features (amount_log, amount_squared, interactions, risk scores)

**Placeholders Created (9 features):**
- ⚠ 3 Identity consistency features (device_reuse, ip_geo_mismatch, email_domain_risk)
- ⚠ 3 Graph features (shared_device, shared_address, network_size)
- ⚠ 3 Risk flags (prepaid_bin, disposable_email, high_risk_geo)

**Status**: ✓ **ALL STEPS COMPLETED**

---

## Conclusions

### Summary of Feature Engineering:

1. ✓ **Velocity Features**: 3 features created and calculated (time-based)
2. ✓ **Identity Consistency**: 3 features structured (placeholders created, ready for data)
3. ✓ **Graph Features**: 3 features structured (placeholders created, ready for data)
4. ✓ **Risk Flags**: 7 features (4 implemented, 3 placeholders)
5. ✓ **Derived Features**: 6 features created
6. ✓ **Feature Summary**: Complete - 22 new features, 64 total columns (42 original + 22 new)
7. ✓ **Dataset Saved**: Successfully saved to `cnp_dataset/feature_engineered/creditcard_features.csv` (284,807 rows, 64 columns)
8. ✓ **Feature Documentation**: Successfully generated at `cnp_dataset/feature_engineered/feature_documentation.txt`

### Data Requirements for Full Implementation:

**To implement all features, the following columns are needed:**
- `customer_id`: For customer-level grouping
- `device_id` or `device_fingerprint`: For device-based features
- `ip_address`, `ip_country`, `ip_city`: For geolocation features
- `email`, `email_domain`: For email-based features
- `billing_address`, `shipping_address`: For address-based features
- `card_bin` or `card_number`: For BIN-based features

### Dataset Ready For:

- Machine Learning Model Training
- Feature Selection
- Model Evaluation
- Feature Importance Analysis

---

## Appendix

### A. Feature List

**Velocity Features:**
- transactions_10m
- transactions_1h
- transactions_24h

**Identity Consistency (Placeholders):**
- device_reuse_count
- ip_geo_mismatch
- email_domain_risk

**Graph Features (Placeholders):**
- shared_device_count
- shared_address_count
- device_address_network_size

**Risk Flags:**
- high_amount_flag
- unusual_time_flag
- weekend_flag
- rapid_transaction_flag
- prepaid_bin_flag (placeholder)
- disposable_email_flag (placeholder)
- high_risk_geo_flag (placeholder)

**Derived Features:**
- amount_log
- amount_squared
- hour_amount_interaction
- weekend_amount_interaction
- velocity_risk_score
- risk_flag_count

### B. Code Repository
- `feature_engineering.R`: Main feature engineering script

---

*Report generated on [Date]*

