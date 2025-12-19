# Data Collection Guide for Placeholder Features
## Required Data Sources for 9 Placeholder Features

This guide outlines the data requirements and collection strategies for implementing the 9 placeholder features in the feature-engineered dataset.

---

## Overview

**Placeholder Features Requiring Data:**
- **Identity Consistency**: 3 features
- **Graph Features**: 3 features  
- **Risk Flags**: 3 features

**Total Placeholder Features**: 9

---

## 1. Identity Consistency Features (3 features)

### 1.1 device_reuse_count

**Feature Description:**
Count of other customer accounts using the same device.

**Required Data:**
- `customer_id` or `account_id`: Unique identifier for each customer/account
- `device_id` or `device_fingerprint`: Unique identifier for the device
- Device information can come from:
  - Browser fingerprinting
  - Device hardware IDs
  - Mobile device identifiers (IMEI, Android ID, etc.)
  - Browser/OS combination identifiers

**Data Sources:**
- Transaction logs with device information
- Mobile app analytics
- Web browser fingerprinting services
- Device management systems

**Implementation Logic:**
```r
# When data is available:
df <- df %>%
  group_by(device_id) %>%
  mutate(device_reuse_count = n_distinct(customer_id) - 1) %>%
  ungroup()
```

**Collection Priority**: High (strong fraud indicator)

---

### 1.2 ip_geo_mismatch

**Feature Description:**
Binary flag (1 if IP country ≠ billing country, else 0).

**Required Data:**
- `ip_address`: IP address of the transaction
- `ip_country`: Country derived from IP address (via geolocation)
- `billing_country`: Country from billing address
- `shipping_country`: Country from shipping address (optional, for additional checks)

**Data Sources:**
- IP geolocation services:
  - MaxMind GeoIP2
  - IP2Location
  - GeoLite2
  - ipapi.co
  - ip-api.com
- Billing/shipping address data from transaction records
- Customer profile data

**Implementation Logic:**
```r
# When data is available:
df <- df %>%
  mutate(
    ip_geo_mismatch = ifelse(ip_country != billing_country, 1, 0),
    # Optional: Also check shipping country
    ip_shipping_mismatch = ifelse(ip_country != shipping_country, 1, 0)
  )
```

**Collection Priority**: High (common fraud pattern)

---

### 1.3 email_domain_risk

**Feature Description:**
Risk score for email domain (0-3 scale).

**Required Data:**
- `email`: Customer email address
- `email_domain`: Extracted domain from email (e.g., "gmail.com" from "user@gmail.com")

**Email Domain Categories:**
- **0 (Low Risk)**: Corporate domains (company.com, organization.org)
- **1 (Medium Risk)**: Standard personal domains
- **2 (Higher Risk)**: Free email providers (gmail.com, yahoo.com, hotmail.com, etc.)
- **3 (Highest Risk)**: Disposable/temporary email services

**Data Sources:**
- Customer registration data
- Transaction records with email
- Email validation services
- Disposable email domain lists:
  - https://github.com/ivolo/disposable-email-domains
  - https://github.com/FGRibreau/mailchecker

**Implementation Logic:**
```r
# When data is available:
# Load disposable email domain list
disposable_domains <- readLines("disposable_email_domains.txt")
free_email_domains <- c("gmail.com", "yahoo.com", "hotmail.com", "outlook.com", 
                        "aol.com", "icloud.com", "protonmail.com", "mail.com")

df <- df %>%
  mutate(
    email_domain = str_extract(email, "@(.+)$") %>% str_remove("@"),
    email_domain_risk = case_when(
      email_domain %in% disposable_domains ~ 3,
      email_domain %in% free_email_domains ~ 2,
      str_detect(email_domain, "\\.(edu|gov|org)$") ~ 0,  # Educational/Government
      TRUE ~ 1  # Standard domain
    )
  )
```

**Collection Priority**: Medium (useful but not critical)

---

## 2. Graph Features (3 features)

### 2.1 shared_device_count

**Feature Description:**
Count of customer accounts sharing the same device.

**Required Data:**
- `customer_id`: Unique identifier for each customer
- `device_id`: Unique identifier for the device
- Transaction history to build device-customer relationships

**Data Sources:**
- Same as device_reuse_count (device_id, customer_id)
- Historical transaction data
- Device tracking systems

**Implementation Logic:**
```r
# When data is available:
df <- df %>%
  group_by(device_id) %>%
  mutate(shared_device_count = n_distinct(customer_id)) %>%
  ungroup()
```

**Collection Priority**: High (detects device sharing networks)

---

### 2.2 shared_address_count

**Feature Description:**
Count of customer accounts sharing the same address.

**Required Data:**
- `customer_id`: Unique identifier for each customer
- `billing_address`: Normalized billing address
- `shipping_address`: Normalized shipping address (optional)
- Address normalization (standardized format for matching)

