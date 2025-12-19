# Fix Connection Error - Step by Step

## Error You're Seeing:
```
Connection failed SQLstate : 01000
SQL server error 64
Microsoft ODBC SQL server
```

**This means your ODBC DSN is using SQL Server driver instead of MySQL driver!**

---

## ✅ Step-by-Step Fix

### **STEP 1: Open ODBC Data Source Administrator**

1. Press `Windows Key + R`
2. Type: `odbcad32.exe`
3. Press Enter
4. ODBC Data Source Administrator window opens

---

### **STEP 2: Check Your Current DSN**

1. Click on **"User DSN"** tab (at the top)
2. Look for your DSN in the list (probably named `MySQL_Tableau` or similar)
3. **Look at the "Driver" column** - this tells you which driver it's using

**What you might see:**
- ❌ **WRONG:** "ODBC Driver 18 for SQL Server"
- ❌ **WRONG:** "ODBC Driver 17 for SQL Server"  
- ❌ **WRONG:** "SQL Server"
- ✅ **CORRECT:** "MySQL ODBC 8.0 Unicode Driver"
- ✅ **CORRECT:** "MySQL ODBC 8.0 ANSI Driver"

**If it says SQL Server → You need to delete it and create a new one!**

---

### **STEP 3: Delete the Wrong DSN**

1. **Select the DSN** that's using SQL Server driver
2. Click **"Remove"** button
3. Click **"Yes"** to confirm deletion

---

### **STEP 4: Check if MySQL Driver is Installed**

1. Still in ODBC Data Source Administrator
2. Click **"Add"** button
3. **Look at the list of drivers**

**What you should see:**
- ✅ "MySQL ODBC 8.0 Unicode Driver"
- ✅ "MySQL ODBC 8.0 ANSI Driver"

**If you DON'T see MySQL drivers:**
- You need to install MySQL ODBC driver first
- See "Install MySQL Driver" section below
- Then come back to Step 5

**If you DO see MySQL drivers:**
- Continue to Step 5

---

### **STEP 5: Create New DSN with MySQL Driver**

1. **In the driver list, select:**
   - ✅ **"MySQL ODBC 8.0 Unicode Driver"** (preferred)
   - OR "MySQL ODBC 8.0 ANSI Driver"
   - ❌ **DO NOT select:** Any SQL Server driver!

2. Click **"Finish"**

3. **Configure the connection:**
   - **Data Source Name:** `MySQL_Tableau`
   - **Description:** (leave blank or type "MySQL for Tableau")
   - **TCP/IP Server:** `localhost`
   - **Port:** `3306`
   - **User:** `root` (or your MySQL username)
   - **Password:** `[enter your MySQL password]`
   - **Database:** `fraud_detection_db` (or your database name)

4. **Test the connection:**
   - Click **"Test"** button
   - Should see: **"Connection successful"** ✅
   - If you see an error, check:
     - MySQL service is running
     - Username/password is correct
     - Database name is correct

5. Click **"OK"** to save

---

### **STEP 6: Verify the DSN is Correct**

1. **Back in the DSN list:**
   - Find your `MySQL_Tableau` DSN
   - **Check the "Driver" column**
   - Should say: **"MySQL ODBC 8.0 Unicode Driver"** (NOT SQL Server!)

2. **If it still says SQL Server:**
   - Delete it again
   - Make sure you select MySQL driver when creating

---

### **STEP 7: Connect in Tableau**

1. **Open Tableau Desktop**
2. **Select:** "Other Databases (ODBC)"
3. **Enter:**
   - **Name:** `MySQL_Fraud_Detection`
   - **Description:** `MySQL database` (optional)
   - **Server/DSN:** `MySQL_Tableau`
4. **Click "Connect"**

**This time it should work!** ✅

---

## Install MySQL ODBC Driver (If Needed)

**If you don't see MySQL drivers in Step 4:**

### **Download:**
1. Go to: https://dev.mysql.com/downloads/connector/odbc/
2. Select: **Windows (x64, 64-bit)** - most common
3. Click **"Download"** button
4. Choose **"No thanks, just start my download"**

### **Install:**
1. Run the downloaded `.msi` file
2. Follow installation wizard:
   - Click **"Next"**
   - Accept license agreement
   - Choose **"Complete"** installation
   - Click **"Install"**
   - Wait for installation
   - Click **"Finish"**

### **Verify Installation:**
1. Close ODBC Data Source Administrator
2. Open it again (`odbcad32.exe`)
3. Click **"Add"**
4. **You should now see MySQL drivers!**

---

## Troubleshooting

### **Issue: "Connection failed" when testing in ODBC**

**Check:**
- MySQL service is running (check Windows Services)
- Username and password are correct
- Database name is correct (case-sensitive in some MySQL versions)
- Port 3306 is correct

### **Issue: Still seeing SQL Server errors in Tableau**

**Solutions:**
- Make sure you deleted the old DSN
- Verify new DSN shows "MySQL ODBC 8.0" in Driver column
- Restart Tableau Desktop
- Try creating DSN in "System DSN" tab instead of "User DSN"

### **Issue: Can't find MySQL driver after installation**

**Solutions:**
- Restart ODBC Data Source Administrator
- Make sure you installed 64-bit version (if you have 64-bit Windows)
- Check if you need to install both 32-bit and 64-bit versions

---

## Quick Checklist

- [ ] Opened ODBC Data Source Administrator
- [ ] Found DSN using SQL Server driver
- [ ] Deleted wrong DSN
- [ ] Checked for MySQL driver (installed if needed)
- [ ] Created new DSN with MySQL driver
- [ ] Tested connection - "Connection successful"
- [ ] Verified Driver column shows "MySQL ODBC 8.0"
- [ ] Connected in Tableau - should work now!

---

**After completing these steps, your connection should work!** ✅



