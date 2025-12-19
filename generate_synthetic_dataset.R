# =============================================================================
# Synthetic Dataset Generator for CNP Fraud Detection Project
# Creates a realistic synthetic dataset aligned with the project structure
# Includes all fields needed for placeholder features
# =============================================================================

# Load required libraries
library(readr)
library(dplyr)
library(lubridate)
library(stringr)

# Set random seed for reproducibility
set.seed(42)

# =============================================================================
# Configuration
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Synthetic Dataset Generator for CNP Fraud Detection\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Dataset size
N_TRANSACTIONS <- 50000  # Adjust as needed
FRAUD_RATE <- 0.0017     # ~0.17% fraud rate (matching original dataset)

# Date range (September 2013, matching original dataset)
START_DATE <- as.POSIXct("2013-09-01 00:00:00", tz = "UTC")
END_DATE <- as.POSIXct("2013-09-30 23:59:59", tz = "UTC")

# Number of unique entities
N_CUSTOMERS <- 2000
N_DEVICES <- 3000
N_ADDRESSES <- 1500
N_IPS <- 500

cat(sprintf("Generating %d transactions...\n", N_TRANSACTIONS))
cat(sprintf("Fraud rate: %.2f%%\n", FRAUD_RATE * 100))
cat(sprintf("Date range: %s to %s\n\n", START_DATE, END_DATE))

# =============================================================================
# Step 1: Generate Base Entity Data
# =============================================================================

cat("Step 1: Generating base entity data...\n")

# Generate customer IDs
customer_ids <- paste0("CUST_", sprintf("%06d", 1:N_CUSTOMERS))

# Generate device IDs (more devices than customers - some sharing)
device_ids <- paste0("DEV_", sprintf("%06d", 1:N_DEVICES))

# Generate email domains
corporate_domains <- c("acme.com", "techcorp.com", "finance.com", "retail.com", 
                      "services.com", "enterprise.com", "business.com")
free_email_domains <- c("gmail.com", "yahoo.com", "hotmail.com", "outlook.com", 
                        "aol.com", "icloud.com", "mail.com", "protonmail.com")
disposable_domains <- c("tempmail.com", "throwaway.com", "guerrillamail.com", 
                       "10minutemail.com", "mailinator.com", "trashmail.com")

all_email_domains <- c(corporate_domains, free_email_domains, disposable_domains)

# Generate country codes
low_risk_countries <- c("US", "CA", "GB", "DE", "FR", "AU", "JP", "CH", "SE", "NO")
medium_risk_countries <- c("BR", "MX", "IN", "CN", "RU", "TR", "ZA", "AR", "CL", "CO")
high_risk_countries <- c("XX", "YY", "ZZ", "AA", "BB")  # Placeholder high-risk codes

all_countries <- c(low_risk_countries, medium_risk_countries, high_risk_countries)

# Generate IP addresses (simplified)
generate_ip <- function(n) {
  paste0(
    sample(1:255, n, replace = TRUE), ".",
    sample(1:255, n, replace = TRUE), ".",
    sample(1:255, n, replace = TRUE), ".",
    sample(1:255, n, replace = TRUE)
  )
}

# Generate addresses
generate_address <- function(n) {
  streets <- c("Main St", "Oak Ave", "Park Blvd", "Elm St", "Cedar Ln", 
               "Maple Dr", "Pine Rd", "First St", "Second Ave", "High St")
  cities <- c("New York", "Los Angeles", "Chicago", "Houston", "Phoenix",
              "Philadelphia", "San Antonio", "San Diego", "Dallas", "San Jose")
  
  paste0(
    sample(100:9999, n, replace = TRUE), " ",
    sample(streets, n, replace = TRUE), ", ",
    sample(cities, n, replace = TRUE)
  )
}

# Generate card BINs
prepaid_bins <- c("411111", "422222", "433333", "444444", "455555")
regular_bins <- c("510000", "520000", "530000", "540000", "550000",
                  "400000", "401000", "402000", "403000", "404000")