**Data Sources:**
- Customer profile data
- Transaction records with address information
- Address validation/normalization services:
  - Google Maps Geocoding API
  - SmartyStreets
  - Loqate

**Implementation Logic:**
```r
# When data is available:
# First normalize addresses (remove case, punctuation, standardize format)
df <- df %>%
  mutate(
    billing_address_normalized = normalize_address(billing_address)
  ) %>%
  group_by(billing_address_normalized) %>%
  mutate(shared_address_count = n_distinct(customer_id)) %>%
  ungroup()
```

**Collection Priority**: Medium (useful for detecting address sharing)

---

### 2.3 device_address_network_size

**Feature Description:**
Size of connected component in device-address graph (network analysis).

**Required Data:**
- `customer_id`: Unique identifier for each customer
- `device_id`: Unique identifier for the device
- `billing_address`: Normalized billing address
- Historical data to build graph relationships

**Data Sources:**
- All of the above (device_id, customer_id, address)
- Graph analysis libraries (igraph in R, networkx in Python)

**Implementation Logic:**
```r
# When data is available:
# Requires igraph library
library(igraph)

# Build bipartite graph: customers ↔ devices, customers ↔ addresses
# Create edges
edges <- df %>%
  select(customer_id, device_id, billing_address_normalized) %>%
  gather(key = "entity_type", value = "entity_id", -customer_id) %>%
  filter(!is.na(entity_id))

# Build graph
g <- graph_from_data_frame(edges, directed = FALSE)

# Find connected components
components <- components(g)

# Map component sizes back to transactions
df <- df %>%
  mutate(
    customer_component = components$membership[as.character(customer_id)],
    device_address_network_size = components$csize[customer_component]
  )
```

**Collection Priority**: Medium (advanced feature, requires graph analysis)

---

## 3. Risk Flags (3 features)

### 3.1 prepaid_bin_flag

**Feature Description:**
Binary flag (1 if card BIN is prepaid, else 0).

**Required Data:**
- `card_bin`: First 6 digits of credit card (Bank Identification Number)
- `card_number`: Full or partial card number (first 6-8 digits sufficient)
- Prepaid BIN database/list

**Data Sources:**
- Card BIN databases:
  - Binlist.net API
  - BIN Database services
  - Card issuer databases
- Prepaid card BIN lists:
  - Visa/Mastercard prepaid BIN ranges
  - Third-party BIN databases
  - Internal card type databases

**Implementation Logic:**
```r
# When data is available:
# Load prepaid BIN list
prepaid_bins <- readLines("prepaid_bin_list.txt")  # List of prepaid BIN ranges

df <- df %>%
  mutate(
    card_bin = substr(card_number, 1, 6),  # Extract first 6 digits
    prepaid_bin_flag = ifelse(card_bin %in% prepaid_bins, 1, 0)
  )
```

**Collection Priority**: High (prepaid cards are higher fraud risk)

---

### 3.2 disposable_email_flag

**Feature Description:**
Binary flag (1 if email domain is disposable/temporary, else 0).

**Required Data:**
- `email`: Customer email address
- `email_domain`: Extracted domain from email
- Disposable email domain list

**Data Sources:**
- Same as email_domain_risk (email, email_domain)
- Disposable email domain lists:
  - https://github.com/ivolo/disposable-email-domains
  - https://github.com/FGRibreau/mailchecker
  - https://github.com/7c/fakefilter

**Implementation Logic:**
```r
# When data is available:
# Load disposable email domain list
disposable_domains <- readLines("disposable_email_domains.txt")

df <- df %>%
  mutate(
    email_domain = str_extract(email, "@(.+)$") %>% str_remove("@"),
    disposable_email_flag = ifelse(email_domain %in% disposable_domains, 1, 0)
  )
```

**Collection Priority**: Medium (correlates with fraud but not definitive)

---

### 3.3 high_risk_geo_flag

**Feature Description:**
Binary flag (1 if IP country is in high-risk countries list, else 0).

**Required Data:**
- `ip_address`: IP address of the transaction
- `ip_country`: Country derived from IP address
- High-risk countries list (based on fraud statistics)

**Data Sources:**
- IP geolocation services (same as ip_geo_mismatch)
- High-risk country lists:
  - Internal fraud statistics
  - Industry fraud reports
  - Sanctions lists
  - Countries with high fraud rates

**High-Risk Country Criteria:**
- Countries with historically high fraud rates
- Countries under sanctions
- Countries with weak financial regulations
- Countries with high cybercrime rates

**Implementation Logic:**
```r
# When data is available:
# Define high-risk countries (example list - update based on your data)
high_risk_countries <- c(
  "XX", "YY", "ZZ"  # Replace with actual country codes
  # Common examples might include certain regions, but this should be
  # based on your actual fraud data and business rules
)

df <- df %>%
  mutate(
    high_risk_geo_flag = ifelse(ip_country %in% high_risk_countries, 1, 0)
  )
```

