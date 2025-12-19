# Install MySQL ODBC Driver - Step by Step

## Problem
You're seeing these drivers in ODBC:
- Microsoft Access dBASE Driver
- Microsoft Access TEXT Driver
- Microsoft Excel Driver
- ODBC Driver 18 for SQL Server
- SQL Server

**But NO MySQL drivers!** ❌

**This means MySQL ODBC driver is not installed on your computer.**

---

## ✅ Solution: Install MySQL ODBC Driver

### **STEP 1: Download MySQL Connector/ODBC**

1. **Open your web browser**
2. **Go to this URL:**
   ```
   https://dev.mysql.com/downloads/connector/odbc/
   ```
3. **On the download page:**
   - Look for **"Windows (x86, 64-bit), MSI Installer"** or **"Windows (x64, 64-bit), MSI Installer"**
   - This is usually the first option
   - Click the **"Download"** button next to it

4. **You might see a login prompt:**
   - Click **"No thanks, just start my download"** (at the bottom)
   - The file will start downloading

5. **Wait for download to complete**
   - File name will be something like: `mysql-connector-odbc-8.0.xx-winx64.msi`
   - Usually downloads to your "Downloads" folder

---

### **STEP 2: Install the Driver**

1. **Find the downloaded file:**
   - Go to your Downloads folder
   - Look for: `mysql-connector-odbc-8.0.xx-winx64.msi`

2. **Double-click the file** to start installation

3. **If Windows asks for permission:**
   - Click **"Yes"** to allow the installer to run

4. **Follow the installation wizard:**
   - **Welcome screen:** Click **"Next"**
   - **License Agreement:** Select "I accept" → Click **"Next"**
   - **Setup Type:** Choose **"Complete"** → Click **"Next"**
   - **Ready to Install:** Click **"Install"**
   - **Wait for installation** (takes 1-2 minutes)
   - **Installation Complete:** Click **"Finish"**

---

### **STEP 3: Verify Installation**

1. **Close ODBC Data Source Administrator** (if it's open)

2. **Open ODBC Data Source Administrator again:**
   - Press `Windows Key + R`
   - Type: `odbcad32.exe`
   - Press Enter

3. **Click "Add" button**

4. **Look at the driver list:**
   - You should NOW see:
     - ✅ **"MySQL ODBC 8.0 Unicode Driver"**
     - ✅ **"MySQL ODBC 8.0 ANSI Driver"**
   - These are the MySQL drivers you need!

5. **If you see MySQL drivers:** ✅ Success! Continue to Step 4
6. **If you DON'T see MySQL drivers:** See troubleshooting below

---

### **STEP 4: Create MySQL DSN**

Now that MySQL driver is installed:

1. **In ODBC Data Source Administrator:**
   - Click **"Add"** button
   - **Select:** "MySQL ODBC 8.0 Unicode Driver" (or ANSI Driver)
   - ❌ **DO NOT select:** "ODBC Driver 18 for SQL Server"
   - Click **"Finish"**

2. **Configure the connection:**
   - **Data Source Name:** `MySQL_Tableau`
   - **Description:** (leave blank or type "MySQL for Tableau")
   - **TCP/IP Server:** `localhost`
   - **Port:** `3306`
   - **User:** `root` (or your MySQL username)
   - **Password:** `[enter your MySQL password]`
   - **Database:** `fraud_detection_db`

3. **Test the connection:**
   - Click **"Test"** button
   - Should see: **"Connection successful"** ✅
   - If error, check:
     - MySQL service is running
     - Username/password is correct
     - Database name is correct

4. **Click "OK"** to save

---

### **STEP 5: Verify DSN is Correct**

1. **Back in the DSN list:**
   - Find your `MySQL_Tableau` DSN
   - **Check the "Driver" column**
   - Should say: **"MySQL ODBC 8.0 Unicode Driver"** ✅
   - Should NOT say: "ODBC Driver 18 for SQL Server" ❌

---

### **STEP 6: Connect in Tableau**

1. **Open Tableau Desktop**
2. **Select:** "Other Databases (ODBC)"
3. **Enter:**
   - **Name:** `MySQL_Fraud_Detection`
   - **Description:** `MySQL database` (optional)
   - **Server/DSN:** `MySQL_Tableau`
4. **Click "Connect"**

**This time it should work!** ✅

---

## Troubleshooting

### **Issue: Can't find the download link**

**Alternative download method:**
1. Go to: https://dev.mysql.com/downloads/connector/odbc/
2. Scroll down to find "Windows (x86, 64-bit), MSI Installer"
3. Click the download icon (arrow pointing down)
4. Choose "No thanks, just start my download"

### **Issue: Installation fails**

**Solutions:**
- Make sure you're running installer as Administrator:
  - Right-click the `.msi` file
  - Select "Run as administrator"
  - Try installing again

### **Issue: Still don't see MySQL drivers after installation**

**Solutions:**
1. **Restart your computer** (sometimes needed)
2. **Check if you installed 64-bit version:**
   - If you have 64-bit Windows, install 64-bit driver
   - If you have 32-bit Windows, install 32-bit driver
3. **Try installing both 32-bit and 64-bit versions:**
   - Some systems need both
4. **Check installation location:**
   - Driver should be in: `C:\Program Files\MySQL\Connector ODBC 8.0\`
   - If missing, reinstall

### **Issue: "Connection failed" when testing**

**Check:**
- MySQL service is running:
  - Press `Windows Key + R`
  - Type: `services.msc`
  - Press Enter
  - Look for "MySQL" service
  - Should be "Running"
  - If not, right-click → "Start"
- Username and password are correct
- Database name is correct (case-sensitive in some MySQL versions)
- Port 3306 is correct

---

## Quick Checklist

- [ ] Downloaded MySQL Connector/ODBC from official website
- [ ] Installed the driver (Complete installation)
- [ ] Closed and reopened ODBC Data Source Administrator
- [ ] Verified MySQL drivers appear in the list
- [ ] Created new DSN with MySQL driver (NOT SQL Server!)
- [ ] Tested connection - "Connection successful"
- [ ] Verified Driver column shows "MySQL ODBC 8.0"
- [ ] Connected in Tableau - should work now!

---

## Direct Download Link

**If the website is confusing, try this direct link:**
- Go to: https://dev.mysql.com/downloads/connector/odbc/
- Look for: **"Windows (x86, 64-bit), MSI Installer"** (version 8.0.x or 8.1.x)
- Click download

**Or search for:** "MySQL Connector ODBC Windows download"

---

**After installing the MySQL driver, you'll be able to create the correct DSN and connect successfully!** ✅



