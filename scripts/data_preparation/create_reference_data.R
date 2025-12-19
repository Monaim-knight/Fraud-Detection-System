# =============================================================================
# Create Reference Data Files for Placeholder Features
# Generates lists of disposable email domains, prepaid BINs, and high-risk countries
# =============================================================================

# Create data directory
data_dir <- "data"
if (!dir.exists(data_dir)) {
  dir.create(data_dir, recursive = TRUE)
}

cat("Creating reference data files...\n\n")

# =============================================================================
# 1. Disposable Email Domains
# =============================================================================

disposable_domains <- c(
  # Common disposable email services
  "tempmail.com", "throwaway.com", "guerrillamail.com",
  "10minutemail.com", "mailinator.com", "trashmail.com",
  "temp-mail.org", "getnada.com", "mohmal.com",
  "fakeinbox.com", "yopmail.com", "sharklasers.com",
  "maildrop.cc", "mintemail.com", "getairmail.com",
  "dispostable.com", "meltmail.com", "spamgourmet.com",
  "mailcatch.com", "spamhole.com", "spamex.com",
  "spambox.us", "spamfree24.org", "spamfree24.de",
  "spamfree24.eu", "spamfree24.net", "spamfree24.com",
  "spamgourmet.com", "spamhole.com", "spamex.com"
)

writeLines(disposable_domains, file.path(data_dir, "disposable_email_domains.txt"))
cat(sprintf("✓ Created disposable_email_domains.txt (%d domains)\n", length(disposable_domains)))

# =============================================================================
# 2. Prepaid Card BINs
# =============================================================================

# Common prepaid card BIN ranges (first 6 digits)
# Note: These are examples - in production, use a real BIN database
prepaid_bins <- c(
  # Visa Prepaid
  "411111", "411112", "411113", "411114", "411115",
  "422222", "422223", "422224", "422225",
  "433333", "433334", "433335",
  "444444", "444445", "444446",
  "455555", "455556",
  # Mastercard Prepaid
  "510000", "510001", "510002",
  "520000", "520001",
  "530000", "530001",
  "540000", "540001",
  "550000", "550001",
  # Additional prepaid ranges
  "400000", "400001", "400002",
  "401000", "401001",
  "402000", "402001",
  "403000", "403001",
  "404000", "404001"
)

writeLines(prepaid_bins, file.path(data_dir, "prepaid_bin_list.txt"))
cat(sprintf("✓ Created prepaid_bin_list.txt (%d BINs)\n", length(prepaid_bins)))

# =============================================================================
# 3. High-Risk Countries
# =============================================================================

# High-risk countries based on fraud statistics
# Note: This is a simplified list - in production, use your own fraud data
# to determine high-risk countries
high_risk_countries <- c(
  # Placeholder codes (replace with actual high-risk country codes)
  # These should be based on your actual fraud data
  "XX", "YY", "ZZ", "AA", "BB"
)

# Alternative: Use actual country codes if you have fraud statistics
# Example (uncomment and modify based on your data):
# high_risk_countries <- c(
#   "NG", "GH", "KE", "ZM", "ZW",  # Example African countries
#   "PK", "BD", "LK",              # Example Asian countries
#   "VE", "CO", "PE"               # Example Latin American countries
# )

writeLines(high_risk_countries, file.path(data_dir, "high_risk_countries.txt"))
cat(sprintf("✓ Created high_risk_countries.txt (%d countries)\n", length(high_risk_countries)))

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Reference data files created successfully!\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")
cat(sprintf("\nFiles created in: %s/\n", data_dir))
cat("  - disposable_email_domains.txt\n")
cat("  - prepaid_bin_list.txt\n")
cat("  - high_risk_countries.txt\n\n")
cat("Note: Update high_risk_countries.txt with actual high-risk country codes\n")
cat("      based on your fraud statistics.\n")






