# Tableau Dashboard Guide
## Interactive Fraud Detection Monitoring Dashboard

**Date:** [Current Date]  
**Purpose:** Create comprehensive fraud detection monitoring dashboard  
**Tool:** Tableau Desktop/Tableau Public

---

## Dashboard Overview

This guide will help you create an interactive Tableau dashboard with 4 key components:

1. **Fraud Capture Rate** - Blocked fraud / Total fraud
2. **False Positive Rate** - Blocked legitimate / Total legitimate
3. **Drift Monitoring** - Population Stability Index (PSI)
4. **Case Queue Overview** - Operations team queue management

---

## Prerequisites

### Required Software
- Tableau Desktop (recommended) or Tableau Public (free)
- Access to your fraud detection data

### Required Data
- Transaction data with predictions
- Fraud labels (actual vs predicted)
- Timestamps for drift monitoring
- Queue status for operations

---

## Step 1: Data Preparation

### 1.1 Prepare Your Data Source

Create a CSV or connect to your database with the following columns:

**Required Columns:**
- `transaction_id` - Unique transaction identifier
- `transaction_date` - Date/time of transaction
- `fraud_probability` - Model prediction probability
- `fraud_prediction` - Binary prediction (0/1)
- `actual_label` - Actual fraud status (0/1)
- `decision` - Action taken (AUTO_BLOCK, REVIEW_QUEUE, AUTO_APPROVE)
- `queue_status` - For ops team (PENDING, IN_REVIEW, RESOLVED)
- `amount` - Transaction amount
- `customer_id` - Customer identifier

**Sample Data Structure:**
```csv
transaction_id,transaction_date,fraud_probability,fraud_prediction,actual_label,decision,queue_status,amount,customer_id
1,2024-01-01 10:00:00,0.85,1,1,AUTO_BLOCK,RESOLVED,150.00,C001
2,2024-01-01 10:05:00,0.02,0,0,AUTO_APPROVE,RESOLVED,50.00,C002
3,2024-01-01 10:10:00,0.35,1,0,REVIEW_QUEUE,IN_REVIEW,200.00,C003
```

### 1.2 Create Calculated Fields in Data Source (Optional)

You can add these in Tableau, but preparing them in your data source is easier:

```sql
-- SQL example (if using database)
SELECT 
  transaction_id,
  transaction_date,
  fraud_probability,
  fraud_prediction,
  actual_label,
  decision,
  queue_status,
  amount,
  customer_id,
  -- Calculated fields
  CASE WHEN actual_label = 1 AND fraud_prediction = 1 THEN 1 ELSE 0 END AS true_positive,
  CASE WHEN actual_label = 0 AND fraud_prediction = 1 THEN 1 ELSE 0 END AS false_positive,
  CASE WHEN actual_label = 1 AND fraud_prediction = 0 THEN 1 ELSE 0 END AS false_negative,
  CASE WHEN actual_label = 0 AND fraud_prediction = 0 THEN 1 ELSE 0 END AS true_negative,
  CASE WHEN decision = 'AUTO_BLOCK' THEN 1 ELSE 0 END AS blocked,
  CASE WHEN decision = 'REVIEW_QUEUE' THEN 1 ELSE 0 END AS in_queue
FROM transactions
```

---

## Step 2: Connect Tableau to Data

### 2.1 Open Tableau Desktop

1. Launch Tableau Desktop
2. Click "Connect to Data"

### 2.2 Connect to Your Data Source

**Option A: CSV File**
1. Select "Text file" or "Microsoft Excel"
2. Browse to your CSV file
3. Click "Open"
4. Review data preview
5. Click "Sheet 1" to start building

**Option B: Database**
1. Select your database type (SQL Server, MySQL, etc.)
2. Enter connection details
3. Select your table/view
4. Click "Sheet 1"

### 2.3 Verify Data Connection

- Check that all required columns are present
- Verify data types are correct
- Ensure date fields are recognized as dates

---

## Step 3: Create Calculated Fields

### 3.1 Navigate to Calculated Fields

1. Right-click in the Data pane (left side)
2. Select "Create Calculated Field"
3. Enter the field name (provided below for each field)
4. Enter the formula
5. Click "OK"

