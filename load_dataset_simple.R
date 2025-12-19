# =============================================================================
# Simple Code to Load CNP Dataset in R
# =============================================================================

# Load required library
library(readr)

# Set the dataset path (update if needed)
dataset_path <- "C:/Users/monai/OneDrive - student.uni-halle.de/Desktop/Billie _ R/creditcard.csv"

# If the above doesn't work, try these alternatives:
# dataset_path <- "C:/Users/monai/OneDrive - student.uni-halle.de/Desktop/Billie _ R/creditcard"
# dataset_path <- file.path("C:", "Users", "monai", "OneDrive - student.uni-halle.de", "Desktop", "Billie _ R", "creditcard.csv")

# Load the dataset
df <- read_csv(dataset_path, show_col_types = FALSE)

# View the dataset
View(df)           # Opens in RStudio viewer
head(df)            # First 6 rows
str(df)             # Structure of the dataset
summary(df)         # Summary statistics






