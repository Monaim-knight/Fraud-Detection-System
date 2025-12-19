# =============================================================================
# Apply Labeling Criteria to CNP Dataset
# Step 2: Labeling and Exclusion of Ambiguous Cases
# =============================================================================

# Load required libraries
library(readr)
library(dplyr)
library(lubridate)

# =============================================================================
# Step 1: Load the Cleaned Dataset
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Applying Labeling Criteria to CNP Dataset\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Load the cleaned dataset
cleaned_path <- "cnp_dataset/cleaned/creditcard_cleaned.csv"
original_path <- "C:/Users/monai/OneDrive - student.uni-halle.de/Desktop/Billie _ R/creditcard.csv"

# Try to load cleaned dataset first, otherwise load original
if (file.exists(cleaned_path)) {
  cat("Loading cleaned dataset...\n")
  df <- read_csv(cleaned_path, show_col_types = FALSE)
} else if (file.exists(original_path)) {
  cat("Cleaned dataset not found. Loading original dataset...\n")
  df <- read_csv(original_path, show_col_types = FALSE)
} else {
  stop("Dataset file not found. Please check the file paths.")
}

cat(sprintf("Dataset loaded: %d rows, %d columns\n\n", nrow(df), ncol(df)))

# =============================================================================
# Step 2: Labeling Criteria
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Labeling Criteria:\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Fraud (Class = 1): Confirmed chargebacks or flagged fraudulent transactions\n")
cat("Non-Fraud (Class = 0): Settled transactions with no disputes after 90 days\n")
cat("Ambiguous: Pending investigations (to be excluded)\n\n")

# =============================================================================
# Step 3: Check Current Class Distribution
# =============================================================================

cat("Current Class Distribution:\n")
class_dist <- df %>%
  count(Class) %>%
  mutate(percentage = n / nrow(df) * 100)

print(class_dist)
cat("\n")

# =============================================================================
# Step 4: Identify Ambiguous Cases
# =============================================================================

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Identifying Ambiguous Cases\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")

# Note: The current dataset only has Class = 0 or 1
# In a real scenario, you might have:
# - Class = -1 or NA for ambiguous/pending cases
# - Additional columns indicating investigation status
# - Dispute status columns

# For this dataset, we'll check if there are any ambiguous indicators
# Since the dataset only has 0 and 1, we'll document the labeling criteria
# and create a function for future use

# Check for any missing or unusual Class values
ambiguous_indicators <- df %>%
  filter(is.na(Class) | !Class %in% c(0, 1))

if (nrow(ambiguous_indicators) > 0) {
  cat(sprintf("Found %d ambiguous cases (NA or invalid Class values)\n", nrow(ambiguous_indicators)))
} else {
  cat("No ambiguous cases found in current dataset\n")
  cat("All transactions are clearly labeled as Fraud (1) or Non-Fraud (0)\n")
}

# =============================================================================
# Step 5: Apply Labeling Criteria (Documentation)
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Labeling Criteria Applied:\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")

# Create a labeling summary
labeling_summary <- df %>%
  summarise(
    total_transactions = n(),
    fraud_count = sum(Class == 1, na.rm = TRUE),
    non_fraud_count = sum(Class == 0, na.rm = TRUE),
    ambiguous_count = sum(is.na(Class) | !Class %in% c(0, 1)),
    fraud_percentage = mean(Class == 1, na.rm = TRUE) * 100,
    non_fraud_percentage = mean(Class == 0, na.rm = TRUE) * 100
  )

cat("\nLabeling Summary:\n")
print(labeling_summary)

# =============================================================================
# Step 6: Final Labeled Dataset Distribution
# =============================================================================
# Note: Step 6 (Exclude Ambiguous Cases) is skipped since no ambiguous cases exist
# All transactions are clearly labeled, so we use the full dataset

# Since there are no ambiguous cases, use the full dataset
df_labeled <- df

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Final Labeled Dataset Distribution:\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")

final_dist <- df_labeled %>%
  count(Class) %>%
  mutate(
    label = ifelse(Class == 1, "Fraud", "Non-Fraud"),
    percentage = n / nrow(df_labeled) * 100
  ) %>%
  select(label, Class, n, percentage)

print(final_dist)

# =============================================================================
# Step 7: Save Labeled Dataset
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("Saving Labeled Dataset\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")

# Create output directory
output_dir <- "cnp_dataset/labeled"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Save labeled dataset
output_path <- file.path(output_dir, "creditcard_labeled.csv")
write_csv(df_labeled, output_path)

cat(sprintf("✓ Labeled dataset saved to: %s\n", output_path))
cat(sprintf("  Rows: %d\n", nrow(df_labeled)))
cat(sprintf("  Columns: %d\n", ncol(df_labeled)))

# =============================================================================
# Step 8: Create Labeling Report
# =============================================================================

report_path <- file.path(output_dir, "labeling_report.txt")
sink(report_path)
cat("CNP Dataset Labeling Report\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")
cat("Labeling Criteria:\n")
cat("- Fraud (Class = 1): Confirmed chargebacks or flagged fraudulent transactions\n")
cat("- Non-Fraud (Class = 0): Settled transactions with no disputes after 90 days\n")
cat("- Ambiguous: Pending investigations (excluded)\n\n")
cat("Labeling Summary:\n")
print(labeling_summary)
cat("\nFinal Distribution:\n")
print(final_dist)
cat("\nDataset saved to:", output_path, "\n")
sink()

cat(sprintf("✓ Labeling report saved to: %s\n", report_path))

# =============================================================================
# Final Summary
# =============================================================================

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("LABELING COMPLETE!\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")
cat(sprintf("Labeled dataset: %s\n", output_path))
cat(sprintf("Total rows: %d\n", nrow(df_labeled)))
cat(sprintf("Fraud cases: %d (%.2f%%)\n", 
            sum(df_labeled$Class == 1),
            mean(df_labeled$Class == 1) * 100))
cat(sprintf("Non-Fraud cases: %d (%.2f%%)\n", 
            sum(df_labeled$Class == 0),
            mean(df_labeled$Class == 0) * 100))
cat(paste0(rep("=", 60), collapse = ""), "\n")