### 3.2 Required Calculated Fields

> **Important:** The formulas below assume your Tableau field names match your CSV/SQL schema.  
> In your Tableau data, these appear as **`Actual Label`** and **`Fraud Prediction`** (with spaces and capital letters).  
> Use **exactly** those names in the formulas:
> - `[Actual Label]` instead of `[actual_label]`
> - `[Fraud Prediction]` instead of `[fraud_prediction]`

**1. Field Name: `True Positive`**
```
IF [Actual Label] = 1 AND [Fraud Prediction] = 1 THEN 1 ELSE 0 END
```

**2. Field Name: `False Positive`**
```
IF [Actual Label] = 0 AND [Fraud Prediction] = 1 THEN 1 ELSE 0 END
```

**3. Field Name: `False Negative`**
```
IF [Actual Label] = 1 AND [Fraud Prediction] = 0 THEN 1 ELSE 0 END
```

**4. Field Name: `True Negative`**
```
IF [Actual Label] = 0 AND [Fraud Prediction] = 0 THEN 1 ELSE 0 END
```

**5. Field Name: `Blocked Transactions`**
```
IF [decision] = "AUTO_BLOCK" THEN 1 ELSE 0 END
```

**6. Field Name: `Total Fraud`**
```
SUM([Actual Label])
```

**7. Field Name: `Total Legitimate`**
```
IF [Actual Label] = 0 THEN 1 ELSE 0 END
```

**8. Field Name: `Blocked Fraud`**
```
SUM([True Positive])
```

**9. Field Name: `Blocked Legitimate`**
```
SUM([False Positive])
```

**10. Field Name: `Fraud Capture Rate`**
```
SUM([True Positive]) / SUM([Actual Label])
```

**11. Field Name: `False Positive Rate`**
```
// Recommended safe version
IF SUM(IF [Actual Label] = 0 THEN 1 ELSE 0 END) > 0 THEN
    SUM([False Positive]) / SUM(IF [Actual Label] = 0 THEN 1 ELSE 0 END)
ELSE
    0
END
```

**Note:** When using these in visualizations, Tableau will automatically aggregate them.  
If you already created `Total Legitimate` as a row-level field (`IF [Actual Label] = 0 THEN 1 ELSE 0 END`),  
you can also use:
`IF SUM([Total Legitimate]) > 0 THEN SUM([False Positive]) / SUM([Total Legitimate]) ELSE 0 END`

**12. Field Name: `In Queue`**
```
IF [queue_status] = "IN_REVIEW" OR [queue_status] = "PENDING" THEN 1 ELSE 0 END
```

**13. Field Name: `Queue Age Hours`**
```
DATEDIFF('hour', [queue_created_date], NOW())
```

**14. Field Name: `Revenue Lost to False Positives`**
```
SUM(IF [False Positive] = 1 THEN [amount] ELSE 0 END)
```

**15. Field Name: `PSI Status`**

**⚠️ IMPORTANT:** This field requires `psi_score` to exist in your data. If you don't have PSI data yet, **SKIP THIS FIELD** and come back to it later.

**Option A: If `psi_score` field exists in your data**
```
IF ISNULL([psi_score]) THEN "No Data"
ELSEIF [psi_score] < 0.10 THEN "No Drift"
ELSEIF [psi_score] < 0.25 THEN "Minor Drift"
ELSE "Major Drift"
END
```

**Option B: If using aggregated PSI (from SQL view)**
```
IF ISNULL(AVG([psi_score])) THEN "No Data"
ELSEIF AVG([psi_score]) < 0.10 THEN "No Drift"
ELSEIF AVG([psi_score]) < 0.25 THEN "Minor Drift"
ELSE "Major Drift"
END
```

**Option C: Skip this field (if PSI not available yet)**
- Don't create this field if `psi_score` doesn't exist
- You can add it later when PSI data is available
- For now, focus on other dashboard components

**16. Field Name: `Drift Alert`**

**⚠️ IMPORTANT:** Same as above - requires `psi_score` field.

**Option A: If `psi_score` field exists**
```
IF ISNULL([psi_score]) THEN "NO DATA"
ELSEIF [psi_score] >= 0.25 THEN "CRITICAL"
ELSEIF [psi_score] >= 0.10 THEN "WARNING"
ELSE "OK"
END
```

