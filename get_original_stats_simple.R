# Simple script to get Original Amount Statistics from the original CSV file
# This will definitely work!

library(readr)
library(dplyr)
library(DescTools)

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Getting Original Amount Statistics\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Load the ORIGINAL dataset (before any processing)
dataset_path <- "C:/Users/monai/OneDrive - student.uni-halle.de/Desktop/Billie _ R/creditcard.csv"

cat("Loading original dataset from:", dataset_path, "\n")

if (file.exists(dataset_path)) {
  df_original <- read_csv(dataset_path, show_col_types = FALSE)
  
  cat("✓ Dataset loaded successfully!\n")
  cat(sprintf("Dataset shape: %d rows, %d columns\n\n", nrow(df_original), ncol(df_original)))
  
  # Get original Amount statistics
  original_stats <- df_original %>%
    summarise(
      mean_amount = mean(Amount, na.rm = TRUE),
      median_amount = median(Amount, na.rm = TRUE),
      min_amount = min(Amount, na.rm = TRUE),
      max_amount = max(Amount, na.rm = TRUE),
      q1 = quantile(Amount, 0.25, na.rm = TRUE),
      q3 = quantile(Amount, 0.75, na.rm = TRUE),
      iqr = q3 - q1,
      skewness = DescTools::Skew(Amount, na.rm = TRUE)
    )
  
  cat(paste0(rep("=", 60), collapse = ""), "\n")
  cat("ORIGINAL Amount Statistics:\n")
  cat(paste0(rep("=", 60), collapse = ""), "\n")
  print(original_stats)
  
  cat("\n", paste0(rep("-", 60), collapse = ""), "\n")
  cat("Formatted for Report:\n")
  cat(paste0(rep("-", 60), collapse = ""), "\n")
  cat(sprintf("- Mean Amount: %.2f\n", original_stats$mean_amount))
  cat(sprintf("- Median Amount: %.2f\n", original_stats$median_amount))
  cat(sprintf("- Min Amount: %.2f\n", original_stats$min_amount))
  cat(sprintf("- Max Amount: %.2f\n", original_stats$max_amount))
  cat(sprintf("- Q1 (25th percentile): %.2f\n", original_stats$q1))
  cat(sprintf("- Q3 (75th percentile): %.2f\n", original_stats$q3))
  cat(sprintf("- IQR: %.2f\n", original_stats$iqr))
  cat(sprintf("- Skewness: %.4f\n", original_stats$skewness))
  cat(paste0(rep("=", 60), collapse = ""), "\n")
  
} else {
  cat("ERROR: File not found at:", dataset_path, "\n")
  cat("Please check the file path.\n")
}






