# =============================================================================
# Implementation Script for Placeholder Features
# Use this script once you have collected the required data
# =============================================================================

# Load required libraries
library(readr)
library(dplyr)
library(tidyr)
library(stringr)

# =============================================================================
# Step 1: Load Feature-Engineered Dataset
# =============================================================================

cat("Loading dataset...\n")
# Try synthetic dataset first, then fall back to feature-engineered dataset
if (file.exists("cnp_dataset/synthetic/creditcard_synthetic.csv")) {
  cat("Using synthetic dataset...\n")
  df <- read_csv("cnp_dataset/synthetic/creditcard_synthetic.csv", 
                 show_col_types = FALSE)
} else if (file.exists("cnp_dataset/feature_engineered/creditcard_features.csv")) {
  cat("Using feature-engineered dataset...\n")
  df <- read_csv("cnp_dataset/feature_engineered/creditcard_features.csv", 
                 show_col_types = FALSE)
} else {
  stop("No dataset found. Please generate synthetic dataset or run feature engineering first.")
}

cat(sprintf("Dataset loaded: %d rows, %d columns\n\n", nrow(df), ncol(df)))

# =============================================================================
# Step 2: Load Additional Data Files
# =============================================================================

# Load reference lists (create these files with your data)
# disposable_email_domains.txt - list of disposable email domains
# prepaid_bin_list.txt - list of prepaid card BINs
# high_risk_countries.txt - list of high-risk country codes

disposable_domains <- if (file.exists("data/disposable_email_domains.txt")) {
  readLines("data/disposable_email_domains.txt")
} else {
  character(0)
}

prepaid_bins <- if (file.exists("data/prepaid_bin_list.txt")) {
  readLines("data/prepaid_bin_list.txt")
} else {
  character(0)
}

high_risk_countries <- if (file.exists("data/high_risk_countries.txt")) {
  readLines("data/high_risk_countries.txt")
} else {
  character(0)
}

# Free email domains (common list)
free_email_domains <- c(
  "gmail.com", "yahoo.com", "hotmail.com", "outlook.com", 
  "aol.com", "icloud.com", "protonmail.com", "mail.com",
  "yahoo.co.uk", "live.com", "msn.com", "ymail.com"
)

# =============================================================================
# Step 3: Implement Identity Consistency Features
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Implementing Identity Consistency Features\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Check if required columns exist
required_cols_identity <- c("customer_id", "device_id", "ip_address", 
                            "ip_country", "billing_country", "email")

missing_cols <- setdiff(required_cols_identity, colnames(df))
if (length(missing_cols) > 0) {
  cat("⚠ Missing columns for identity features:", paste(missing_cols, collapse = ", "), "\n")
  cat("Skipping identity consistency features.\n\n")
} else {
  # 3.1 device_reuse_count
  cat("Calculating device_reuse_count...\n")
  df <- df %>%
    group_by(device_id) %>%
    mutate(device_reuse_count = n_distinct(customer_id) - 1) %>%
    ungroup()
  
  # 3.2 ip_geo_mismatch
  cat("Calculating ip_geo_mismatch...\n")
  df <- df %>%
    mutate(
      ip_geo_mismatch = ifelse(ip_country != billing_country, 1, 0)
    )
  
  # 3.3 email_domain_risk
  cat("Calculating email_domain_risk...\n")
  df <- df %>%
    mutate(
      email_domain = str_extract(email, "@(.+)$") %>% str_remove("@"),
      email_domain_risk = case_when(
        email_domain %in% disposable_domains ~ 3,
        email_domain %in% free_email_domains ~ 2,
        str_detect(email_domain, "\\.(edu|gov|org)$") ~ 0,
        TRUE ~ 1
      )
    )
  
  cat("✓ Identity consistency features implemented\n\n")
}

# =============================================================================
# Step 4: Implement Graph Features
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Implementing Graph Features\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

required_cols_graph <- c("customer_id", "device_id", "billing_address")