**Option B: Skip this field (if PSI not available yet)**
- Don't create this field if `psi_score` doesn't exist
- Add it later when PSI data is available

**Alternative: If using aggregated PSI score**
If `psi_score` is already aggregated (e.g., from `tableau_psi_score` view), use:
```
IF AVG([psi_score]) IS NULL THEN "No Data"
ELSEIF AVG([psi_score]) < 0.10 THEN "No Drift"
ELSEIF AVG([psi_score]) < 0.25 THEN "Minor Drift"
ELSE "Major Drift"
END
```

---

## Step 4: Create Fraud Capture Rate Visualization

### 4.1 Create New Sheet

1. Click "New Worksheet" (bottom tabs)
2. Rename to "Fraud Capture Rate"

### 4.2 Build the Visualization

**Step 1: Create KPI Card**
1. Drag `Fraud Capture Rate` to Text (in Marks card)
2. Change mark type to "Text"
3. Format: Percentage, 2 decimal places
4. Add title: "Fraud Capture Rate"

**Step 2: Add Trend Line**
1. Drag `transaction_date` to Columns (set to continuous, by day/week)
2. Drag `Fraud Capture Rate` to Rows
3. Change mark type to "Line"
4. Add reference line at 0.95 (target: 95%)

**Step 3: Add Breakdown Table**
1. Create new sheet: "Fraud Capture Details"
2. Drag `transaction_date` to Rows (by month)
3. Drag these to Text:
   - `Blocked Fraud` (SUM)
   - `Total Fraud` (SUM)
   - `Fraud Capture Rate` (AVG, formatted as %)
4. Add color: Green if > 0.95, Yellow if 0.90-0.95, Red if < 0.90

**Final Layout:**
```
┌─────────────────────────┐
│  Fraud Capture Rate     │
│      95.2%              │
│  (Target: 95%)          │
├─────────────────────────┤
│  [Trend Line Chart]     │
│  (Daily/Weekly)         │
├─────────────────────────┤
│  [Monthly Breakdown]    │
│  Table with Color       │
└─────────────────────────┘
```

---

## Step 5: Create False Positive Rate Visualization

### 5.1 Create New Sheet

1. Click "New Worksheet"
2. Rename to "False Positive Rate"

### 5.2 Build the Visualization

**Step 1: Create KPI Card**
1. Drag `False Positive Rate` to Text
2. Format: Percentage, 2 decimal places
3. Add title: "False Positive Rate"

**Step 2: Add Trend Line**
1. Drag `transaction_date` to Columns
2. Drag `False Positive Rate` to Rows
3. Change mark type to "Line"
4. Add reference line at 0.02 (target: < 2%)

**Step 3: Add Impact Analysis**
1. Create calculated field: `Revenue Lost to False Positives`
   ```
   SUM(IF [False Positive] = 1 THEN [amount] ELSE 0 END)
   ```
2. Create bar chart:
   - X-axis: `transaction_date` (by week)
   - Y-axis: `Revenue Lost to False Positives`
   - Color: Red gradient

**Step 4: Add Breakdown**
1. Create table:
   - Rows: `transaction_date` (by month)
   - Columns: 
     - `Blocked Legitimate` (SUM)
     - `Total Legitimate` (SUM)
     - `False Positive Rate` (AVG, %)
   - Color: Green if < 0.02, Yellow if 0.02-0.05, Red if > 0.05

**Final Layout:**
```
┌─────────────────────────┐
│  False Positive Rate    │
│      1.8%               │
│  (Target: < 2%)         │
├─────────────────────────┤
│  [Trend Line Chart]     │
│  (Daily/Weekly)         │
├─────────────────────────┤
│  [Revenue Impact]       │
│  Bar Chart              │
├─────────────────────────┤
│  [Monthly Breakdown]    │
│  Table with Color       │
└─────────────────────────┘
```

---

## Step 6: Create Drift Monitoring (PSI) Visualization

### 6.1 Calculate Population Stability Index (PSI)

**PSI Formula:**
```
PSI = Σ((Actual % - Expected %) × ln(Actual % / Expected %))
```

**Step 1: Create PSI Calculation**

