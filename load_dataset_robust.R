# =============================================================================
# Robust Code to Load CNP Dataset in R
# Tries multiple path variations to find the file
# =============================================================================

# Load required library
library(readr)

# Base directory
base_dir <- "C:/Users/monai/OneDrive - student.uni-halle.de/Desktop/Billie _ R"

# Try different possible file names
possible_files <- c(
  file.path(base_dir, "creditcard.csv"),
  file.path(base_dir, "creditcard"),
  file.path(base_dir, "CreditCard.csv"),
  file.path(base_dir, "CREDITCARD.CSV")
)

# Find which file exists
dataset_path <- NULL
for (file_path in possible_files) {
  if (file.exists(file_path)) {
    dataset_path <- file_path
    cat("Found dataset at:", dataset_path, "\n")
    break
  }
}

# If no file found, list files in directory
if (is.null(dataset_path)) {
  cat("Dataset file not found. Listing files in directory:\n")
  if (dir.exists(base_dir)) {
    print(list.files(base_dir))
    cat("\nPlease update the dataset_path variable with the correct file name.\n")
  } else {
    cat("Directory does not exist:", base_dir, "\n")
    cat("Please check the path and update the base_dir variable.\n")
  }
  stop("Dataset file not found. Please check the path.")
}

# Load the dataset
cat("Loading dataset...\n")
df <- read_csv(dataset_path, show_col_types = FALSE)

# Display basic information
cat("\n=== Dataset Loaded Successfully ===\n")
cat("Dimensions:", nrow(df), "rows x", ncol(df), "columns\n")
cat("Column names:", paste(colnames(df), collapse = ", "), "\n")
cat("Memory usage:", format(object.size(df), units = "MB"), "\n")

# Display first few rows
cat("\nFirst 5 rows:\n")
print(head(df, 5))

# Quick summary
cat("\nSummary:\n")
print(summary(df))

# The dataset is now loaded in the variable 'df'
# You can use it for analysis, cleaning, etc.