missing_cols <- setdiff(required_cols_graph, colnames(df))
if (length(missing_cols) > 0) {
  cat("⚠ Missing columns for graph features:", paste(missing_cols, collapse = ", "), "\n")
  cat("Skipping graph features.\n\n")
} else {
  # Normalize addresses function
  normalize_address <- function(addr) {
    addr %>%
      tolower() %>%
      str_remove_all("[^a-z0-9\\s]") %>%
      str_squish()
  }
  
  # 4.1 shared_device_count
  cat("Calculating shared_device_count...\n")
  df <- df %>%
    group_by(device_id) %>%
    mutate(shared_device_count = n_distinct(customer_id)) %>%
    ungroup()
  
  # 4.2 shared_address_count
  cat("Calculating shared_address_count...\n")
  df <- df %>%
    mutate(billing_address_normalized = normalize_address(billing_address)) %>%
    group_by(billing_address_normalized) %>%
    mutate(shared_address_count = n_distinct(customer_id)) %>%
    ungroup()
  
  # 4.3 device_address_network_size (requires igraph)
  if (requireNamespace("igraph", quietly = TRUE)) {
    cat("Calculating device_address_network_size...\n")
    library(igraph)
    
    # Build graph edges
    edges <- df %>%
      select(customer_id, device_id, billing_address_normalized) %>%
      gather(key = "entity_type", value = "entity_id", -customer_id) %>%
      filter(!is.na(entity_id)) %>%
      distinct()
    
    # Build graph
    g <- graph_from_data_frame(edges, directed = FALSE)
    components_result <- components(g)
    
    # Map component sizes
    df <- df %>%
      mutate(
        customer_component = components_result$membership[as.character(customer_id)],
        device_address_network_size = ifelse(
          !is.na(customer_component),
          components_result$csize[customer_component],
          0
        )
      )
    
    cat("✓ Graph features implemented\n\n")
  } else {
    cat("⚠ igraph package not installed. Skipping device_address_network_size.\n")
    cat("Install with: install.packages('igraph')\n\n")
  }
}

# =============================================================================
# Step 5: Implement Risk Flags
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Implementing Risk Flags\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# 5.1 prepaid_bin_flag
if ("card_bin" %in% colnames(df) || "card_number" %in% colnames(df)) {
  cat("Calculating prepaid_bin_flag...\n")
  df <- df %>%
    mutate(
      card_bin = ifelse(
        "card_bin" %in% colnames(df),
        card_bin,
        substr(card_number, 1, 6)
      ),
      prepaid_bin_flag = ifelse(card_bin %in% prepaid_bins, 1, 0)
    )
  cat("✓ prepaid_bin_flag implemented\n\n")
} else {
  cat("⚠ card_bin or card_number not available. Skipping prepaid_bin_flag.\n\n")
}

# 5.2 disposable_email_flag
if ("email" %in% colnames(df)) {
  cat("Calculating disposable_email_flag...\n")
  df <- df %>%
    mutate(
      email_domain = ifelse(
        "email_domain" %in% colnames(df),
        email_domain,
        str_extract(email, "@(.+)$") %>% str_remove("@")
      ),
      disposable_email_flag = ifelse(email_domain %in% disposable_domains, 1, 0)
    )
  cat("✓ disposable_email_flag implemented\n\n")
} else {
  cat("⚠ email not available. Skipping disposable_email_flag.\n\n")
}

# 5.3 high_risk_geo_flag
if ("ip_country" %in% colnames(df)) {
  cat("Calculating high_risk_geo_flag...\n")
  df <- df %>%
    mutate(
      high_risk_geo_flag = ifelse(ip_country %in% high_risk_countries, 1, 0)
    )
  cat("✓ high_risk_geo_flag implemented\n\n")
} else {
  cat("⚠ ip_country not available. Skipping high_risk_geo_flag.\n\n")
}

# =============================================================================
# Step 6: Create Missing Risk Flags (if needed) and Update Risk Flag Count
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Step 6: Creating Missing Risk Flags and Updating Risk Flag Count\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# First, ensure all flags are initialized (set to 0 if they don't exist)
required_flags <- c("high_amount_flag", "unusual_time_flag", "weekend_flag", 
                    "rapid_transaction_flag", "prepaid_bin_flag", 
                    "disposable_email_flag", "high_risk_geo_flag")

cat("Step 6.1: Initializing all risk flags...\n")
for (flag in required_flags) {
  if (!flag %in% colnames(df)) {
    df[[flag]] <- 0
    cat(sprintf("  ✓ %s: initialized to 0\n", flag))
  } else {
    cat(sprintf("  ✓ %s: already exists\n", flag))
  }
}