**Collection Priority**: Medium (useful but requires careful definition of "high-risk")

---

## Data Collection Strategy

### Phase 1: High Priority Data (Critical Features)

**Immediate Collection:**
1. **Device Information** (`device_id`, `device_fingerprint`)
   - Integrate device fingerprinting in transaction processing
   - Collect from mobile apps, web browsers
   - Store in transaction logs

2. **IP Address & Geolocation** (`ip_address`, `ip_country`)
   - Capture IP address in transaction logs
   - Use IP geolocation service (MaxMind, IP2Location, etc.)
   - Store geolocation data with transactions

3. **Customer ID** (`customer_id`)
   - Ensure all transactions are linked to customer accounts
   - Maintain customer-transaction relationships

4. **Card BIN** (`card_bin` or first 6 digits of `card_number`)
   - Extract BIN from card numbers (PCI-compliant: only store first 6-8 digits)
   - Maintain BIN database for card type identification

### Phase 2: Medium Priority Data

**Secondary Collection:**
1. **Email Address** (`email`, `email_domain`)
   - Collect during customer registration
   - Extract domain for risk scoring
   - Maintain disposable email domain lists

2. **Billing/Shipping Address** (`billing_address`, `shipping_address`)
   - Normalize addresses for matching
   - Use address validation services
   - Store normalized versions

### Phase 3: Advanced Features

**Future Enhancement:**
1. **Graph Analysis Infrastructure**
   - Set up graph database or analysis tools
   - Build customer-device-address networks
   - Calculate network metrics

---

## Implementation Checklist

### Data Collection Checklist:

- [ ] **Device Information**
  - [ ] Integrate device fingerprinting
  - [ ] Collect device_id in transaction logs
  - [ ] Store device-customer relationships

- [ ] **IP & Geolocation**
  - [ ] Capture IP address in transactions
  - [ ] Set up IP geolocation service
  - [ ] Store IP country with transactions

- [ ] **Customer ID**
  - [ ] Ensure customer_id in all transactions
  - [ ] Maintain customer-transaction mapping

- [ ] **Card BIN**
  - [ ] Extract BIN from card numbers (PCI-compliant)
  - [ ] Obtain prepaid BIN database
  - [ ] Store BIN with transactions

- [ ] **Email**
  - [ ] Collect email during registration
  - [ ] Extract email domains
  - [ ] Maintain disposable email domain list

- [ ] **Address**
  - [ ] Collect billing/shipping addresses
  - [ ] Normalize addresses
  - [ ] Store normalized versions

### Feature Implementation Checklist:

- [ ] **Identity Consistency Features**
  - [ ] Implement device_reuse_count
  - [ ] Implement ip_geo_mismatch
  - [ ] Implement email_domain_risk

- [ ] **Graph Features**
  - [ ] Implement shared_device_count
  - [ ] Implement shared_address_count
  - [ ] Implement device_address_network_size (requires graph library)

- [ ] **Risk Flags**
  - [ ] Implement prepaid_bin_flag
  - [ ] Implement disposable_email_flag
  - [ ] Implement high_risk_geo_flag

---

## Data Privacy & Compliance

**Important Considerations:**

1. **PCI DSS Compliance**: 
   - Never store full card numbers
   - Only store BIN (first 6 digits) or tokenized card data
   - Follow PCI DSS guidelines for card data handling

2. **GDPR/Privacy Regulations**:
   - Obtain consent for device fingerprinting
   - Anonymize or pseudonymize customer data where possible
   - Follow data retention policies

3. **Data Security**:
   - Encrypt sensitive data (IP addresses, emails, addresses)
   - Secure storage and transmission
   - Access controls and audit logs

---

## Next Steps

1. **Identify Data Sources**: Review your transaction systems and identify where each data type can be collected
2. **Set Up Data Collection**: Integrate data collection into transaction processing pipeline
3. **Build Data Pipelines**: Create ETL processes to extract, transform, and load the data
4. **Implement Features**: Once data is available, update the feature engineering script
5. **Validate Features**: Test feature calculations and validate against known fraud cases

---

## Resources

### IP Geolocation Services:
- MaxMind GeoIP2: https://www.maxmind.com/
- IP2Location: https://www.ip2location.com/
- ipapi.co: https://ipapi.co/
- ip-api.com: https://ip-api.com/

### Disposable Email Lists:
- https://github.com/ivolo/disposable-email-domains
- https://github.com/FGRibreau/mailchecker

### BIN Databases:
- Binlist.net: https://binlist.net/
- BIN Database services

### Address Normalization:
- Google Maps Geocoding API
- SmartyStreets: https://www.smartystreets.com/
- Loqate: https://www.loqate.com/

---

*Document created to guide data collection for placeholder features*