Create calculated field: `PSI Score`
```
// This is a simplified version - you'll need to calculate PSI for each feature
// For demonstration, we'll use fraud_probability distribution

VAR expected_distribution = 
  {FIXED [transaction_date]: 
    COUNTD(IF [transaction_date] <= DATEADD('day', -30, TODAY()) 
           THEN [transaction_id] END) / 
    COUNTD([transaction_id])
  }

VAR actual_distribution = 
  {FIXED [transaction_date]: 
    COUNTD([transaction_id]) / 
    COUNTD([transaction_id])
  }

// Simplified PSI calculation
// In practice, you'd calculate this for each feature bin
```

**Note:** PSI calculation in Tableau is complex. Consider:
1. Pre-calculating PSI in your data source
2. Using Tableau's built-in statistical functions
3. Creating bins for probability distribution

**Step 2: Create PSI Visualization**

**Option A: Pre-calculated PSI (Recommended)**
1. Add `psi_score` column to your data
2. Create line chart:
   - X-axis: `transaction_date` (by day)
   - Y-axis: `psi_score` (AVG)
   - Add reference lines:
     - 0.10 (Minor drift - yellow)
     - 0.25 (Major drift - red)

**Option B: Distribution Comparison**
1. Create bins for `fraud_probability`:
   - Right-click `fraud_probability` → Create → Bins
   - Bin size: 0.1 (0-0.1, 0.1-0.2, etc.)
2. Create histogram:
   - X-axis: `fraud_probability (bin)`
   - Y-axis: `COUNT([transaction_id])`
   - Color: `transaction_date` (recent vs baseline)
3. Add comparison:
   - Show baseline period (last 30 days)
   - Show current period (today)
   - Visual comparison of distributions

**Step 3: Feature-Level PSI**

For each important feature, create PSI calculation:
1. Create calculated field for each feature's PSI
2. Create heatmap:
   - Rows: Feature names
   - Columns: `transaction_date` (by week)
   - Color: PSI score (green < 0.1, yellow 0.1-0.25, red > 0.25)

**Final Layout:**
```
┌─────────────────────────┐
│  PSI Score              │
│      0.08                │
│  (Target: < 0.10)       │
├─────────────────────────┤
│  [PSI Trend Line]       │
│  (Daily with Alerts)    │
├─────────────────────────┤
│  [Distribution Compare] │
│  Histogram Overlay      │
├─────────────────────────┤
│  [Feature PSI Heatmap]  │
│  (Top 10 Features)      │
└─────────────────────────┘
```

---

## Step 7: Create Case Queue Overview

### 7.1 Create New Sheet

1. Click "New Worksheet"
2. Rename to "Case Queue Overview"

### 7.2 Build the Visualization

**Step 1: Queue Status Summary**
1. Create KPI cards:
   - `Total in Queue` = SUM([In Queue])
   - `Pending Review` = COUNTD(IF [queue_status] = "PENDING" THEN [transaction_id] END)
   - `In Review` = COUNTD(IF [queue_status] = "IN_REVIEW" THEN [transaction_id] END)
   - `Avg Wait Time` = DATEDIFF('hour', MIN([queue_created_date]), TODAY())

**Step 2: Queue Status Donut Chart**
1. Drag `queue_status` to Color
2. Drag `queue_status` to Angle (COUNT)
3. Change mark type to "Pie"
4. Add `queue_status` to Label (with count)
5. Format as donut (add white circle in center)

**Step 3: Queue by Priority**
1. Create calculated field: `Queue Priority`
   ```
   IF [fraud_probability] >= 0.80 THEN "CRITICAL"
   ELSEIF [fraud_probability] >= 0.50 THEN "HIGH"
   ELSEIF [fraud_probability] >= 0.17 THEN "MEDIUM"
   ELSE "LOW"
   END
   ```
2. Create bar chart:
   - X-axis: `Queue Priority`
   - Y-axis: COUNT([transaction_id])
   - Color: `Queue Priority` (red to green gradient)

**Step 4: Queue Age Analysis**
1. Create calculated field: **`Queue Age Hours`**
   ```
   DATEDIFF('hour', [queue_created_date], NOW())
   ```
