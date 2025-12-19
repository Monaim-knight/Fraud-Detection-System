# Quick script to get Original Amount Statistics
# Run this in R to get the original statistics for the report

library(readr)
library(dplyr)
library(DescTools)

cat(paste0(rep("=", 60), collapse = ""), "\n")
cat("Getting Original Amount Statistics\n")
cat(paste0(rep("=", 60), collapse = ""), "\n\n")

# Method 1: Try to get from cleaned dataset (Amount_original column)
cleaned_path <- "cnp_dataset/cleaned/creditcard_cleaned.csv"

if (file.exists(cleaned_path)) {
  cat("Method 1: Loading cleaned dataset...\n")
  df_cleaned <- read_csv(cleaned_path, show_col_types = FALSE)
  
  if ("Amount_original" %in% colnames(df_cleaned)) {
    cat("✓ Found Amount_original column!\n\n")
    
    original_stats <- df_cleaned %>%
      summarise(
        mean_amount = mean(Amount_original, na.rm = TRUE),
        median_amount = median(Amount_original, na.rm = TRUE),
        min_amount = min(Amount_original, na.rm = TRUE),
        max_amount = max(Amount_original, na.rm = TRUE),
        q1 = quantile(Amount_original, 0.25, na.rm = TRUE),
        q3 = quantile(Amount_original, 0.75, na.rm = TRUE),
        iqr = q3 - q1,
        skewness = DescTools::Skew(Amount_original, na.rm = TRUE)
      )
    
    cat("ORIGINAL Amount Statistics (from Amount_original column):\n")
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
    
    quit(save = "no")
  } else {
    cat("Amount_original column not found. Trying Method 2...\n\n")
  }
}

# Method 2: Load original CSV file
cat("Method 2: Loading original dataset from source...\n")
dataset_path <- "C:/Users/monai/OneDrive - student.uni-halle.de/Desktop/Billie _ R/creditcard.csv"

if (file.exists(dataset_path)) {
  df_original <- read_csv(dataset_path, show_col_types = FALSE)
  
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
  
  cat("ORIGINAL Amount Statistics (from original CSV file):\n")
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
  
} else {
  cat("ERROR: Original dataset file not found at:", dataset_path, "\n")
  cat("Please check the file path.\n")
}