# Verify initialization worked
cat("\nVerifying initialization...\n")
cat("Current flags in dataset:", paste(intersect(required_flags, colnames(df)), collapse = ", "), "\n")

# Now create/update flags based on available data
cat("\nStep 6.2: Creating risk flags from available data...\n")

# High amount flag
if ("Amount" %in% colnames(df)) {
  cat("  - Creating high_amount_flag...\n")
  df <- df %>%
    mutate(
      high_amount_flag = ifelse(Amount > quantile(Amount, 0.95, na.rm = TRUE), 1, 0)
    )
} else {
  cat("  - ⚠ Amount column not found. high_amount_flag remains 0.\n")
}

# Unusual time flag
if ("hour_of_day" %in% colnames(df)) {
  cat("  - Creating unusual_time_flag...\n")
  df <- df %>%
    mutate(
      unusual_time_flag = ifelse(hour_of_day >= 2 & hour_of_day < 5, 1, 0)
    )
} else {
  cat("  - ⚠ hour_of_day column not found. unusual_time_flag remains 0.\n")
}

# Weekend flag
if ("is_weekend" %in% colnames(df)) {
  cat("  - Creating weekend_flag...\n")
  df <- df %>%
    mutate(
      weekend_flag = ifelse(is_weekend == TRUE, 1, 0)
    )
} else {
  cat("  - ⚠ is_weekend column not found. weekend_flag remains 0.\n")
}

# Rapid transaction flag
if ("time_since_previous" %in% colnames(df)) {
  cat("  - Creating rapid_transaction_flag...\n")
  df <- df %>%
    mutate(
      rapid_transaction_flag = ifelse(time_since_previous < 60, 1, 0)
    )
} else {
  cat("  - ⚠ time_since_previous column not found. rapid_transaction_flag remains 0.\n")
}

# Verify all flags exist after creation
cat("\nStep 6.3: Verifying all flags exist...\n")
missing_flags <- setdiff(required_flags, colnames(df))
if (length(missing_flags) > 0) {
  cat("⚠ Warning: Some flags still missing. Initializing them...\n")
  for (flag in missing_flags) {
    df[[flag]] <- 0
    cat(sprintf("  ✓ %s: initialized to 0\n", flag))
  }
}

# Final check - all flags must exist
final_check <- setdiff(required_flags, colnames(df))
if (length(final_check) > 0) {
  cat("❌ ERROR: Could not create flags:", paste(final_check, collapse = ", "), "\n")
  cat("Available columns:", paste(colnames(df), collapse = ", "), "\n")
  stop("Cannot proceed without all risk flags")
} else {
  cat("✓ All 7 risk flags are present:\n")
  for (flag in required_flags) {
    cat(sprintf("  - %s: exists (range: %d to %d)\n", flag, min(df[[flag]]), max(df[[flag]])))
  }
}

# Update risk_flag_count to include all flags
cat("\nStep 6.4: Calculating risk_flag_count...\n")
# Use base R assignment to ensure it works (NOT mutate)
if (!all(required_flags %in% colnames(df))) {
  stop("Cannot calculate risk_flag_count: missing required flags")
}

df$risk_flag_count <- (
  df$high_amount_flag + 
  df$unusual_time_flag + 
  df$weekend_flag + 
  df$rapid_transaction_flag +
  df$prepaid_bin_flag +
  df$disposable_email_flag +
  df$high_risk_geo_flag
)

cat("✓ risk_flag_count calculated successfully\n")
cat(sprintf("  Range: %d to %d\n", min(df$risk_flag_count), max(df$risk_flag_count)))
cat(sprintf("  Mean: %.2f\n", mean(df$risk_flag_count)))

cat("✓ risk_flag_count updated to include all 7 risk flags\n\n")

# =============================================================================
# Step 7: Save Updated Dataset
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Saving Updated Dataset\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Create output directory if it doesn't exist
output_dir <- "cnp_dataset/feature_engineered"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
  cat(sprintf("✓ Created output directory: %s\n", output_dir))
}

output_path <- file.path(output_dir, "creditcard_features_complete.csv")
write_csv(df, output_path)

cat(sprintf("✓ Updated dataset saved to: %s\n", output_path))
cat(sprintf("  Rows: %d\n", nrow(df)))
cat(sprintf("  Columns: %d\n", ncol(df)))

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("PLACEHOLDER FEATURES IMPLEMENTATION COMPLETE!\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")

