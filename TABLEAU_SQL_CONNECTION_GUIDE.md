# Tableau MySQL Connection Guide
## Connecting Tableau to MySQL Database for Fraud Detection Dashboard

**Purpose:** Step-by-step guide for connecting Tableau directly to MySQL database using MySQL Workbench

---

## Overview

Instead of exporting to CSV, you can connect Tableau directly to your MySQL database. This provides:
- ✅ Real-time data updates
- ✅ Better performance with large datasets
- ✅ No need to export/import files
- ✅ Automatic data refresh

---

## 🎯 Quick Start for MySQL Workbench

**If you're using MySQL 8.4 (or MySQL 5.7+) with MySQL Workbench:**

1. **Use the MySQL-specific script:** `prepare_tableau_data_mysql.sql`
2. **Open MySQL Workbench** and connect to your database
3. **Create/Select your database**
4. **Run the script** (File → Open SQL Script → Execute)
5. **Connect Tableau** to MySQL (see Step 2 below)

---

## ⚠️ Prerequisites

**Before running the SQL script, you MUST have:**

1. **A `transactions` table** in your database with transaction data
2. **Required columns in `transactions` table:**
   - `transaction_id` (INT, Primary Key)
   - `customer_id` (INT)
   - `transaction_date` (DATETIME or TIMESTAMP)
   - `fraud_probability` (DECIMAL) - e.g., 0.75
   - `fraud_prediction` (INT) - 0 or 1
   - `actual_label` (INT) - 0 or 1
   - `amount` (DECIMAL)

**If you don't have this table yet, see [Creating the Transactions Table](#creating-the-transactions-table) below.**

---

## Step 1: Prepare SQL Views Using MySQL Workbench

### 1.1 Launch MySQL Workbench

**Option A: From Start Menu**
- Press `Windows Key`
- Type **"MySQL Workbench"**
- Click on **"MySQL Workbench"** from search results

**Option B: From Desktop/Shortcut**
- Double-click the MySQL Workbench icon on your desktop (if you have one)

**Option C: Download if Not Installed**
- Download from: https://dev.mysql.com/downloads/workbench/
- Install MySQL Workbench
- Launch it after installation

---

### 1.2 Connect to Your MySQL Server

1. **In MySQL Workbench Home Screen:**
   - You'll see connection tiles (squares with connection names)
   - If you have an existing connection, click on it
   - **OR** click the **"+"** button to create a new connection

2. **If Creating New Connection:**
   - **Connection Name:** Give it a name (e.g., "Local MySQL" or "My Database")
   - **Hostname:** `localhost` (for local MySQL) or your MySQL server IP address
   - **Port:** `3306` (default MySQL port - usually already filled)
   - **Username:** Your MySQL username (commonly `root`)
   - **Password:** Click **"Store in Vault"** and enter your MySQL password
   - Click **"Test Connection"** to verify it works
   - Click **"OK"** to save