all_bins <- c(prepaid_bins, regular_bins)

cat("✓ Base entity data generated\n\n")

# =============================================================================
# Step 2: Create Customer Profiles
# =============================================================================

cat("Step 2: Creating customer profiles...\n")

# Create customer profiles with attributes
customer_profiles <- data.frame(
  customer_id = customer_ids,
  email_domain = sample(all_email_domains, N_CUSTOMERS, replace = TRUE),
  billing_country = sample(all_countries, N_CUSTOMERS, replace = TRUE, 
                          prob = c(rep(0.4, length(low_risk_countries)),
                                   rep(0.5, length(medium_risk_countries)),
                                   rep(0.1, length(high_risk_countries)))),
  billing_address = generate_address(N_CUSTOMERS),
  is_fraudster = sample(c(0, 1), N_CUSTOMERS, replace = TRUE, 
                        prob = c(1 - FRAUD_RATE * 10, FRAUD_RATE * 10)),
  stringsAsFactors = FALSE
)

# Assign devices to customers (some customers share devices)
customer_device_map <- data.frame(
  customer_id = sample(customer_ids, N_CUSTOMERS * 1.5, replace = TRUE),
  device_id = sample(device_ids, N_CUSTOMERS * 1.5, replace = TRUE),
  stringsAsFactors = FALSE
) %>%
  distinct()

cat(sprintf("✓ Created %d customer profiles\n", N_CUSTOMERS))
cat(sprintf("✓ Created %d customer-device relationships\n\n", nrow(customer_device_map)))

# =============================================================================
# Step 3: Generate Transactions
# =============================================================================

cat("Step 3: Generating transactions...\n")

# Generate transaction times (uniform distribution over date range)
time_range <- as.numeric(difftime(END_DATE, START_DATE, units = "secs"))
transaction_times <- START_DATE + runif(N_TRANSACTIONS, 0, time_range)
transaction_times <- sort(transaction_times)

# Assign customers to transactions
transaction_customers <- sample(customer_ids, N_TRANSACTIONS, replace = TRUE)

# Assign devices based on customer (with some randomness)
get_device_for_customer <- function(cust_id) {
  available_devices <- customer_device_map$device_id[customer_device_map$customer_id == cust_id]
  if (length(available_devices) > 0) {
    sample(available_devices, 1)
  } else {
    # If customer has no device, assign a random one
    sample(device_ids, 1)
  }
}

transaction_devices <- sapply(transaction_customers, get_device_for_customer)

# Get customer attributes
customer_lookup <- customer_profiles %>%
  select(customer_id, email_domain, billing_country, billing_address, is_fraudster) %>%
  setNames(c("customer_id", "email_domain", "billing_country", "billing_address", "is_fraudster"))

# Generate transaction amounts (realistic distribution)
# Most transactions are small, some are large
amounts <- c(
  rexp(N_TRANSACTIONS * 0.7, rate = 1/50),  # 70% small transactions
  rexp(N_TRANSACTIONS * 0.25, rate = 1/200), # 25% medium transactions
  rexp(N_TRANSACTIONS * 0.05, rate = 1/500)  # 5% large transactions
)[1:N_TRANSACTIONS]
amounts <- round(amounts, 2)
amounts <- pmax(amounts, 0.01)  # Minimum amount

# Generate fraud labels
# Fraud probability increases for:
# - Known fraudsters
# - Prepaid cards
# - High-risk countries
# - Disposable emails
# - Device sharing
# - IP geo mismatch

fraud_labels <- numeric(N_TRANSACTIONS)

