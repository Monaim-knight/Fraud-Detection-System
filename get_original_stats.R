# Quick script to get original Amount statistics
# IMPORTANT: Load the ORIGINAL dataset BEFORE any winsorization
# This script loads a fresh copy of the dataset

library(readr)
library(dplyr)
library(DescTools)

# Load the ORIGINAL dataset (fresh copy, before any processing)
dataset_path <- "C:/Users/monai/OneDrive - student.uni-halle.de/Desktop/Billie _ R/creditcard.csv"
df_original <- read_csv(dataset_path, show_col_types = FALSE)

cat("Loading ORIGINAL dataset (before winsorization)...\n")
cat(sprintf("Dataset shape: %d rows, %d columns\n\n", nrow(df_original), ncol(df_original)))

# Get original Amount statistics
amount_col <- "Amount"

cat("Calculating ORIGINAL Amount statistics...\n\n")

original_stats <- df_original %>%
  summarise(
    mean_amount = mean(!!sym(amount_col), na.rm = TRUE),
    median_amount = median(!!sym(amount_col), na.rm = TRUE),
    min_amount = min(!!sym(amount_col), na.rm = TRUE),
    max_amount = max(!!sym(amount_col), na.rm = TRUE),
    q1 = quantile(!!sym(amount_col), 0.25, na.rm = TRUE),
    q3 = quantile(!!sym(amount_col), 0.75, na.rm = TRUE),
    iqr = q3 - q1,
    skewness = DescTools::Skew(!!sym(amount_col), na.rm = TRUE)
  )

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("ORIGINAL Amount Statistics (BEFORE Winsorization):\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")
print(original_stats)

cat("\n", paste0(rep("-", 60), collapse = ""), "\n")
cat("Formatted for report:\n")
cat(paste0(rep("-", 60), collapse = ""), "\n")
cat(sprintf("- Mean Amount: %.2f\n", original_stats$mean_amount))
cat(sprintf("- Median Amount: %.2f\n", original_stats$median_amount))
cat(sprintf("- Min Amount: %.2f\n", original_stats$min_amount))
cat(sprintf("- Max Amount: %.2f\n", original_stats$max_amount))
cat(sprintf("- Q1 (25th percentile): %.2f\n", original_stats$q1))
cat(sprintf("- Q3 (75th percentile): %.2f\n", original_stats$q3))
cat(sprintf("- IQR: %.2f\n", original_stats$iqr))
cat(sprintf("- Skewness: %.4f\n", original_stats$skewness))

cat("\n", paste0(rep("=", 60), collapse = ""), "\n")
cat("NOTE: These are the ORIGINAL values before winsorization.\n")
cat("Compare with winsorized stats to see the improvement.\n")
cat(paste0(rep("=", 60), collapse = ""), "\n")