2. Create histogram:
   - X-axis: `Queue Age (Hours)` (binned)
   - Y-axis: COUNT([transaction_id])
   - Color: Alert if > 24 hours (red)

**Step 5: Analyst Workload**
1. Create table:
   - Rows: `analyst_name` (if available)
   - Columns:
     - `Cases Assigned` (COUNT)
     - `Cases Resolved` (COUNT)
     - `Avg Resolution Time` (AVG hours)
     - `Pending Cases` (COUNT)

**Step 6: Queue Trend**
1. Create line chart:
   - X-axis: `transaction_date` (by day)
   - Y-axis: COUNT([transaction_id]) where `In Queue` = 1
   - Add reference line for target queue size

**Final Layout:**
```
┌─────────────────────────┐
│  Queue KPIs             │
│  [4 KPI Cards]          │
├─────────────────────────┤
│  [Queue Status Donut]   │
│  [Queue by Priority]    │
├─────────────────────────┤
│  [Queue Age Histogram]  │
│  [Analyst Workload]     │
├─────────────────────────┤
│  [Queue Trend Line]     │
└─────────────────────────┘
```

---

## Step 8: Build the Dashboard

### 8.1 Create Dashboard

1. Click "New Dashboard" (bottom tabs)
2. Rename to "Fraud Detection Monitoring"

### 8.2 Add Sheets to Dashboard

**Layout Structure:**
```
┌─────────────────────────────────────────────────────────┐
│  FRAUD DETECTION MONITORING DASHBOARD                   │
│  [Date Filter] [Time Range Selector]                    │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ Fraud Capture│  │ False Pos    │  │ PSI Score    │ │
│  │ Rate         │  │ Rate         │  │              │ │
│  │ 95.2%        │  │ 1.8%         │  │ 0.08         │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────────────┐  ┌──────────────────────┐    │
│  │ Fraud Capture Trend  │  │ False Positive Trend  │    │
│  │ [Line Chart]         │  │ [Line Chart]         │    │
│  └──────────────────────┘  └──────────────────────┘    │
├─────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────┐ │
│  │ Case Queue Overview                                │ │
│  │ [Queue Status] [Queue by Priority] [Queue Age]    │ │
│  └────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────┐ │
│  │ Drift Monitoring (PSI)                            │ │
│  │ [PSI Trend] [Distribution Compare] [Feature PSI] │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 8.3 Add Filters

1. **Date Range Filter:**
   - Drag `transaction_date` to Filters
   - Select "Relative Date" or "Range"
   - Show filter on dashboard

2. **Decision Type Filter:**
   - Drag `decision` to Filters
   - Allow multiple selections
   - Show filter on dashboard

3. **Queue Status Filter:**
   - Drag `queue_status` to Filters
   - Show filter on dashboard

### 8.4 Add Actions

**1. Highlight Action:**
- Dashboard → Actions → Add Action → Highlight
- Source: All sheets
- Target: All sheets
- Run action on: Select

**2. Filter Action:**
- Dashboard → Actions → Add Action → Filter
- Source: Queue Overview sheet
- Target: All other sheets
- Run action on: Select

### 8.5 Format Dashboard

1. **Title:**
   - Add text box: "Fraud Detection Monitoring Dashboard"
   - Format: Large, bold, centered

2. **Colors:**
   - Use consistent color scheme:
     - Green: Good performance
     - Yellow: Warning
     - Red: Alert/Critical

3. **Layout:**
   - Use containers for organization
   - Set fixed sizes for KPI cards
   - Allow scrolling for detailed views

---

## Step 9: Add Interactivity

### 9.1 Tooltips

For each visualization, customize tooltips:

**Example Tooltip for Fraud Capture Rate:**
```
Blocked Fraud: <SUM([True Positive])>
Total Fraud: <SUM([actual_label])>
Capture Rate: <AVG([Fraud Capture Rate])>%
Date: <transaction_date>
```

### 9.2 Parameters

**1. Parameter Name: `Target Capture Rate`**
1. Right-click in Data pane → Create Parameter
2. Name: **`Target Capture Rate`**
3. Data type: Float
4. Current value: 0.95
5. Allowable values: Range 0.80 to 1.00

**2. Calculated Field Name: `Capture Rate Status`**
Use the parameter in this calculation:
```
IF [Fraud Capture Rate] >= [Target Capture Rate] THEN "Above Target"
ELSE "Below Target"
END
```

**3. Parameter Name: `Target False Positive Rate`**
1. Right-click in Data pane → Create Parameter
2. Name: **`Target False Positive Rate`**
3. Data type: Float
4. Current value: 0.02
5. Allowable values: Range 0.00 to 0.10

**4. Calculated Field Name: `False Positive Rate Status`**
```
IF [False Positive Rate] <= [Target False Positive Rate] THEN "Within Target"
ELSE "Above Target"
END
```

### 9.3 Dynamic Labels

Add conditional formatting:
- Green if above target
- Yellow if near target
- Red if below target

---

## Step 10: Publish and Share

### 10.1 Save Workbook

1. File → Save As
2. Name: "Fraud_Detection_Dashboard.twbx"
3. Save to desired location

### 10.2 Publish to Tableau Server (if available)

1. Server → Publish Workbook
2. Enter server details
3. Set permissions
4. Schedule refresh (if using live data)

### 10.3 Export Options

1. **PDF Export:**
   - Dashboard → Export Image/PDF
   - Useful for reports

2. **Image Export:**
   - Right-click visualization → Copy → Image
   - Use in presentations

---

## Step 11: Data Refresh Setup

### 11.1 Live Connection

If using database:
1. Data → Edit Data Source
2. Select "Live" connection
3. Set refresh schedule on server

### 11.2 Extract Refresh

If using extracts:
1. Data → Extract Data
2. Set refresh schedule
3. Configure incremental refresh if possible

---

## Advanced Features

### 11.1 Alerts

Set up alerts for:
- Fraud capture rate < 90%
- False positive rate > 5%
- PSI > 0.25
- Queue size > 100

### 11.2 Custom SQL

For complex calculations, use Custom SQL:
```sql
SELECT 
  transaction_date,
  COUNT(*) as total_transactions,
  SUM(CASE WHEN actual_label = 1 AND fraud_prediction = 1 THEN 1 ELSE 0 END) as tp,
  SUM(CASE WHEN actual_label = 1 THEN 1 ELSE 0 END) as total_fraud,
  SUM(CASE WHEN actual_label = 1 AND fraud_prediction = 1 THEN 1 ELSE 0 END) * 1.0 / 
  NULLIF(SUM(CASE WHEN actual_label = 1 THEN 1 ELSE 0 END), 0) as capture_rate