for (i in 1:N_TRANSACTIONS) {
  cust_id <- transaction_customers[i]
  cust_profile <- customer_lookup[customer_lookup$customer_id == cust_id, ]
  
  # Base fraud probability
  fraud_prob <- FRAUD_RATE
  
  # Increase if customer is a known fraudster
  if (cust_profile$is_fraudster == 1) {
    fraud_prob <- fraud_prob * 20
  }
  
  # Increase for high-risk countries
  if (cust_profile$billing_country %in% high_risk_countries) {
    fraud_prob <- fraud_prob * 3
  }
  
  # Increase for disposable emails
  if (cust_profile$email_domain %in% disposable_domains) {
    fraud_prob <- fraud_prob * 5
  }
  
  # Increase for large amounts
  if (amounts[i] > 500) {
    fraud_prob <- fraud_prob * 2
  }
  
  # Cap at 0.5 (50% max)
  fraud_prob <- min(fraud_prob, 0.5)
  
  fraud_labels[i] <- rbinom(1, 1, fraud_prob)
}

cat(sprintf("✓ Generated %d transactions\n", N_TRANSACTIONS))
cat(sprintf("✓ Fraud transactions: %d (%.2f%%)\n", 
            sum(fraud_labels), mean(fraud_labels) * 100))

# =============================================================================
# Step 4: Generate Additional Transaction Attributes
# =============================================================================

cat("\nStep 4: Generating transaction attributes...\n")

# Generate IP addresses and countries
# For fraud cases, sometimes use mismatched IP countries
ip_addresses <- generate_ip(N_TRANSACTIONS)
ip_countries <- character(N_TRANSACTIONS)

for (i in 1:N_TRANSACTIONS) {
  cust_id <- transaction_customers[i]
  billing_country <- customer_lookup$billing_country[customer_lookup$customer_id == cust_id]
  
  if (fraud_labels[i] == 1 && runif(1) < 0.4) {
    # 40% of fraud cases have IP geo mismatch
    ip_countries[i] <- sample(setdiff(all_countries, billing_country), 1)
  } else {
    # Most transactions have matching IP country
    ip_countries[i] <- billing_country
  }
}

# Generate card BINs
# Fraud cases more likely to use prepaid cards
card_bins <- character(N_TRANSACTIONS)
for (i in 1:N_TRANSACTIONS) {
  if (fraud_labels[i] == 1 && runif(1) < 0.3) {
    # 30% of fraud uses prepaid
    card_bins[i] <- sample(prepaid_bins, 1)
  } else {
    card_bins[i] <- sample(regular_bins, 1)
  }
}

# Generate emails
emails <- character(N_TRANSACTIONS)
for (i in 1:N_TRANSACTIONS) {
  cust_id <- transaction_customers[i]
  domain <- customer_lookup$email_domain[customer_lookup$customer_id == cust_id]
  username <- paste0("user", sample(1000:9999, 1))
  emails[i] <- paste0(username, "@", domain)
}

# Generate shipping addresses (usually same as billing, sometimes different)
shipping_addresses <- character(N_TRANSACTIONS)
for (i in 1:N_TRANSACTIONS) {
  cust_id <- transaction_customers[i]
  billing_addr <- customer_lookup$billing_address[customer_lookup$customer_id == cust_id]
  
  if (runif(1) < 0.1) {
    # 10% have different shipping address
    shipping_addresses[i] <- generate_address(1)
  } else {
    shipping_addresses[i] <- billing_addr
  }
}

# Generate PCA features (V1-V28)
# These are normally distributed (matching original dataset characteristics)
pca_features <- matrix(rnorm(N_TRANSACTIONS * 28), nrow = N_TRANSACTIONS, ncol = 28)
colnames(pca_features) <- paste0("V", 1:28)

# Adjust PCA features slightly for fraud cases (make them more extreme)
for (i in which(fraud_labels == 1)) {
  # Fraud cases have more extreme PCA values
  pca_features[i, ] <- pca_features[i, ] * 1.5 + rnorm(28, 0, 0.5)
}

cat("✓ Generated transaction attributes\n\n")

# =============================================================================
# Step 5: Assemble Dataset
# =============================================================================

