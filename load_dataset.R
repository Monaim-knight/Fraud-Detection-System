# =============================================================================
# Load CNP Dataset in R
# Credit Card Fraud Detection Dataset
# =============================================================================

# Load required library for fast CSV reading
library(readr)

# =============================================================================
# Option 1: Load from the new location you specified
# =============================================================================

# Set the dataset path
dataset_path <- "C:/Users/monai/OneDrive - student.uni-halle.de/Desktop/Billie _ R/creditcard.csv"

# Alternative: If the file doesn't have .csv extension, try:
# dataset_path <- "C:/Users/monai/OneDrive - student.uni-halle.de/Desktop/Billie _ R/creditcard"

# Load the dataset
cat("Loading dataset from:", dataset_path, "\n")

# Try to load the dataset
df <- read_csv(dataset_path, show_col_types = FALSE)

# Display dataset information
cat("\nDataset loaded successfully!\n")
cat("Dataset dimensions:", nrow(df), "rows,", ncol(df), "columns\n")
cat("Column names:", paste(colnames(df), collapse = ", "), "\n")
cat("Memory usage:", format(object.size(df), units = "MB"), "\n")

# Display first few rows
cat("\nFirst 5 rows:\n")
print(head(df, 5))

# Display summary statistics
cat("\nSummary statistics:\n")
print(summary(df))

# Check for missing values
cat("\nMissing values per column:\n")
missing_counts <- sapply(df, function(x) sum(is.na(x)))
print(missing_counts[missing_counts > 0])
if (sum(missing_counts) == 0) {
  cat("No missing values found!\n")
}

# Display fraud distribution
if ("Class" %in% colnames(df)) {
  cat("\nFraud distribution (Class column):\n")
  print(table(df$Class))
  cat("Fraud percentage:", round(mean(df$Class) * 100, 2), "%\n")
}

# =============================================================================
# Option 2: Load using base R (alternative method)
# =============================================================================

# Uncomment below if readr doesn't work:
# df <- read.csv(dataset_path, stringsAsFactors = FALSE)

# =============================================================================
# Option 3: Load with relative path (if working directory is set correctly)
# =============================================================================

# If you set your working directory to the folder containing the dataset:
# setwd("C:/Users/monai/OneDrive - student.uni-halle.de/Desktop/Billie _ R")
# df <- read_csv("creditcard.csv", show_col_types = FALSE)






