# MySQL Connection Diagnostic Script
# This will help identify why the connection is failing

cat("\n", paste(rep("=", 70), collapse = ""), "\n")
cat("MySQL Connection Diagnostic\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Configuration
MYSQL_HOST <- "localhost"
MYSQL_PORT <- 3306
MYSQL_USER <- "root"
MYSQL_PASSWORD <- "070707"
MYSQL_DB <- "fraud_detection_db"

# Install packages if needed
required_packages <- c("DBI", "RMariaDB")
new_packages <- required_packages[!(required_packages %in% rownames(installed.packages()))]

if (length(new_packages) > 0) {
  cat("Installing required packages:", paste(new_packages, collapse = ", "), "...\n")
  install.packages(new_packages)
}

library(DBI)
library(RMariaDB)

cat("Testing MySQL connection...\n\n")

# Test 1: Try connecting without specifying database first
cat("Test 1: Connecting to MySQL server (no database)...\n")
con1 <- NULL
result1 <- tryCatch({
  con1 <- dbConnect(
    RMariaDB::MariaDB(),
    host     = MYSQL_HOST,
    port     = MYSQL_PORT,
    user     = MYSQL_USER,
    password = MYSQL_PASSWORD
  )
  if (!is.null(con1) && dbIsValid(con1)) {
    cat("✓ Successfully connected to MySQL server!\n")
    
    # List databases
    cat("\nAvailable databases:\n")
    dbs <- dbGetQuery(con1, "SHOW DATABASES")
    print(dbs)
    
    # Check if our database exists
    if (MYSQL_DB %in% dbs$Database) {
      cat("\n✓ Database '", MYSQL_DB, "' exists!\n", sep = "")
    } else {
      cat("\n✗ Database '", MYSQL_DB, "' NOT found!\n", sep = "")
      cat("Available databases:\n")
      print(dbs$Database)
    }
    
    dbDisconnect(con1)
    TRUE
  } else {
    FALSE
  }
}, error = function(e) {
  cat("✗ Failed to connect to MySQL server\n")
  cat("Error:", e$message, "\n\n")
  cat("Possible issues:\n")
  cat("  1. MySQL service is not running\n")
  cat("  2. Wrong host/port (", MYSQL_HOST, ":", MYSQL_PORT, ")\n", sep = "")
  cat("  3. Wrong username/password\n")
  cat("  4. MySQL not installed\n\n")
  FALSE
})

# Test 2: Try connecting with database specified
cat("\n", paste(rep("-", 70), collapse = ""), "\n")
cat("Test 2: Connecting to MySQL with database specified...\n")
con2 <- NULL
result2 <- tryCatch({
  con2 <- dbConnect(
    RMariaDB::MariaDB(),
    host     = MYSQL_HOST,
    port     = MYSQL_PORT,
    user     = MYSQL_USER,
    password = MYSQL_PASSWORD,
    dbname   = MYSQL_DB
  )
  if (!is.null(con2) && dbIsValid(con2)) {
    cat("✓ Successfully connected to database '", MYSQL_DB, "'!\n", sep = "")
    
    # List tables
    cat("\nTables/views in database:\n")
    tables <- dbGetQuery(con2, "SHOW FULL TABLES")
    names(tables) <- c("name", "type")
    print(tables)
    
    dbDisconnect(con2)
    TRUE
  } else {
    FALSE
  }
}, error = function(e) {
  cat("✗ Failed to connect to database\n")
  cat("Error:", e$message, "\n")
  FALSE
})

# Test 3: Try alternative connection method
cat("\n", paste(rep("-", 70), collapse = ""), "\n")
cat("Test 3: Trying alternative connection method...\n")
con3 <- NULL
result3 <- tryCatch({
  con3 <- dbConnect(
    drv = RMariaDB::MariaDB(),
    host = MYSQL_HOST,
    port = MYSQL_PORT,
    username = MYSQL_USER,
    password = MYSQL_PASSWORD,
    dbname = MYSQL_DB
  )
  if (!is.null(con3) && dbIsValid(con3)) {
    cat("✓ Alternative connection method worked!\n")
    dbDisconnect(con3)
    TRUE
  } else {
    FALSE
  }
}, error = function(e) {
  cat("✗ Alternative method also failed\n")
  cat("Error:", e$message, "\n")
  FALSE
})

# Test 4: Check if MySQL service is running (Windows)
cat("\n", paste(rep("-", 70), collapse = ""), "\n")
cat("Test 4: Checking MySQL service status (Windows)...\n")
tryCatch({
  # Try to check Windows service
  service_check <- system("sc query MySQL", intern = TRUE, ignore.stderr = TRUE)
  if (length(service_check) > 0) {
    cat("MySQL service status:\n")
    cat(paste(service_check, collapse = "\n"), "\n")
  } else {
    cat("Could not check service status (may need to run as administrator)\n")
  }
}, error = function(e) {
  cat("Could not check service status\n")
})

cat("\n", paste(rep("=", 70), collapse = ""), "\n")
cat("Diagnostic complete!\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