cat("Step 5: Assembling dataset...\n")

# Calculate Time (seconds since first transaction)
first_time <- min(transaction_times)
time_seconds <- as.numeric(difftime(transaction_times, first_time, units = "secs"))

# Create main dataset
df_synthetic <- data.frame(
  transaction_id = 1:N_TRANSACTIONS,
  Time = time_seconds,
  pca_features,
  Amount = amounts,
  Class = fraud_labels,
  # New fields for placeholder features
  customer_id = transaction_customers,
  device_id = transaction_devices,
  ip_address = ip_addresses,
  ip_country = ip_countries,
  billing_country = customer_lookup$billing_country[match(transaction_customers, customer_lookup$customer_id)],
  shipping_country = ip_countries,  # Usually same as IP country
  email = emails,
  email_domain = customer_lookup$email_domain[match(transaction_customers, customer_lookup$customer_id)],
  billing_address = customer_lookup$billing_address[match(transaction_customers, customer_lookup$customer_id)],
  shipping_address = shipping_addresses,
  card_bin = card_bins,
  transaction_timestamp_utc = transaction_times,
  stringsAsFactors = FALSE
)

cat("✓ Dataset assembled\n\n")

# =============================================================================
# Step 6: Add Derived Time Features (matching cleaning script)
# =============================================================================

cat("Step 6: Adding derived time features...\n")

df_synthetic <- df_synthetic %>%
  mutate(
    hour_of_day = hour(transaction_timestamp_utc),
    day_of_week = wday(transaction_timestamp_utc, label = TRUE, abbr = FALSE),
    day_of_month = day(transaction_timestamp_utc),
    month = month(transaction_timestamp_utc, label = TRUE, abbr = FALSE),
    is_weekend = wday(transaction_timestamp_utc) %in% c(1, 7),
    seconds_since_first = Time,
    time_of_day = case_when(
      hour_of_day >= 6 & hour_of_day < 12 ~ "Morning",
      hour_of_day >= 12 & hour_of_day < 18 ~ "Afternoon",
      hour_of_day >= 18 & hour_of_day < 22 ~ "Evening",
      TRUE ~ "Night"
    ),
    time_since_previous = c(0, diff(Time))
  )

cat("✓ Derived time features added\n\n")

# =============================================================================
# Step 6.5: Add Risk Flags (matching feature engineering script)
# =============================================================================

cat("Step 6.5: Adding risk flags...\n")

df_synthetic <- df_synthetic %>%
  mutate(
    # Risk flag: High amount transactions
    # Flag transactions above 95th percentile as high risk
    high_amount_flag = ifelse(Amount > quantile(Amount, 0.95, na.rm = TRUE), 1, 0),
    
    # Risk flag: Unusual time (late night/early morning)
    # Transactions between 2 AM and 5 AM are higher risk
    unusual_time_flag = ifelse(hour_of_day >= 2 & hour_of_day < 5, 1, 0),
    
    # Risk flag: Weekend transactions
    # Weekend transactions may have different risk profile
    weekend_flag = ifelse(is_weekend == TRUE, 1, 0),
    
    # Risk flag: Rapid successive transactions
    # Multiple transactions within short time window
    rapid_transaction_flag = ifelse(time_since_previous < 60, 1, 0),  # Less than 1 minute
    
    # Placeholder flags (will be updated when placeholder features are implemented)
    prepaid_bin_flag = 0,  # Placeholder - will be updated in implement_placeholder_features.R
    disposable_email_flag = 0,  # Placeholder - will be updated in implement_placeholder_features.R
    high_risk_geo_flag = 0,  # Placeholder - will be updated in implement_placeholder_features.R
    
    # Initial risk flag count (will be updated after placeholder features are implemented)
    risk_flag_count = (
      high_amount_flag + 
      unusual_time_flag + 
      weekend_flag + 
      rapid_transaction_flag
    )
  )

