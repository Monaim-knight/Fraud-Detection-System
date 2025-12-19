# =============================================================================
# Feature Engineering for CNP Dataset
# Step 3: Create Advanced Features for Fraud Detection
# =============================================================================

# Load required libraries
library(readr)
library(dplyr)
library(lubridate)

# =============================================================================
# Step 1: Load the Labeled Dataset
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Feature Engineering for CNP Dataset\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Load the labeled dataset
labeled_path <- "cnp_dataset/labeled/creditcard_labeled.csv"

if (file.exists(labeled_path)) {
  cat("Loading labeled dataset...\n")
  df <- read_csv(labeled_path, show_col_types = FALSE)
} else {
  stop("Labeled dataset not found. Please run labeling script first.")
}

cat(sprintf("Dataset loaded: %d rows, %d columns\n\n", nrow(df), ncol(df)))

# =============================================================================
# Step 2: Velocity Features
# Transactions per customer in 10m/1h/24h windows
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 1: Creating Velocity Features\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")

# Note: The CNP dataset doesn't have customer_id, so we'll use transaction_id
# and create velocity features based on time windows
# In a real scenario, you would group by customer_id

# Sort by timestamp for proper window calculations
df <- df %>%
  arrange(transaction_timestamp_utc)

# Create time-based velocity features
cat("Creating velocity features based on time windows...\n")
cat("Note: Without customer_id, these are time-based velocity features.\n")
cat("In production, group by customer_id first for customer-level velocity.\n\n")

# Define time windows in seconds
window_10m <- 10 * 60      # 10 minutes = 600 seconds
window_1h <- 60 * 60       # 1 hour = 3600 seconds
window_24h <- 24 * 60 * 60 # 24 hours = 86400 seconds

# Optimized calculation using findInterval for efficient rolling windows
cat("Calculating velocity features using optimized method...\n")
cat("This uses findInterval for efficient time window calculations...\n")

# Extract time vector for efficiency
time_vec <- df$seconds_since_first
n <- length(time_vec)

# Use findInterval for efficient rolling window calculations
# This is much faster than sapply - uses binary search
calculate_velocity <- function(times, window_size) {
  n <- length(times)
  result <- numeric(n)
  
  # Use findInterval for each time point (much faster than sapply with sum)
  for (i in 1:n) {
    # Find all transactions within the window after current time
    window_end <- times[i] + window_size
    # Use binary search - findInterval is O(log n) vs O(n) for sum
    end_idx <- findInterval(window_end, times, rightmost.closed = FALSE)
    result[i] <- max(0, end_idx - i)
  }
  
  return(result)
}

# Calculate velocity features with progress indication
cat("Calculating 10-minute window (this may take a few minutes for large datasets)...\n")
df$transactions_10m <- calculate_velocity(time_vec, window_10m)

cat("Calculating 1-hour window...\n")
df$transactions_1h <- calculate_velocity(time_vec, window_1h)

cat("Calculating 24-hour window...\n")
df$transactions_24h <- calculate_velocity(time_vec, window_24h)

cat("✓ Velocity features calculated\n")

cat("✓ Velocity features created:\n")
cat("  - transactions_10m: Transactions in 10-minute window\n")
cat("  - transactions_1h: Transactions in 1-hour window\n")
cat("  - transactions_24h: Transactions in 24-hour window\n\n")

# =============================================================================
# Step 3: Identity Consistency Features
# Device reuse count, IP geolocation mismatch, email domain risk
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 2: Creating Identity Consistency Features\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")

cat("Note: CNP dataset doesn't contain device_id, IP, or email columns.\n")
cat("Creating placeholder structure for when these features are available.\n\n")

# Placeholder columns - these would be populated with actual data
# In a real scenario, you would have columns like:
# - device_id, device_fingerprint
# - ip_address, ip_country, ip_city
# - email, email_domain
# - billing_address, shipping_address

# For now, we'll create the structure and document what would be calculated
df <- df %>%
  mutate(
    # Placeholder: Device reuse count
    # Would calculate: count of unique customers using same device_id
    # device_reuse_count = count of other transactions with same device_id
    
    # Placeholder: IP geolocation mismatch
    # Would calculate: 1 if billing_country != ip_country, else 0
    # ip_geo_mismatch = ifelse(billing_country != ip_country, 1, 0)
    
    # Placeholder: Email domain risk
    # Would calculate: risk score based on email domain (disposable, free, etc.)
    # email_domain_risk = case_when(
    #   email_domain %in% disposable_domains ~ 3,
    #   email_domain %in% free_email_domains ~ 2,
    #   email_domain %in% corporate_domains ~ 0,
    #   TRUE ~ 1
    # )
    
    # For demonstration, create dummy features based on available data
    # In production, replace with actual calculations
    device_reuse_count = 0,  # Placeholder
    ip_geo_mismatch = 0,    # Placeholder
    email_domain_risk = 0   # Placeholder
  )

