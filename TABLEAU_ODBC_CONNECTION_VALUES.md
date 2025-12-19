# Tableau ODBC Connection - What to Enter

## When Tableau Asks for Connection Details

If Tableau is asking for:
- **Name**
- **Description** 
- **Server**

Here's exactly what to enter:

---

## Option 1: If You Created ODBC DSN (Recommended)

**Name:** 
```
MySQL_Fraud_Detection
```
(Or any name you want - this is just for Tableau to remember the connection)

**Description:** 
```
MySQL database for fraud detection dashboard
```
(Optional - you can leave this blank)

**Server/DSN:** 
```
MySQL_Tableau
```
(This is the DSN name you created in ODBC Data Source Administrator)

**Then click "Connect" or "OK"**

---

## Option 2: If You Need to Enter Connection String Directly

If Tableau asks for a connection string instead of DSN:

**Name:** 
```
MySQL_Fraud_Detection
```

**Description:** 
```
MySQL database for fraud detection dashboard
```

**Server/Connection String:** 
```
DRIVER={MySQL ODBC 8.0 Unicode Driver};SERVER=localhost;PORT=3306;DATABASE=fraud_detection_db;USER=root;PASSWORD=your_password;
```

**⚠️ Important:** Replace `your_password` with your actual MySQL password!

**Example if your password is "mypassword123":**
```
DRIVER={MySQL ODBC 8.0 Unicode Driver};SERVER=localhost;PORT=3306;DATABASE=fraud_detection_db;USER=root;PASSWORD=mypassword123;
```

---

## Option 3: If Tableau Shows Different Fields

If Tableau shows different fields, here's what they mean:

**Data Source Name (DSN):** `MySQL_Tableau`

**OR if it asks for individual fields:**
- **Server:** `localhost`
- **Port:** `3306`
- **Database:** `fraud_detection_db`
- **Username:** `root`
- **Password:** `[your MySQL password]`

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Name** | `MySQL_Fraud_Detection` |
| **Description** | `MySQL database for fraud detection dashboard` (optional) |
| **Server/DSN** | `MySQL_Tableau` (if you created ODBC DSN) |
| **OR Server** | `localhost` (if entering directly) |
| **Port** | `3306` |
| **Database** | `fraud_detection_db` |
| **Username** | `root` |
| **Password** | `[your MySQL password]` |

---

## Authentication Options

**If Tableau asks "How should SQL server verify the authenticity of the login ID":**

**⚠️ NOTE:** This question is for SQL Server, but you're using MySQL. Here's what to do:

**Option 1: Use Windows Authentication (if available)**
- Select "Windows Authentication"
- This uses your Windows login credentials
- **Note:** This usually doesn't work for MySQL - MySQL uses its own authentication

**Option 2: Use SQL Server Authentication (Recommended for MySQL)**
- Select "SQL Server Authentication" or "Use a specific username and password"
- Enter:
  - **Username:** `root` (or your MySQL username)
  - **Password:** `[your MySQL password]`
- This is the standard way MySQL authenticates

**Option 3: If Using ODBC DSN**
- The authentication is already configured in the ODBC DSN
- You shouldn't need to enter username/password again
- Just select the DSN and connect

---

## After Connecting

Once connected successfully:
1. You'll see your database in the left panel
2. Navigate to **"Views"** folder
3. Select **`tableau_fraud_data`** view
4. Click "Sheet 1" to start building your dashboard

---

---

## SQL Server Connection Options (When Connecting to MySQL via ODBC)

**If Tableau shows SQL Server-specific options, here's what to check:**

These options are for SQL Server, but since you're using MySQL via ODBC, most don't apply. Here's what to do:

### **Options to Check/Uncheck:**

✅ **Use ANSI quoted identifiers:** 
- **Check this** (helps with compatibility)

✅ **Use ANSI nulls, paddings and warnings:**
- **Check this** (helps with compatibility)

❌ **Change the default database to:**
- **Leave blank** or **uncheck** (MySQL uses the database from your DSN)

❌ **Mirror Server:**
- **Leave blank** or **uncheck** (MySQL doesn't use mirror servers)

❌ **Attach database filename:**
- **Leave blank** or **uncheck** (Not applicable to MySQL)

### **Recommended Settings:**

**For MySQL connection, check these:**
- ✅ Use ANSI quoted identifiers
- ✅ Use ANSI nulls, paddings and warnings

**Leave these blank/unchecked:**
- ❌ Change the default database to (already set in DSN)
- ❌ Mirror Server
- ❌ Attach database filename

**Then click "OK" or "Connect"**

---

**Need help?** Make sure you created the ODBC DSN first (see `TABLEAU_MYSQL_CONNECTION_SETUP.md`)

