###############################################################################
# Export MySQL Data for Tableau (ARM‑friendly, no ODBC)
# - Connects directly to MySQL using DBI + RMariaDB
# - Designed for this project: `fraud_detection_db`
# - Exports key tables/views to CSV so Tableau can read them
###############################################################################

cat(paste0("\n", paste(rep("=", 70), collapse = ""), "\n"))
cat("MySQL → Tableau Export Script (no ODBC, ARM‑friendly)\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

###############################################################################
# 1. Configuration  (EDIT THESE VALUES IF NEEDED)
###############################################################################

# MySQL connection settings
MYSQL_HOST <- "localhost"
MYSQL_PORT <- 3306
MYSQL_USER <- "root"
MYSQL_PASSWORD <- "070707"    # <<<<<<<<<< YOUR MySQL password
MYSQL_DB <- "fraud_detection_db"

# Folder where CSVs for Tableau will be written
OUTPUT_DIR <- "tableau_exports"

# Optional: limit rows exported from very large tables (NULL = all rows)
MAX_ROWS <- NULL  # e.g. 50000 for testing

###############################################################################
# 2. Packages
###############################################################################

required_packages <- c("DBI", "RMariaDB")
new_packages <- required_packages[!(required_packages %in% rownames(installed.packages()))]

if (length(new_packages) > 0) {
  cat("Installing required packages:", paste(new_packages, collapse = ", "), "...\n")
  install.packages(new_packages)
}

library(DBI)
library(RMariaDB)

###############################################################################
# 3. Helpers
###############################################################################

safe_read_table <- function(con, name, max_rows = NULL) {
  # Prefer dbReadTable, but fall back to SELECT * for views if needed
  qry <- paste0("SELECT * FROM `", name, "`")
  if (!is.null(max_rows)) {
    qry <- paste0(qry, " LIMIT ", as.integer(max_rows))
  }
  dbGetQuery(con, qry)
}

export_table_to_csv <- function(con, name, out_dir, max_rows = NULL) {
  cat("Exporting:", name, "...")
  tryCatch({
    df <- safe_read_table(con, name, max_rows)
    # Replace dots with underscores for safe filenames
    fname <- gsub("\\\\.", "_", name)
    path <- file.path(out_dir, paste0(fname, ".csv"))
    write.csv(df, path, row.names = FALSE, na = "")
    cat("  ✓", nrow(df), "rows,", ncol(df), "columns →", path, "\n")
    return(invisible(TRUE))
  }, error = function(e) {
    cat("  ✗ failed:", e$message, "\n")
    return(invisible(FALSE))
  })
}

###############################################################################
# 4. Prepare output directory
###############################################################################

if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR, recursive = TRUE)
  cat("Created output directory:", OUTPUT_DIR, "\n\n")
} else {
  cat("Using existing output directory:", OUTPUT_DIR, "\n\n")
}

###############################################################################
# 5. Connect to MySQL
###############################################################################

cat("Connecting to MySQL at ", MYSQL_HOST, ":", MYSQL_PORT,
    " (DB: ", MYSQL_DB, ")...\n", sep = "")

con <- NULL
last_error <- NULL

# Try connection method 1: standard connection
result1 <- tryCatch({
  con <- dbConnect(
    RMariaDB::MariaDB(),
    host     = MYSQL_HOST,
    port     = MYSQL_PORT,
    user     = MYSQL_USER,
    password = MYSQL_PASSWORD,
    dbname   = MYSQL_DB
  )
  if (!is.null(con) && dbIsValid(con)) {
    cat("✓ Connected successfully!\n\n")
    TRUE
  } else {
    FALSE
  }
}, error = function(e) {
  last_error <<- e$message
  FALSE
})

# Try connection method 2: alternative parameter names
if (is.null(con) || !dbIsValid(con)) {
  result2 <- tryCatch({
    con <- dbConnect(
      drv = RMariaDB::MariaDB(),
      host = MYSQL_HOST,
      port = MYSQL_PORT,
      username = MYSQL_USER,
      password = MYSQL_PASSWORD,
      dbname = MYSQL_DB
    )
    if (!is.null(con) && dbIsValid(con)) {
      cat("✓ Connected successfully (method 2)!\n\n")
      TRUE
    } else {
      FALSE
    }
  }, error = function(e) {
    last_error <<- e$message
    FALSE
  })
}