cat("Identity consistency features structure created:\n")
cat("  - device_reuse_count: Count of other accounts using same device (placeholder)\n")
cat("  - ip_geo_mismatch: 1 if IP country != billing country (placeholder)\n")
cat("  - email_domain_risk: Risk score for email domain (placeholder)\n\n")
cat("⚠ Note: These require additional data columns (device_id, IP, email)\n\n")

# =============================================================================
# Step 4: Graph Features
# Shared addresses or devices across multiple accounts
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 3: Creating Graph Features\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")

cat("Note: Graph features require customer_id, device_id, address columns.\n")
cat("Creating placeholder structure for graph-based features.\n\n")

# Graph features would identify:
# - Shared devices across multiple customer accounts
# - Shared addresses across multiple customer accounts
# - Network connections between accounts

df <- df %>%
  mutate(
    # Placeholder: Shared device count
    # Would calculate: number of unique customers sharing same device_id
    # shared_device_count = count of unique customer_ids with same device_id
    
    # Placeholder: Shared address count
    # Would calculate: number of unique customers sharing same address
    # shared_address_count = count of unique customer_ids with same address
    
    # Placeholder: Device-address network size
    # Would calculate: size of connected component in device-address graph
    # device_address_network_size = size of connected component
    
    # For demonstration, create dummy features
    shared_device_count = 0,      # Placeholder
    shared_address_count = 0,     # Placeholder
    device_address_network_size = 0 # Placeholder
  )

cat("Graph features structure created:\n")
cat("  - shared_device_count: Count of accounts sharing same device (placeholder)\n")
cat("  - shared_address_count: Count of accounts sharing same address (placeholder)\n")
cat("  - device_address_network_size: Size of connected component (placeholder)\n\n")
cat("⚠ Note: These require customer_id, device_id, and address columns\n\n")

# =============================================================================
# Step 5: Risk Flags
# Prepaid BIN, disposable email, high-risk geo
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 4: Creating Risk Flags\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")

# Risk flags based on available and derived data
cat("Creating risk flags from available data...\n")

# Prepaid BIN flag (would need BIN/card number - not available in CNP dataset)
# Disposable email flag (would need email - not available)
# High-risk geo flag (would need IP/geo data - not available)

# Create risk flags based on available features
df <- df %>%
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
    
    # Placeholder: Prepaid BIN flag
    # Would check: if BIN is in prepaid BIN list
    prepaid_bin_flag = 0,  # Placeholder
    
    # Placeholder: Disposable email flag
    # Would check: if email domain is in disposable email list
    disposable_email_flag = 0,  # Placeholder
    
    # Placeholder: High-risk geo flag
    # Would check: if IP country is in high-risk countries list
    high_risk_geo_flag = 0  # Placeholder
  )

cat("✓ Risk flags created:\n")
cat("  - high_amount_flag: Transactions above 95th percentile\n")
cat("  - unusual_time_flag: Transactions between 2 AM - 5 AM\n")
cat("  - weekend_flag: Weekend transactions\n")
cat("  - rapid_transaction_flag: Transactions < 1 minute apart\n")
cat("  - prepaid_bin_flag: Prepaid card BIN (placeholder)\n")
cat("  - disposable_email_flag: Disposable email domain (placeholder)\n")
cat("  - high_risk_geo_flag: High-risk geographic location (placeholder)\n\n")

# =============================================================================
# Step 6: Additional Derived Features
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 5: Creating Additional Derived Features\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")

# Create additional useful features from available data
df <- df %>%
  mutate(
    # Amount-based features
    amount_log = log1p(Amount),  # Log transform to reduce skewness
    amount_squared = Amount^2,
    
    # Time-based interaction features
    hour_amount_interaction = hour_of_day * Amount,
    weekend_amount_interaction = ifelse(is_weekend, Amount, 0),
    
    # Velocity-based risk score
    velocity_risk_score = (
      transactions_10m * 3 + 
      transactions_1h * 2 + 
      transactions_24h * 1
    ) / 6,
    
    # Combined risk flag count
    risk_flag_count = (
      high_amount_flag + 
      unusual_time_flag + 
      weekend_flag + 
      rapid_transaction_flag
    )
  )