FROM transactions
GROUP BY transaction_date
```

### 11.3 Performance Optimization

1. Use extracts for large datasets
2. Hide unused fields
3. Use data source filters
4. Optimize calculations

---

## Troubleshooting

### Common Issues

**1. PSI Calculation Too Complex**
- Pre-calculate PSI in data source
- Use Python/R script to calculate
- Import pre-calculated PSI values

**2. Slow Performance**
- Create extracts
- Use data source filters
- Limit date ranges
- Hide unused fields

**3. Missing Data**
- Check data connections
- Verify date formats
- Ensure all required columns exist

---

## Quick Reference: Key Calculations

### Fraud Capture Rate
```
SUM([True Positive]) / SUM([actual_label])
```

### False Positive Rate
```
SUM([False Positive]) / SUM([Total Legitimate])
```

### PSI (Simplified)
```
// Pre-calculate in data source or use Python/R
// Formula: Σ((Actual % - Expected %) × ln(Actual % / Expected %))
```

### Queue Metrics
```
Total in Queue: SUM([In Queue])
Avg Wait Time: AVG([Queue Age (Hours)])
```

---

## Next Steps

1. ✅ **Build Dashboard** - Follow steps 1-10
2. ⏭️ **Test with Sample Data** - Verify all calculations
3. ⏭️ **Get Feedback** - Share with ops team
4. ⏭️ **Iterate** - Add requested features
5. ⏭️ **Deploy** - Publish to Tableau Server
6. ⏭️ **Monitor** - Track usage and performance

---

**Document Version:** 1.0  
**Last Updated:** [Current Date]  
**Tool:** Tableau Desktop/Public  
**Estimated Time:** 4-6 hours for complete dashboard