cat("✓ Risk flags created:\n")
cat("  - high_amount_flag: Transactions above 95th percentile\n")
cat("  - unusual_time_flag: Transactions between 2 AM - 5 AM\n")
cat("  - weekend_flag: Weekend transactions\n")
cat("  - rapid_transaction_flag: Transactions < 1 minute apart\n")
cat("  - prepaid_bin_flag: Prepaid card BIN (placeholder)\n")
cat("  - disposable_email_flag: Disposable email domain (placeholder)\n")
cat("  - high_risk_geo_flag: High-risk geographic location (placeholder)\n")
cat("  - risk_flag_count: Initial count (4 flags)\n\n")

# =============================================================================
# Step 7: Save Dataset
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 7: Saving Dataset\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Create output directory
output_dir <- "cnp_dataset/synthetic"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Save main dataset
output_path <- file.path(output_dir, "creditcard_synthetic.csv")
write_csv(df_synthetic, output_path)

cat(sprintf("✓ Synthetic dataset saved to: %s\n", output_path))
cat(sprintf("  Rows: %d\n", nrow(df_synthetic)))
cat(sprintf("  Columns: %d\n", ncol(df_synthetic)))

# Save customer profiles (for reference)
customer_profiles_path <- file.path(output_dir, "customer_profiles.csv")
write_csv(customer_profiles, customer_profiles_path)

# Save customer-device mapping (for reference)
device_map_path <- file.path(output_dir, "customer_device_map.csv")
write_csv(customer_device_map, device_map_path)

cat(sprintf("✓ Customer profiles saved to: %s\n", customer_profiles_path))
cat(sprintf("✓ Customer-device mapping saved to: %s\n", device_map_path))

# =============================================================================
# Step 8: Summary Statistics
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 8: Summary Statistics\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("SYNTHETIC DATASET GENERATION COMPLETE!\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

cat("Dataset Summary:\n")
cat(sprintf("  Total transactions: %d\n", nrow(df_synthetic)))
cat(sprintf("  Fraud transactions: %d (%.2f%%)\n", 
            sum(df_synthetic$Class), mean(df_synthetic$Class) * 100))
cat(sprintf("  Non-fraud transactions: %d (%.2f%%)\n", 
            sum(df_synthetic$Class == 0), mean(df_synthetic$Class == 0) * 100))
cat(sprintf("  Unique customers: %d\n", n_distinct(df_synthetic$customer_id)))
cat(sprintf("  Unique devices: %d\n", n_distinct(df_synthetic$device_id)))
cat(sprintf("  Unique IP addresses: %d\n", n_distinct(df_synthetic$ip_address)))
cat(sprintf("  Date range: %s to %s\n", 
            min(df_synthetic$transaction_timestamp_utc),
            max(df_synthetic$transaction_timestamp_utc)))

cat("\nAmount Statistics:\n")
cat(sprintf("  Mean: $%.2f\n", mean(df_synthetic$Amount)))
cat(sprintf("  Median: $%.2f\n", median(df_synthetic$Amount)))
cat(sprintf("  Min: $%.2f\n", min(df_synthetic$Amount)))
cat(sprintf("  Max: $%.2f\n", max(df_synthetic$Amount)))

cat("\nFraud Characteristics:\n")
fraud_df <- df_synthetic %>% filter(Class == 1)
cat(sprintf("  Prepaid cards: %.1f%%\n", 
            mean(fraud_df$card_bin %in% prepaid_bins) * 100))
cat(sprintf("  Disposable emails: %.1f%%\n", 
            mean(fraud_df$email_domain %in% disposable_domains) * 100))
cat(sprintf("  High-risk countries: %.1f%%\n", 
            mean(fraud_df$billing_country %in% high_risk_countries) * 100))
cat(sprintf("  IP geo mismatch: %.1f%%\n", 
            mean(fraud_df$ip_country != fraud_df$billing_country) * 100))

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Dataset is ready for feature engineering!\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")

