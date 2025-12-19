# Export MySQL Data to CSV for Tableau (ARM Windows Compatible)
# This script connects directly to MySQL (no ODBC needed) and exports data for Tableau

# =============================================================================
# CONFIGURATION - EDIT THESE VALUES
# =============================================================================

MYSQL_HOST <- "localhost"
MYSQL_PORT <- 3306
MYSQL_USER <- "root"
MYSQL_PASSWORD <- ""  # Enter your MySQL password here
MYSQL_DATABASE <- "fraud_detection_db"

# Output directory for CSV files
OUTPUT_DIR <- "tableau_exports"

# =============================================================================
# SETUP
# =============================================================================

# Install required packages if needed
required_packages <- c("RMySQL", "DBI", "dplyr")
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) {
  cat("Installing required packages...\n")
  install.packages(new_packages)
}

library(RMySQL)
library(DBI)
library(dplyr)

# Create output directory
if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR)
  cat("Created output directory:", OUTPUT_DIR, "\n")
}

# =============================================================================
# CONNECT TO MYSQL
# =============================================================================

cat("Connecting to MySQL...\n")

tryCatch({
  # Create connection
  con <- dbConnect(
    MySQL(),
    host = MYSQL_HOST,
    port = MYSQL_PORT,
    user = MYSQL_USER,
    password = MYSQL_PASSWORD,
    dbname = MYSQL_DATABASE
  )
  
  cat("✓ Connected to MySQL successfully!\n\n")
  
  # =============================================================================
  # EXPORT TABLES AND VIEWS
  # =============================================================================
  
  # Get list of all tables
  cat("Getting list of tables and views...\n")
  tables <- dbListTables(con)
  cat("Found", length(tables), "tables/views\n\n")
  
  # Export each table/view
  exported_files <- c()
  
  for (table_name in tables) {
    cat("Exporting:", table_name, "...")
    
    tryCatch({
      # Read data from table/view
      data <- dbReadTable(con, table_name)
      
      # Create filename (replace dots with underscores for CSV compatibility)
      filename <- gsub("\\.", "_", table_name)
      filepath <- file.path(OUTPUT_DIR, paste0(filename, ".csv"))
      
      # Write to CSV
      write.csv(data, filepath, row.names = FALSE, na = "")
      
      cat(" ✓ (", nrow(data), "rows,", ncol(data), "columns)\n")
      exported_files <- c(exported_files, filepath)
      
    }, error = function(e) {
      cat(" ✗ Error:", e$message, "\n")
    })
  }
  
  # =============================================================================
  # EXPORT SPECIFIC VIEWS FOR TABLEAU (if they exist)
  # =============================================================================
  
  cat("\n--- Exporting Tableau-specific views ---\n")
  
  # List of views that might exist (from prepare_tableau_data_mysql.sql)
  tableau_views <- c(
    "tableau_fraud_data",
    "tableau_fraud_summary",
    "tableau_fraud_trends",
    "tableau_customer_analysis",
    "tableau_transaction_details"
  )
  
  for (view_name in tableau_views) {
    if (view_name %in% tables) {
      cat("Exporting view:", view_name, "...")
      
      tryCatch({
        data <- dbReadTable(con, view_name)
        filename <- gsub("\\.", "_", view_name)
        filepath <- file.path(OUTPUT_DIR, paste0(filename, ".csv"))
        write.csv(data, filepath, row.names = FALSE, na = "")
        cat(" ✓ (", nrow(data), "rows)\n")
        exported_files <- c(exported_files, filepath)
      }, error = function(e) {
        cat(" ✗ Error:", e$message, "\n")
      })
    }
  }
  
  # =============================================================================
  # SUMMARY
  # =============================================================================
  
  cat("\n" , rep("=", 60), "\n", sep = "")
  cat("EXPORT COMPLETE!\n")
  cat(rep("=", 60), "\n\n")
  cat("Exported", length(exported_files), "files to:", OUTPUT_DIR, "\n\n")
  cat("Files exported:\n")
  for (file in exported_files) {
    file_size <- file.info(file)$size / 1024  # Size in KB
    cat("  -", basename(file), sprintf("(%.2f KB)\n", file_size))
  }
  
  cat("\nNext steps:\n")
  cat("1. Open Tableau Desktop\n")
  cat("2. Connect to 'Text file' or 'Microsoft Excel'\n")
  cat("3. Select one of the CSV files from:", OUTPUT_DIR, "\n")
  cat("4. Build your dashboard!\n\n")
  
  # Close connection
  dbDisconnect(con)
  cat("✓ MySQL connection closed\n")
  
}, error = function(e) {
  cat("\n✗ ERROR: Could not connect to MySQL\n")
  cat("Error message:", e$message, "\n\n")
  cat("Please check:\n")
  cat("  - MySQL service is running\n")
  cat("  - Host, port, username, password are correct\n")
  cat("  - Database name is correct\n")
  cat("  - RMySQL package is installed\n")
})



