# How to Connect Tableau to MySQL - Step by Step

## Problem: MySQL Not Visible in Tableau

If you only see connectors like "Google Drive", "OData", and "Web Data Connector", you need to either:
1. Install MySQL Connector, OR
2. Use ODBC Connection (easier, no installation needed)

---

## Solution 1: Use ODBC Connection (RECOMMENDED - No Installation Needed)

This method works immediately without installing anything!

### Step 1: Set Up ODBC Data Source

1. **Open ODBC Data Source Administrator:**
   - Press `Windows Key + R`
   - Type: `odbcad32.exe`
   - Press Enter
   - **OR** Search "ODBC" in Windows Start Menu

2. **Check Existing DSN (If You Already Created One):**
   - Go to **"User DSN"** tab
   - Look for `MySQL_Tableau` (or whatever name you used)
   - **If it exists:** Click on it, then click **"Configure"**
   - **Check the Driver:** Make sure it says **"MySQL ODBC 8.0 Driver"** NOT "SQL Server"
   - **If it says SQL Server:** Delete it and create a new one (see below)

3. **Create New Data Source (or Fix Existing One):**
   - Go to **"User DSN"** tab
   - Click **"Add"** button

4. **Select MySQL Driver - ⚠️ CRITICAL:**
   - **IMPORTANT:** Look for **"MySQL ODBC 8.0 Unicode Driver"** or **"MySQL ODBC 8.0 ANSI Driver"**
   - **DO NOT select:** "ODBC Driver 17/18 for SQL Server" or any SQL Server driver
   - **DO NOT select:** "SQL Server" or "SQL Server Native Client"
   - **If you only see SQL Server drivers:** You need to install MySQL ODBC driver first (see below)
   - If you see MySQL driver, select it and click **"Finish"**

4. **Configure Connection:**
   - **Data Source Name:** `MySQL_Tableau` (or any name you prefer)
   - **TCP/IP Server:** `localhost` (or your MySQL server IP)
   - **Port:** `3306`
   - **User:** `root` (or your MySQL username)
   - **Password:** `[your MySQL password]`
   - **Database:** `fraud_detection_db` (or your database name)
   - Click **"Test"** button
   - Should see: **"Connection successful"**
   - Click **"OK"** to save

### Step 2: Connect in Tableau

1. **Open Tableau Desktop**
2. **Select Connection:**
   - Look for **"Other Databases (ODBC)"** in the connection list
   - Click on it

3. **When Tableau Asks for Connection Details, Enter:**

   **Name:** `MySQL_Fraud_Detection` (or any name you prefer)
   
   **Description:** `MySQL database for fraud detection dashboard` (optional, can leave blank)
   
   **Server/DSN:** 
   - If you see a dropdown, select: **`MySQL_Tableau`** (the DSN you created)
   - OR if it's a text field, type: **`MySQL_Tableau`**
   - OR if it asks for connection string, use:
     ```
     DRIVER={MySQL ODBC 8.0 Unicode Driver};SERVER=localhost;PORT=3306;DATABASE=fraud_detection_db;USER=root;PASSWORD=your_password;
     ```
     (Replace `your_password` with your actual MySQL password)

4. **Click "Connect" or "OK"**

5. **Select Your Database:**
   - You should now see your MySQL database (`fraud_detection_db`)
   - Navigate to **"Views"** folder
   - Select **`tableau_fraud_data`** or any view you want

---

## Solution 2: Install MySQL ODBC Driver (If Not Available)

If you don't see MySQL driver in ODBC setup:

### Step 1: Download MySQL Connector/ODBC

1. Go to: https://dev.mysql.com/downloads/connector/odbc/
2. Select your Windows version:
   - **Windows (x86, 32-bit)** - for 32-bit systems
   - **Windows (x64, 64-bit)** - for 64-bit systems (most common)
3. Click **"Download"** button
4. Choose **"No thanks, just start my download"** (no login needed)

### Step 2: Install the Driver

1. Run the downloaded `.msi` file
2. Follow installation wizard:
   - Click **"Next"**
   - Accept license agreement
   - Choose **"Complete"** installation
   - Click **"Install"**
   - Wait for installation to complete
   - Click **"Finish"**

### Step 3: Verify Installation

1. Open ODBC Data Source Administrator again (`odbcad32.exe`)
2. Click **"Add"** in User DSN tab
3. You should now see **"MySQL ODBC 8.0 Driver"** in the list
4. Follow Step 1 above to create the data source

---

## Solution 3: Install MySQL Connector for Tableau (Alternative)

Some Tableau versions have a built-in MySQL connector that needs to be enabled:

1. **Check Tableau Version:**
   - Help → About Tableau Desktop
   - Note your version

2. **Download Tableau MySQL Connector:**
   - Go to: https://www.tableau.com/support/drivers
   - Search for "MySQL"
   - Download the connector for your Tableau version
   - Install it
   - Restart Tableau

---

## Quick Test: Verify MySQL is Running

Before connecting, make sure MySQL is running:

1. **Check MySQL Service:**
   - Press `Windows Key + R`
   - Type: `services.msc`
   - Look for **"MySQL"** service
   - Make sure it's **"Running"**

2. **Test Connection from Command Line:**
   ```bash
   mysql -u root -p -h localhost
   ```
   - Enter your password
   - If you can connect, MySQL is working

---

## Troubleshooting

### Issue: "MySQL ODBC Driver not found"

**Solution:**
- Install MySQL Connector/ODBC (see Solution 2 above)
- Make sure you install the correct bit version (32-bit vs 64-bit)

### Issue: "Connection failed" in ODBC Test

**Solutions:**
- Check MySQL service is running
- Verify username and password
- Check if port 3306 is correct
- Try `127.0.0.1` instead of `localhost`

### Issue: "Can't see database in Tableau"

**Solutions:**
- Make sure database name is correct (case-sensitive in some MySQL versions)
- Verify you have SELECT permissions on the database
- Try refreshing the connection

### Issue: "DSN not appearing in Tableau"

**Solutions:**
- Make sure you created it in "User DSN" tab (not System DSN)
- Restart Tableau Desktop
- Try creating it in "System DSN" tab instead

---

## Recommended Approach

**For Quick Setup (5 minutes):**
1. Use ODBC method (Solution 1) - No installation needed if MySQL driver exists
2. If driver doesn't exist, install it (Solution 2) - Takes 2 minutes
3. Create ODBC data source
4. Connect in Tableau

**This method works 100% of the time and doesn't depend on Tableau's connector list!**

---

## After Connecting Successfully

Once connected:
1. Navigate to your database → Views
2. Select `tableau_fraud_data` view
3. Click "Sheet 1" to start building
4. Follow `TABLEAU_DASHBOARD_GUIDE.md` to build your dashboard

---

**Need more help?** Check `TABLEAU_SQL_CONNECTION_GUIDE.md` for detailed troubleshooting.

