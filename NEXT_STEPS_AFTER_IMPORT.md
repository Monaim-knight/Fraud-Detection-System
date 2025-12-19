# Next Steps After Importing Data to MySQL

## ✅ You've Completed:
- [x] Created MySQL database
- [x] Created transactions table
- [x] Imported transaction data

---

## 📋 Next Steps Checklist

### **Step 1: Verify Data Import** ⏱️ 1 minute

**In MySQL Workbench, run these queries:**

```sql
-- Check total number of transactions
SELECT COUNT(*) AS total_transactions FROM transactions;

-- Check fraud distribution
SELECT 
    actual_label,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM transactions), 2) AS percentage
FROM transactions
GROUP BY actual_label;

-- Check date range
SELECT 
    MIN(transaction_date) AS earliest_date,
    MAX(transaction_date) AS latest_date
FROM transactions;

-- Sample data check
SELECT * FROM transactions LIMIT 10;
```

**Expected Results:**
- Total transactions: Should match your CSV file (e.g., 284,807)
- Fraud cases: Should be ~0.17% of total
- Dates: Should be in September 2013
- Sample data: Should show all 7 columns

---

### **Step 2: Create Tableau Views** ⏱️ 2-3 minutes

**This is the most important step!**

1. **Open MySQL Workbench**
2. **Select your database:**
   - Double-click your database name in SCHEMAS (it should become BOLD)
   - OR run: `USE fraud_detection_db;`

3. **Open the SQL script:**
   - File → Open SQL Script (or `Ctrl + O`)
   - Navigate to: `C:\Users\monai\OneDrive - student.uni-halle.de\Desktop\Billie`
   - Select: **`prepare_tableau_data_mysql.sql`**
   - Click Open

4. **Execute the script:**
   - Click the ⚡ lightning bolt icon
   - OR press `Ctrl + Shift + Enter`
   - Wait for completion (you'll see "0 row(s) affected" - this is normal!)

5. **Verify views were created:**
   - In SCHEMAS panel, expand your database
   - Expand "Views" folder
   - You should see 7 views:
     - ✅ `tableau_fraud_data`
     - ✅ `tableau_summary_stats`
     - ✅ `tableau_psi_data`
     - ✅ `tableau_psi_score`
     - ✅ `tableau_queue_overview`
     - ✅ `tableau_feature_psi`
     - ✅ `tableau_feature_psi_scores`

6. **Test a view:**
   ```sql
   SELECT COUNT(*) FROM tableau_fraud_data;
   ```
   - Should return the same number as your transactions table

---

### **Step 3: Connect Tableau to MySQL** ⏱️ 2-3 minutes

1. **Open Tableau Desktop**
2. **Connect to Data:**
   - Click "Connect to Data"
   - Select **"MySQL"** from the list

3. **Enter Connection Details:**
   ```
   Server: localhost
   Port: 3306
   Database: fraud_detection_db
   Username: root (or your MySQL username)
   Password: [your MySQL password]
   ```

4. **Test Connection:**
   - Click "Sign In" or "Test Connection"
   - Should see "Connection successful"

5. **Select Your Views:**
   - In the left panel, find your database
   - Navigate to "Views"
   - Drag `tableau_fraud_data` to the canvas
   - Click "Sheet 1" to start building

---

### **Step 4: Build Your Dashboard** ⏱️ 30-60 minutes

**Follow the main dashboard guide:** `TABLEAU_DASHBOARD_GUIDE.md`

**Key Components to Build:**

1. **Fraud Capture Rate Sheet:**
   - Use `tableau_fraud_data` view
   - Calculate: `SUM([true_positive]) / SUM([actual_label])`

2. **False Positive Rate Sheet:**
   - Use `tableau_fraud_data` view
   - Calculate: `SUM([false_positive]) / SUM([Total Legitimate])`

3. **PSI Monitoring Sheet:**
   - Use `tableau_psi_score` view
   - Show drift status over time

4. **Queue Overview Sheet:**
   - Use `tableau_queue_overview` view
   - Show queue metrics by analyst

5. **Summary Dashboard:**
   - Combine all sheets
   - Add filters and actions

---

### **Step 5: Configure Data Refresh** ⏱️ 5 minutes

**Choose one:**

**Option A: Live Connection (Real-time)**
- Data → Connection Type → Live
- Data refreshes automatically when you open workbook
- Best for real-time monitoring

**Option B: Extract (Better Performance)**
- Data → Extract Data
- Set refresh schedule
- Better for large datasets
- Can schedule automatic refresh

---

## 🎯 Quick Reference

### **Files You Need:**
- ✅ `prepare_tableau_data_mysql.sql` - Run this in MySQL Workbench
- ✅ `TABLEAU_DASHBOARD_GUIDE.md` - Follow this to build dashboard
- ✅ `TABLEAU_SQL_CONNECTION_GUIDE.md` - Reference guide

### **Views Available:**
- `tableau_fraud_data` - Main data view (use for most visualizations)
- `tableau_summary_stats` - Daily aggregated statistics
- `tableau_psi_score` - Overall PSI scores for drift monitoring
- `tableau_feature_psi_scores` - Feature-level PSI scores
- `tableau_queue_overview` - Queue metrics for operations

### **Common Issues:**

**Views show "Empty set":**
- Check if `transactions` table has data
- Run: `SELECT COUNT(*) FROM transactions;`

**Can't connect Tableau to MySQL:**
- Make sure MySQL service is running
- Check username/password
- Verify port 3306 is not blocked

**Views not appearing:**
- Refresh SCHEMAS panel (right-click → Refresh All)
- Make sure database is selected before running script

---

## ✅ Success Checklist

- [ ] Data verified in transactions table
- [ ] Views created successfully (7 views visible)
- [ ] Views show data (not empty)
- [ ] Tableau connected to MySQL
- [ ] Can see views in Tableau
- [ ] Dashboard components built
- [ ] Data refresh configured

---

## 🚀 You're Ready!

Once you complete these steps, you'll have:
- ✅ MySQL database with transaction data
- ✅ Tableau views ready for visualization
- ✅ Tableau connected to MySQL
- ✅ Dashboard ready to build

**Next:** Follow `TABLEAU_DASHBOARD_GUIDE.md` to build your fraud detection dashboard!

---

**Need Help?** Check `TABLEAU_SQL_CONNECTION_GUIDE.md` for detailed troubleshooting.



