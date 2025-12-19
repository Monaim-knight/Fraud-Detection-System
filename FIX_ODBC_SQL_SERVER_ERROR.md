# Fix: SQL Server Driver Error When Connecting to MySQL

## Problem

You're getting this error:
```
[Microsoft][ODBC Driver 18 for SQL Server]...
Server is not found or not accessible...
```

**This means Tableau is trying to use SQL Server driver instead of MySQL driver!**

---

## Solution: Fix Your ODBC DSN

### Step 1: Check Your Current ODBC DSN

1. **Open ODBC Data Source Administrator:**
   - Press `Windows Key + R`
   - Type: `odbcad32.exe`
   - Press Enter

2. **Go to "User DSN" tab**

3. **Look for your DSN** (probably named `MySQL_Tableau` or similar)

4. **Check the Driver column:**
   - ❌ **WRONG:** If it says "ODBC Driver 18 for SQL Server" or "SQL Server"
   - ✅ **CORRECT:** Should say "MySQL ODBC 8.0 Unicode Driver" or "MySQL ODBC 8.0 ANSI Driver"

---

### Step 2: Delete Wrong DSN and Create New One

**If your DSN is using SQL Server driver:**

1. **Delete the wrong DSN:**
   - Select the DSN in the list
   - Click **"Remove"**
   - Confirm deletion

2. **Create a new DSN with MySQL driver:**
   - Click **"Add"** button
   - **Look for MySQL driver:**
     - ✅ "MySQL ODBC 8.0 Unicode Driver"
     - ✅ "MySQL ODBC 8.0 ANSI Driver"
   - **DO NOT select:**
     - ❌ "ODBC Driver 17/18 for SQL Server"
     - ❌ "SQL Server"
     - ❌ "SQL Server Native Client"

3. **If you DON'T see MySQL driver:** You need to install it first (see Step 3)

---

### Step 3: Install MySQL ODBC Driver (If Not Available)

**If you only see SQL Server drivers in the list:**

1. **Download MySQL Connector/ODBC:**
   - Go to: https://dev.mysql.com/downloads/connector/odbc/
   - Select: **Windows (x64, 64-bit)** - most common
   - Click "Download"
   - Choose "No thanks, just start my download"

2. **Install the Driver:**
   - Run the downloaded `.msi` file
   - Follow installation wizard
   - Keep default settings
   - Complete installation

3. **Restart ODBC Administrator:**
   - Close ODBC Data Source Administrator
   - Open it again (`odbcad32.exe`)
   - Click "Add"
   - **You should now see MySQL drivers!**

---

### Step 4: Create Correct ODBC DSN

1. **In ODBC Data Source Administrator:**
   - Click **"Add"**
   - Select **"MySQL ODBC 8.0 Unicode Driver"** (or ANSI Driver)
   - Click **"Finish"**

2. **Configure Connection:**
   - **Data Source Name:** `MySQL_Tableau`
   - **TCP/IP Server:** `localhost`
   - **Port:** `3306`
   - **User:** `root`
   - **Password:** `[your MySQL password]`
   - **Database:** `fraud_detection_db`

3. **Test Connection:**
   - Click **"Test"** button
   - Should see: **"Connection successful"**
   - Click **"OK"** to save

4. **Verify Driver:**
   - In the DSN list, check the "Driver" column
   - Should say: **"MySQL ODBC 8.0 Unicode Driver"** (NOT SQL Server!)

---

### Step 5: Connect in Tableau Again

1. **In Tableau Desktop:**
   - Go back to connection setup
   - Select **"Other Databases (ODBC)"**
   - Select DSN: **`MySQL_Tableau`**
   - Click **"Connect"**

2. **This time it should work!** ✅

---

## Quick Checklist

- [ ] Opened ODBC Data Source Administrator
- [ ] Checked existing DSN - found it's using SQL Server driver
- [ ] Deleted wrong DSN
- [ ] Installed MySQL ODBC driver (if needed)
- [ ] Created new DSN with MySQL driver
- [ ] Tested connection - "Connection successful"
- [ ] Verified driver shows "MySQL ODBC 8.0" (not SQL Server)
- [ ] Connected in Tableau - should work now!

---

## Why This Happened

Tableau's ODBC connection can default to SQL Server driver if:
- MySQL ODBC driver is not installed
- Wrong driver was selected when creating DSN
- Tableau is trying to auto-detect and picks wrong driver

**Solution:** Always explicitly select MySQL driver when creating ODBC DSN!

---

**After fixing, you should be able to connect successfully!** ✅