cat("✓ Additional derived features created:\n")
cat("  - amount_log: Log-transformed amount\n")
cat("  - amount_squared: Squared amount\n")
cat("  - hour_amount_interaction: Hour × Amount interaction\n")
cat("  - weekend_amount_interaction: Weekend × Amount interaction\n")
cat("  - velocity_risk_score: Combined velocity risk score\n")
cat("  - risk_flag_count: Count of risk flags triggered\n\n")

# =============================================================================
# Step 7: Feature Summary
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Feature Engineering Summary\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")

cat(sprintf("Original columns: %d\n", 42))
cat(sprintf("New features created: %d\n", ncol(df) - 42))
cat(sprintf("Total columns: %d\n\n", ncol(df)))

cat("Feature Categories:\n")
cat("  1. Velocity Features: 3 features\n")
cat("  2. Identity Consistency: 3 features (placeholders)\n")
cat("  3. Graph Features: 3 features (placeholders)\n")
cat("  4. Risk Flags: 7 features (4 implemented, 3 placeholders)\n")
cat("  5. Derived Features: 6 features\n")
cat("  Total New Features: 22\n\n")

# =============================================================================
# Step 8: Save Feature-Engineered Dataset
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Saving Feature-Engineered Dataset\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")

# Create output directory
output_dir <- "cnp_dataset/feature_engineered"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Save feature-engineered dataset
output_path <- file.path(output_dir, "creditcard_features.csv")
write_csv(df, output_path)

cat(sprintf("✓ Feature-engineered dataset saved to: %s\n", output_path))
cat(sprintf("  Rows: %d\n", nrow(df)))
cat(sprintf("  Columns: %d\n", ncol(df)))

# =============================================================================
# Step 9: Create Feature Documentation
# =============================================================================

feature_doc_path <- file.path(output_dir, "feature_documentation.txt")
sink(feature_doc_path)
cat("CNP Dataset Feature Engineering Documentation\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

cat("FEATURE CATEGORIES:\n\n")

cat("1. VELOCITY FEATURES:\n")
cat("   - transactions_10m: Count of transactions in 10-minute window\n")
cat("   - transactions_1h: Count of transactions in 1-hour window\n")
cat("   - transactions_24h: Count of transactions in 24-hour window\n\n")

cat("2. IDENTITY CONSISTENCY FEATURES (Placeholders):\n")
cat("   - device_reuse_count: Count of accounts using same device\n")
cat("   - ip_geo_mismatch: 1 if IP country != billing country\n")
cat("   - email_domain_risk: Risk score for email domain (0-3)\n\n")

cat("3. GRAPH FEATURES (Placeholders):\n")
cat("   - shared_device_count: Count of accounts sharing device\n")
cat("   - shared_address_count: Count of accounts sharing address\n")
cat("   - device_address_network_size: Size of connected component\n\n")

cat("4. RISK FLAGS:\n")
cat("   - high_amount_flag: Transactions above 95th percentile\n")
cat("   - unusual_time_flag: Transactions 2 AM - 5 AM\n")
cat("   - weekend_flag: Weekend transactions\n")
cat("   - rapid_transaction_flag: Transactions < 1 minute apart\n")
cat("   - prepaid_bin_flag: Prepaid card BIN (placeholder)\n")
cat("   - disposable_email_flag: Disposable email (placeholder)\n")
cat("   - high_risk_geo_flag: High-risk location (placeholder)\n\n")

cat("5. DERIVED FEATURES:\n")
cat("   - amount_log: Log-transformed amount\n")
cat("   - amount_squared: Squared amount\n")
cat("   - hour_amount_interaction: Hour × Amount\n")
cat("   - weekend_amount_interaction: Weekend × Amount\n")
cat("   - velocity_risk_score: Combined velocity risk (0-1)\n")
cat("   - risk_flag_count: Count of risk flags (0-4)\n\n")

cat("NOTE: Placeholder features require additional data columns:\n")
cat("- customer_id: For grouping transactions by customer\n")
cat("- device_id: For device-based features\n")
cat("- ip_address, ip_country: For geolocation features\n")
cat("- email, email_domain: For email-based features\n")
cat("- billing_address, shipping_address: For address-based features\n")
cat("- card_bin: For BIN-based features\n\n")

sink()

cat(sprintf("✓ Feature documentation saved to: %s\n", feature_doc_path))

# =============================================================================
# Final Summary
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("FEATURE ENGINEERING COMPLETE!\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")
cat(sprintf("Feature-engineered dataset: %s\n", output_path))
cat(sprintf("Total rows: %d\n", nrow(df)))
cat(sprintf("Total columns: %d\n", ncol(df)))
cat(sprintf("New features: %d\n", ncol(df) - 42))
cat(paste0(rep("=", 60), collapse = ""), "\n")