# Try connection method 3: connect without database first, then select
if (is.null(con) || !dbIsValid(con)) {
  result3 <- tryCatch({
    con <- dbConnect(
      RMariaDB::MariaDB(),
      host     = MYSQL_HOST,
      port     = MYSQL_PORT,
      user     = MYSQL_USER,
      password = MYSQL_PASSWORD
    )
    if (!is.null(con) && dbIsValid(con)) {
      dbExecute(con, paste0("USE `", MYSQL_DB, "`"))
      cat("✓ Connected successfully (method 3)!\n\n")
      TRUE
    } else {
      FALSE
    }
  }, error = function(e) {
    last_error <<- e$message
    FALSE
  })
}

if (is.null(con) || !dbIsValid(con)) {
  cat("\n✗ ERROR: Could not connect to MySQL\n")
  if (!is.null(last_error)) {
    cat("Error details:", last_error, "\n\n")
  }
  cat("Please check:\n")
  cat("  1. MySQL service is running\n")
  cat("     - Press Windows Key + R, type: services.msc\n")
  cat("     - Look for 'MySQL' service, should be 'Running'\n")
  cat("  2. Host/port are correct (", MYSQL_HOST, ":", MYSQL_PORT, ")\n", sep = "")
  cat("  3. Username/password are correct (user: ", MYSQL_USER, ")\n", sep = "")
  cat("  4. Database exists (", MYSQL_DB, ")\n", sep = "")
  cat("\nTo diagnose the issue, run: source('test_mysql_connection.R')\n\n")
  stop("MySQL connection failed – see messages above.")
}

cat("✓ Connected successfully!\n\n")

###############################################################################
# 6. Discover tables and views
###############################################################################

cat("Fetching list of tables/views in database...\n")
all_objects <- dbGetQuery(con, "SHOW FULL TABLES")
names(all_objects) <- c("name", "type")

cat("Found", nrow(all_objects), "tables/views.\n\n")

###############################################################################
# 7. Define key tables/views for this project
###############################################################################

# Always export these if present
priority_objects <- c(
  "transactions",                # main fact table from prepare_mysql_dataset.R
  "tableau_fraud_data",
  "tableau_fraud_summary",
  "tableau_fraud_trends",
  "tableau_customer_analysis",
  "tableau_transaction_details"
)

existing_priority <- intersect(priority_objects, all_objects$name)
other_objects <- setdiff(all_objects$name, existing_priority)

cat("Priority objects that will be exported if found:\n")
if (length(existing_priority) == 0) {
  cat("  (none found – make sure views script has been run.)\n\n")
} else {
  for (nm in existing_priority) cat("  -", nm, "\n")
  cat("\n")
}

###############################################################################
# 8. Export priority objects
###############################################################################

exported <- character(0)

if (length(existing_priority) > 0) {
  cat("Exporting priority tables/views...\n")
  for (nm in existing_priority) {
    ok <- export_table_to_csv(con, nm, OUTPUT_DIR, MAX_ROWS)
    if (ok) exported <- c(exported, nm)
  }
  cat("\n")
}

###############################################################################
# 9. (Optional) Export all remaining tables/views
###############################################################################

if (length(other_objects) > 0) {
  cat("Export remaining tables/views as well? (y/n) ")
  ans <- tryCatch(tolower(scan("", what = "character", nmax = 1, quiet = TRUE)),
                  error = function(e) "n")
  if (length(ans) == 0) ans <- "n"
  if (ans == "y") {
    cat("\nExporting remaining objects...\n")
    for (nm in other_objects) {
      ok <- export_table_to_csv(con, nm, OUTPUT_DIR, MAX_ROWS)
      if (ok) exported <- c(exported, nm)
    }
    cat("\n")
  } else {
    cat("Skipping remaining objects.\n\n")
  }
}

###############################################################################
# 10. Summary and next steps
###############################################################################

cat(paste(rep("=", 70), collapse = ""), "\n", sep = "")
cat("EXPORT COMPLETE\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n", sep = "")

cat("Exported ", length(exported), " objects to folder: ", OUTPUT_DIR, "\n", sep = "")
if (length(exported) > 0) {
  cat("Objects exported:\n")
  for (nm in exported) cat("  -", nm, "\n")
  cat("\n")
}

cat("Next steps in Tableau:\n")
cat("  1. Open Tableau Desktop.\n")
cat("  2. Choose 'Text file' as data source.\n")
cat("  3. Browse to the '", OUTPUT_DIR, "' folder in this project.\n", sep = "")
cat("  4. Select one of the CSV files (e.g., 'tableau_fraud_data.csv').\n")
cat("  5. Build your fraud detection dashboard.\n\n")

if (!is.null(con) && dbIsValid(con)) {
  dbDisconnect(con)
  cat("✓ MySQL connection closed.\n")
}

cat("\nAll done.\n")