3. **Connect:**
   - Click on your connection tile
   - Enter password if prompted (if you didn't store it in vault)
   - You should now see the MySQL Workbench interface with your database

---

### 1.3 Create or Select Your Database ⚠️ **REQUIRED**

**This step is CRITICAL!** If you skip this, you'll get error: `Error Code: 1046. No database selected`

#### **Option A: Create a New Database (If You Don't Have One)**

**Step 1: Create the Database**

1. In the **query editor** (the big text area in the middle of MySQL Workbench)
2. Type this command:
   ```sql
   CREATE DATABASE fraud_detection_db;
   ```
   (Or use any name you prefer)

3. **Execute the command:**
   - Click the **lightning bolt icon** (⚡) in the toolbar
   - **OR** press `Ctrl + Shift + Enter`
   - You should see "Query OK, 1 row affected" in the output

**Step 2: Refresh the SCHEMAS Panel**

1. **Right-click** on the **"SCHEMAS"** section in the left sidebar
2. Click **"Refresh All"**
3. Your new database should now appear in the list!

**⚠️ Database Not Showing Up?**
- Right-click "SCHEMAS" → "Refresh All" (try multiple times)
- **OR** Click the refresh icon (circular arrow) at the top of SCHEMAS panel
- **OR** Close and reopen MySQL Workbench
- **OR** Use SQL command: `USE fraud_detection_db;` (works even if not visible in SCHEMAS)

**Step 3: Select the Database**

1. **Double-click** on your database name in the SCHEMAS list
2. It will become **BOLD** (this means it's now selected/active)
3. **OR** run this command:
   ```sql
   USE fraud_detection_db;
   ```

#### **Option B: Select an Existing Database**

1. **Look at the LEFT SIDEBAR** of MySQL Workbench
2. Find the section called **"SCHEMAS"** (expand it if collapsed)
3. **Find your database name** in the list
4. **Double-click** on your database name
   - It will become **BOLD** (selected/active)
   - **OR** run: `USE your_database_name;`

**✅ How to Verify Database is Selected:**
- Database name is **BOLD** in SCHEMAS list
- Database name appears in toolbar dropdown at the top
- Run: `SELECT DATABASE();` - should return your database name

---

### 1.4 Open the MySQL SQL Script

1. **In MySQL Workbench:**
   - Go to **File → Open SQL Script** (or press `Ctrl + O`)

2. **Navigate to Your Project Folder:**
   - Navigate to: `C:\Users\monai\OneDrive - student.uni-halle.de\Desktop\Billie`
   - Look for the file: **`prepare_tableau_data_mysql.sql`**
   - ⚠️ **IMPORTANT:** Make sure you select the **MySQL version** (`prepare_tableau_data_mysql.sql`)

3. **Open the File:**
   - Click on `prepare_tableau_data_mysql.sql`
   - Click **"Open"**
   - The SQL script will appear in a new tab in MySQL Workbench

---

### 1.5 Execute the Script

**Method A: Using Execute Button (Recommended)**
1. Look at the toolbar at the top of MySQL Workbench
2. Find the **lightning bolt icon** (⚡) - this is the "Execute" button
3. Click it to run the entire script

**Method B: Using Keyboard Shortcut**
- Press **`Ctrl + Shift + Enter`** (executes entire script)
- **OR** press **`F9`** (executes selected text or entire script)

**What to Expect:**
- The script will run and process all the SQL commands
- You'll see results in the **"Output"** tab at the bottom
- If successful, you'll see messages like "0 row(s) affected" or "Query OK"
- **"0 row(s) affected" is NORMAL** - it means the views were created successfully!
  - Views don't contain data themselves - they're queries that read from your `transactions` table
  - If you see "0 row(s) affected", the views were created correctly
- **Warnings are NORMAL on first run** - you might see:
  - `Warning: 1051 Unknown table 'database.view_name'`
  - This is expected! The script tries to drop views that don't exist yet (first time only)
  - These warnings are harmless and can be ignored
- **Errors** (if any) will appear in **red text** - these are different from warnings

**✅ After seeing "0 row(s) affected":**
1. Check if views were created (see Step 1.6 below)
2. Verify you have data in your `transactions` table:
   ```sql
   SELECT COUNT(*) FROM transactions;
   ```
   - If this returns 0, you need to import data first
   - If this returns a number > 0, your views will show data

---

### 1.6 Verify Views Were Created

1. **In the Left Sidebar (SCHEMAS panel):**
   - Make sure your database is expanded (click the arrow next to it)
   - Look for a folder called **"Views"**
   - Click the arrow next to **"Views"** to expand it

2. **Check for These 7 Views:**
   You should see these views listed:
   - ✅ `tableau_fraud_data` - Main data view for Tableau
   - ✅ `tableau_summary_stats` - Daily summary statistics
   - ✅ `tableau_psi_data` - PSI component data
   - ✅ `tableau_psi_score` - Overall PSI score
   - ✅ `tableau_queue_overview` - Queue metrics
   - ✅ `tableau_feature_psi` - Feature-level PSI
   - ✅ `tableau_feature_psi_scores` - Aggregated feature PSI

3. **Test a View (Optional):**
   - Right-click on `tableau_fraud_data`
   - Select **"Select Rows - Limit 1000"**
   - This will show you sample data from the view
   - If you see data, the view was created successfully!

---

## Creating the Transactions Table

**⚠️ If you get error: "Error Code: 1146. Table 'database.transactions' doesn't exist"**

You need to create the `transactions` table first! The script creates views based on a `transactions` table that must exist.

**📁 Files Available for Data Preparation:**
- **`transactions_template.csv`** - Sample template with example data (10 rows)
- **`prepare_mysql_dataset.R`** - **RECOMMENDED** - R script to convert your `creditcard.csv` to MySQL format
- **`convert_to_mysql_transactions.R`** - Alternative R script for other CSV formats

**🚀 Quick Start - Prepare Your Dataset:**
1. Open R or RStudio
2. Run: `source("prepare_mysql_dataset.R")`
3. This will create `transactions_for_mysql.csv` ready for MySQL import

### Step 1: Create the Table Structure

Run this SQL in MySQL Workbench (replace `fraud_detection_db` with your database name):

```sql
USE fraud_detection_db;

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    transaction_date DATETIME,
    fraud_probability DECIMAL(5,4),
    fraud_prediction INT,
    actual_label INT,
    amount DECIMAL(10,2)
);
```

Execute this (⚡ button). You should see "Query OK".

### Step 2: Import Your Data

**⏱️ Import Time Estimates:**
- **Small dataset (10,000 rows):** ~30 seconds - 2 minutes
- **Medium dataset (100,000 rows):** ~2-5 minutes
- **Large dataset (284,000 rows):** ~5-15 minutes
- **Very large (500,000+ rows):** ~15-30 minutes

**💡 Tip:** Test with a smaller dataset first! Edit `run_mysql_setup.R` and set `MAX_ROWS <- 10000` to test quickly.

**Option A: Using MySQL Workbench Import Wizard (Recommended for First Time)**

1. Right-click on the `transactions` table in SCHEMAS
2. Select **"Table Data Import Wizard"**
3. Choose your CSV file (`transactions_for_mysql.csv`)
4. Map the columns to match:
   - `transaction_id` → transaction_id
   - `customer_id` → customer_id
   - `transaction_date` → transaction_date
   - `fraud_probability` → fraud_probability
   - `fraud_prediction` → fraud_prediction
   - `actual_label` → actual_label
   - `amount` → amount
5. Click Next → Next → Execute
6. **Wait for completion** - You'll see progress bar

**⚠️ Note:** Import Wizard is slower but easier. For large datasets, use Option B (LOAD DATA) which is much faster!

**Option B: Using SQL LOAD DATA Command (FASTER - Recommended for Large Datasets)**

**This method is 5-10x faster than Import Wizard!**

1. **Enable LOCAL INFILE** (if needed):
   - In MySQL Workbench connection, go to Edit Connection
   - Advanced tab → Add: `OPT_LOCAL_INFILE=1`
   - Or run: `SET GLOBAL local_infile = 1;`

2. **Run this command** (adjust path to your file):

```sql
USE fraud_detection_db;

-- Enable local file loading
SET GLOBAL local_infile = 1;

-- Load the data (MUCH FASTER than Import Wizard)
LOAD DATA LOCAL INFILE 'C:/Users/monai/OneDrive - student.uni-halle.de/Desktop/Billie/transactions_for_mysql.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(transaction_id, customer_id, transaction_date, fraud_probability, fraud_prediction, actual_label, amount);
```

**Time Comparison:**
- Import Wizard: ~10-15 minutes for 284K rows
- LOAD DATA: ~1-3 minutes for 284K rows ⚡

**Note:** 
- Use forward slashes `/` in the path, not backslashes `\`
- Make sure the path is correct
- The file must exist at that location

### Step 3: Verify Data Was Imported

Run this to check:
```sql
SELECT COUNT(*) FROM transactions;
```

You should see a number (e.g., 1000, 5000, etc.).

### Step 4: Run the View Creation Script Again

After the `transactions` table exists with data, run `prepare_tableau_data_mysql.sql` again.

---

## Step 2: Connect Tableau to MySQL Database

### 2.1 Open Tableau Desktop

1. Launch Tableau Desktop
2. You'll see the start screen with connection options

### 2.2 Find MySQL Connection Option

**If you see "MySQL" in the list:**
- Click on **"MySQL"** directly

**If you DON'T see "MySQL" in the list:**

**Option A: Look for "More Servers" or "Other Databases"**
1. Scroll down in the connection list
2. Look for **"More Servers"** or **"Other Databases"**
3. Click it to see more options
4. MySQL should be in the expanded list

**Option B: Use "Other Databases (ODBC)"**
1. Look for **"Other Databases (ODBC)"** in the connection list
2. Click on it
3. You'll need to set up an ODBC connection (see below)

**Option C: Search for MySQL**
1. Use the search box at the top of the connection list
2. Type "MySQL"
3. It should appear in search results

**Option D: Install MySQL Connector (if still not visible)**

**Step 1: Download MySQL Connector/ODBC**
- Go to: https://dev.mysql.com/downloads/connector/odbc/
- Select your Windows version:
  - **Windows (x86, 32-bit)** if you have 32-bit Tableau
  - **Windows (x64, 64-bit)** if you have 64-bit Tableau (most common)
- Download the MSI installer

**Step 2: Install the Connector**
- Run the downloaded installer
- Follow the installation wizard
- Keep default settings
- Complete the installation

**Step 3: Restart Tableau Desktop**
- Close Tableau completely
- Reopen Tableau Desktop
- MySQL should now appear in the connection list

**Step 4: Verify Installation**
- In Tableau, look for "MySQL" in the connection list
- If still not visible, use ODBC method below

### 2.3 Enter Connection Details

**For MySQL (MySQL 8.4 / MySQL 5.7+):**

1. **Enter Connection Details:**
   ```
   Server: localhost (or your MySQL server IP)
   Port: 3306 (default MySQL port)
   Database: your_database_name
   Username: your_username (e.g., root)
   Password: your_password
   ```

2. **Optional Settings:**
   - **Require SSL:** Uncheck if using local MySQL (check for remote/production)
   - **Initial SQL:** Leave blank (or add `USE your_database_name;` if needed)

**Example for Local MySQL:**
```
Server: localhost
Port: 3306
Database: fraud_detection_db
Username: root
Password: [your password]
```

### 2.4 Test Connection

1. Click "Sign In" or "Test Connection"
2. Verify connection is successful
3. Click "OK"

**Common MySQL Connection Issues:**

**Issue: "How should SQL server verify the authenticity of the login ID"**
- **This question is for SQL Server, but you're using MySQL**
- **Solution:** Select **"SQL Server Authentication"** or **"Use a specific username and password"**
- Then enter:
  - **Username:** `root` (or your MySQL username)
  - **Password:** `[your MySQL password]`
- **OR** if using ODBC DSN, authentication is already configured - just select the DSN

**Issue: "MySQL option not visible in Tableau"**
- **Solution 1:** Look for "More Servers" or scroll down in connection list
- **Solution 2:** Use "Other Databases (ODBC)" instead
- **Solution 3:** Install MySQL Connector/ODBC driver
- **Solution 4:** Update Tableau Desktop to latest version

**Issue: "Access denied"**
- **Solution:** Check username/password
- Make sure you're using the correct MySQL credentials

**Issue: "Can't connect to MySQL server"**
- **Solution:** 
  - Make sure MySQL service is running (check Windows Services)
  - Verify hostname and port (default: localhost:3306)
  - Check Windows Firewall settings

**Issue: "Unknown database"**
- **Solution:** Create the database first in MySQL Workbench
- Or verify database name is correct (case-sensitive in some MySQL versions)

**Issue: "Port 3306 blocked"**
- **Solution:** 
  - Check Windows Firewall
  - Or use different port if MySQL is configured differently

---

## Step 3: Select Data Source in Tableau

### 3.1 Choose Database/Schema

1. Select your database from the left panel
2. Navigate to "Views" section

### 3.2 Select Main View

1. Find `tableau_fraud_data` view
2. Drag it to the canvas (or double-click)
3. Click "Sheet 1" to start building

### 3.3 Add Additional Data Sources (Optional)

For different dashboard components, you can add multiple data sources:

**For Summary Metrics:**
- Add `tableau_summary_stats` view

**For PSI Monitoring:**
- Add `tableau_psi_score` view
- Add `tableau_feature_psi_scores` view

**For Queue Overview:**
- Add `tableau_queue_overview` view

---

## Step 4: Configure Data Source in Tableau

### 4.1 Set Up Data Source Filters (Optional)

1. Right-click on data source
2. Select "Edit Data Source Filters"
3. Add filters if needed:
   - Date range filter
   - Decision type filter
   - Queue status filter

### 4.2 Set Data Source to Live or Extract

**Live Connection (Recommended for Real-time):**
1. Data → Connection Type → Live
2. Data refreshes automatically when you open workbook
3. Best for real-time monitoring

**Extract (Recommended for Performance):**
1. Data → Extract Data
2. Set refresh schedule
3. Better performance for large datasets
4. Can schedule automatic refresh

---

## Step 5: Create Calculated Fields in Tableau

Even though SQL views have calculated fields, you may want to add Tableau-specific calculations:

### 5.1 Fraud Capture Rate

```
SUM([true_positive]) / SUM([actual_label])
```

### 5.2 False Positive Rate

```
SUM([false_positive]) / SUM([Total Legitimate])
```

Where `Total Legitimate` is:
```
SUM(IF [actual_label] = 0 THEN 1 ELSE 0 END)
```

### 5.3 Queue Age in Hours

```
DATEDIFF('hour', [queue_created_date], NOW())
```

### 5.4 PSI Status

```
IF [psi_score] < 0.10 THEN "No Drift"
ELSEIF [psi_score] < 0.25 THEN "Minor Drift"
ELSE "Major Drift"
END
```

---

## Step 6: Build Dashboard

Follow the main `TABLEAU_DASHBOARD_GUIDE.md` but use your SQL views instead of CSV:

1. **Fraud Capture Rate Sheet:**
   - Use `tableau_fraud_data` view
   - Or use `tableau_summary_stats` for aggregated metrics

2. **False Positive Rate Sheet:**
   - Use `tableau_fraud_data` view
   - Calculate from confusion matrix fields

3. **PSI Monitoring Sheet:**
   - Use `tableau_psi_score` view for overall PSI
   - Use `tableau_feature_psi_scores` for feature-level PSI

4. **Queue Overview Sheet:**
   - Use `tableau_queue_overview` view
   - Or use `tableau_fraud_data` filtered by `in_queue = 1`

---

## Step 7: Set Up Data Refresh

### 7.1 For Live Connection

- Data refreshes automatically when workbook opens
- No additional setup needed
- Best for real-time dashboards

### 7.2 For Extract

**Manual Refresh:**
1. Data → Refresh Extracts
2. Or right-click data source → Refresh

**Scheduled Refresh (Tableau Server):**
1. Publish workbook to Tableau Server
2. Set up refresh schedule:
   - Daily at specific time
   - Multiple times per day
   - Weekly/Monthly

**Incremental Refresh:**
1. Data → Extract Data → Edit
2. Select "Incremental Refresh"
3. Choose date field for incremental updates
4. Only new data is added (faster)

---

## Step 8: Performance Optimization

### 8.1 Use Extracts for Large Datasets

- Better performance than live connection
- Can filter at data source level
- Faster dashboard loading

### 8.2 Add Data Source Filters

Filter data at the source level in your SQL views:
```sql
-- In your SQL view, add WHERE clause
WHERE transaction_date >= DATE_SUB(NOW(), INTERVAL 90 DAY)
```

### 8.3 Use Aggregated Views

- Use `tableau_summary_stats` for summary metrics
- Reduces data volume
- Faster calculations

### 8.4 Hide Unused Fields

1. Right-click field → Hide
2. Reduces data transfer
3. Faster performance

---

## Troubleshooting

### ⚠️ Issue: "Error Code: 1046. No database selected" - **MOST COMMON ERROR!**

This error means you haven't selected a database before running the script.

**Quick Fix (Choose One Method):**

**Method 1: Double-Click in SCHEMAS (Easiest)**
1. Look at the **LEFT SIDEBAR** in MySQL Workbench
2. Find the **"SCHEMAS"** section (expand it if collapsed)
3. Find your database name in the list
4. **DOUBLE-CLICK** on your database name
5. It will become **BOLD** (this means it's selected)
6. Now run your script again

**Method 2: Use SQL Command**
1. In the query editor, type:
   ```sql
   USE your_database_name;
   ```
   (Replace `your_database_name` with your actual database name)
2. Execute it (click ⚡ or press `Ctrl + Shift + Enter`)
3. You should see "Database changed" in the output
4. Now run your script again

**Method 3: Use Toolbar Dropdown**
1. Look at the **toolbar at the top** of MySQL Workbench
2. Find the **database dropdown** (might say "Default Schema" or be blank)
3. Click the dropdown and **select your database**
4. Now run your script again

**✅ How to Verify Database is Selected:**
- Database name is **BOLD** in SCHEMAS list
- Database name appears in toolbar dropdown
- Run: `SELECT DATABASE();` - should return your database name

---

### Issue: "Access denied for user"

- **Solution:** Check your username and password
- Make sure you're using the correct MySQL credentials

---

### Issue: "No databases in SCHEMAS" or "SCHEMAS list is empty"

- **Solution:** You need to create a database first! Follow these steps:
  1. In the query editor, type:
     ```sql
     CREATE DATABASE fraud_detection_db;
     ```
     (Or use any name you prefer)
  2. Execute it (⚡ button or `Ctrl + Shift + Enter`)
  3. Right-click on "SCHEMAS" → "Refresh All"
  4. Your database will appear in the list
  5. Double-click on it to select it

---

### Issue: "Unknown database"

- **Solution:** Create the database first:
  ```sql
  CREATE DATABASE your_database_name;
  USE your_database_name;
  ```

---

### ⚠️ Issue: "Error Code: 1146. Table 'database.transactions' doesn't exist" - **CRITICAL!**

**This means you need to create the `transactions` table first!** See [Creating the Transactions Table](#creating-the-transactions-table) section above.

---

### Issue: "Warning: 1051 Unknown table 'database.view_name'" ⚠️ **NORMAL - NOT AN ERROR!**

- **This is EXPECTED on the first run!** The script tries to drop views before creating them
- If the views don't exist yet (first time), MySQL shows this warning - it's harmless
- **Solution:** Ignore these warnings! They're normal. Check if views were created:
  1. Look in SCHEMAS → Your Database → Views
  2. You should see 7 views listed
  3. If views are there, the script worked successfully!

---

### Issue: Script runs but no views appear

- **Solution:** 
  1. Refresh the SCHEMAS panel (right-click → Refresh All)
  2. Check the Output tab for error messages
  3. Make sure you selected the correct database before running

---

### Issue: "Error Code: 1064 - Syntax error"

- **Solution:** Make sure you're using `prepare_tableau_data_mysql.sql` (not the SQL Server version)
- The MySQL version has different syntax (e.g., `NOW()` instead of `GETDATE()`)

---

### Issue: "Can't connect to MySQL server" in Tableau

- **Solution:**
  - Make sure MySQL service is running (check Windows Services)
  - Verify hostname and port (default: localhost:3306)
  - Check Windows Firewall settings
  - Verify username and password are correct

---

### Issue: Connection Timeout

- **Solution:**
  - Check network connectivity
  - Verify firewall settings
  - Increase connection timeout in Tableau

---

### Issue: Slow Performance

- **Solution:**
  - Use extracts instead of live connection
  - Add data source filters
  - Use aggregated views
  - Optimize SQL queries

---

### Issue: Missing Data

- **Solution:**
  - Verify SQL views are created
  - Check date filters
  - Verify user permissions
  - Check for NULL values

---

### Issue: Date Format Errors

- **Solution:**
  - Ensure dates are in correct format in database
  - Use CAST or CONVERT in SQL
  - Set date format in Tableau data source

---

## MySQL-Specific Notes

### Date Functions in MySQL

- Use `NOW()` for current date/time
- Use `CURDATE()` for current date only
- Use `DATE_SUB(NOW(), INTERVAL 30 DAY)` for date arithmetic
- Use `TIMESTAMPDIFF(HOUR, date1, date2)` for date differences

### Connection String

```
Server: localhost:3306 (or your MySQL server IP)
Database: your_database_name
Username: your_username
Password: your_password
```

---

## Security Considerations

### 1. Use Read-Only Database User

Create a dedicated user for Tableau with read-only access:
```sql
CREATE USER 'tableau_user'@'localhost' IDENTIFIED BY 'secure_password';
GRANT SELECT ON fraud_detection_db.* TO 'tableau_user'@'localhost';
FLUSH PRIVILEGES;
```

### 2. Use Row-Level Security

Implement row-level security in your views:
```sql
-- Example: Filter by user's department
WHERE department = CURRENT_USER_DEPARTMENT()
```

### 3. Encrypt Connections

- Use SSL/TLS for database connections
- Enable encryption in Tableau connection settings

---

## Best Practices

### 1. Use Views Instead of Tables

- Views provide abstraction
- Easier to modify without changing Tableau
- Can add business logic in SQL

### 2. Schedule Regular Refreshes

- Daily refresh for extracts
- Real-time for live connections
- Balance between freshness and performance

### 3. Monitor Performance

- Track query execution time
- Optimize slow queries
- Use MySQL query performance tools

### 4. Document Your Views

- Add comments to SQL views
- Document field meanings
- Keep data dictionary updated

---

## Quick Reference: SQL Views for Dashboard Components

| Dashboard Component | SQL View | Key Fields |
|---------------------|----------|------------|
| **Fraud Capture Rate** | `tableau_fraud_data` | `true_positive`, `actual_label` |
| **False Positive Rate** | `tableau_fraud_data` | `false_positive`, `actual_label` |
| **PSI Monitoring** | `tableau_psi_score` | `psi_score`, `drift_status` |
| **Feature PSI** | `tableau_feature_psi_scores` | `feature_psi_score`, `feature_name` |
| **Queue Overview** | `tableau_queue_overview` | `queue_count`, `avg_wait_hours` |
| **Summary Stats** | `tableau_summary_stats` | `fraud_capture_rate`, `false_positive_rate` |

---

## Next Steps

**📋 After Importing Data - Follow These Steps:**

1. ✅ **Verify Data Import** - Check that data was imported correctly
2. ✅ **Create Views** - Run `prepare_tableau_data_mysql.sql` in MySQL Workbench
3. ✅ **Verify Views** - Check that 7 views were created and show data
4. ✅ **Connect Tableau** - Connect Tableau Desktop to your MySQL database
5. ✅ **Select Views** - Use the created views in Tableau
6. ✅ **Build Dashboard** - Follow `TABLEAU_DASHBOARD_GUIDE.md`
7. ✅ **Set Refresh** - Configure data refresh schedule
8. ✅ **Publish** - Publish to Tableau Server (if available)

**📖 Detailed Next Steps Guide:** See `NEXT_STEPS_AFTER_IMPORT.md` for complete step-by-step instructions

---

**Document Version:** 2.0  
**Last Updated:** [Current Date]  
**Database Support:** MySQL 5.7+ and MySQL 8.0+ (MySQL Workbench)
