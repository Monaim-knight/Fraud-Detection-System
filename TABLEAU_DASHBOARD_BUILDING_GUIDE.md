# Step-by-Step Guide: Building Your Fraud Detection Dashboard in Tableau

## Overview
This guide will walk you through creating a comprehensive fraud detection dashboard using your exported MySQL data.

---

## Part 1: Connect to Your Data

### Step 1.1: Open Tableau Desktop
1. Launch **Tableau Desktop**
2. You'll see the start screen with connection options

### Step 1.2: Connect to CSV File
1. On the left sidebar, under **"Connect"**, click **"Text file"**
2. Navigate to your project folder:
   ```
   C:\Users\monai\OneDrive - student.uni-halle.de\Desktop\Billie\tableau_exports\
   ```
3. Select **`tableau_fraud_data.csv`** (recommended starting point)
4. Click **"Open"**

### Step 1.3: Review Your Data
1. Tableau will show a preview of your data
2. Check that columns are recognized correctly:
   - **Dimensions** (blue): `customer_id`, `transaction_date`, etc.
   - **Measures** (green): `amount`, `fraud_probability`, etc.
3. If needed, click **"Update Now"** to refresh the data
4. Click **"Sheet 1"** at the bottom to start building

---

## Part 2: Understanding Your Data Fields

### Key Fields in `tableau_fraud_data.csv`:

**Dimensions (Blue - Categorical):**
- `customer_id` - Unique customer identifier
- `transaction_date` - Date/time of transaction
- `fraud_prediction` - Predicted fraud (0=Normal, 1=Fraud)
- `actual_label` - Actual fraud status (0=Normal, 1=Fraud)

**Measures (Green - Numerical):**
- `amount` - Transaction amount
- `fraud_probability` - Probability of fraud (0-1)
- Other feature columns (V1, V2, etc.)

---

## Part 3: Create Your First Visualization

### Visualization 1: Fraud Detection Overview

**Goal:** Show overall fraud statistics

1. **Create a new sheet:**
   - Right-click "Sheet 1" → "Rename" → Type "Fraud Overview"

2. **Build the visualization:**
   - Drag `fraud_prediction` to **Rows** shelf
   - **Option 1: Create Count Calculated Field:**
     - Right-click in the data pane (left sidebar) → **"Create Calculated Field"**
     - **Name:** Type `Count` (or any name you want)
     - **Formula box:** Type just the number `1` (that's it - just the digit 1)
     - Click **"OK"**
     - Drag `Count` to **Columns** shelf
     - Right-click `Count` → **"Measure"** → **"Sum"** (this sums all the 1s to count records)
   - **Option 2: Use existing measure (Easier):**
     - Drag any measure (like `amount`) to **Columns** shelf
     - Right-click it → **"Measure"** → **"Count"** (this counts non-null values)
     - This is simpler - no calculated field needed!
   - **Option 3:** If you see "CNT" or "COUNT" of any field in your measures, use that
   - Right-click `fraud_prediction` → "Format" → Change to "Discrete" if needed
   - You'll see a bar chart showing fraud vs normal transactions

3. **Add labels:**
   - Drag the same count measure to the **Label** shelf (on the Marks card)
   - Right-click the label → "Format" → Show as percentage if desired

4. **Color code:**
   - **IMPORTANT: Make fraud_prediction discrete first:**
     - In the left sidebar, find `fraud_prediction`
     - **Right-click** on `fraud_prediction` → Select **"Convert to Discrete"**
     - The icon should change from # (number) to Abc (text)
   - Drag `fraud_prediction` to **Color** on the Marks card (you'll see it appear in the Marks card)
   - A color legend will appear on the right side of your screen
   - **To edit colors:**
     - **Right-click** on the color legend (the box showing 0 and 1 with colors)
     - **If you see "Edit Colors..."** → Select it
     - **If you see palette options instead:**
       - The field is still continuous - make sure you converted it to discrete (step above)
       - Or try: Right-click color legend → "Stepped Color" → Set to 2 steps
   - **In the Edit Colors dialog:**
     - **EASIEST METHOD - Use "Assign Palette":**
       - Click **"Select colour palette"** dropdown → Choose **"Red-Green Diverging"**
       - Click **"Assign palette"** button (automatically assigns colors to 0 and 1)
       - Click **"OK"** - Done!
     - **If dropdown doesn't show 0 and 1:**
       - **Create a text field instead** (see Alternative method below)
     - **If you can select individual values:**
       - Click **"Select Data Item"** dropdown → Select **"0"**
       - Click color box → Choose **Green** → Click **"Apply"**
       - Click **"Select Data Item"** dropdown → Select **"1"**
       - Click color box → Choose **Red** → Click **"Apply"**
       - Click **"OK"**
   - **ALTERNATIVE - Create Text Field (Most Reliable):**
     - Right-click in data pane → **"Create Calculated Field"**
     - Name: `fraud_status`
     - **Formula (type exactly, no backticks):**
       ```
       IF [fraud_prediction] = 1 THEN "Fraud" ELSE "Normal" END
       ```
     - **If you get an error:**
       - Check that `fraud_prediction` field name matches exactly
       - If field is text, use: `IF [fraud_prediction] = "1" THEN "Fraud" ELSE "Normal" END`
       - Or try: `IF INT([fraud_prediction]) = 1 THEN "Fraud" ELSE "Normal" END`
     - Click **"OK"** when formula shows as valid (green checkmark)
     - Remove `fraud_prediction` from Color shelf
     - Drag `fraud_status` to Color shelf instead
     - Right-click color legend → **"Edit Colors..."**
     - Click color box next to **"Fraud"** → Choose **Red**
     - Click color box next to **"Normal"** → Choose **Green**
     - Click **"OK"**
   - **If you still see palette options:**
     - Create a calculated field: `fraud_status` with formula: `IF [fraud_prediction] = 1 THEN "Fraud" ELSE "Normal" END`
     - Use `fraud_status` instead of `fraud_prediction` for colors

---

### Visualization 2: Fraud Over Time

**Goal:** Show fraud trends by date

1. **Create new sheet:** "Fraud Trends"

2. **Build the visualization:**
   - Drag `transaction_date` to **Columns** shelf
   - **For count (since "Number of Records" doesn't exist):**
     - Drag `amount` (or any measure) to **Rows** shelf
     - Right-click `amount` → **"Measure"** → **"Count"** (this counts all records)
     - OR use your Count calculated field if you created one
   - Drag `fraud_prediction` to **Color** on Marks card
   - **Change chart type:**
     - Click **"Show Me"** button (top right toolbar)
     - Select **"Line (continuous)"** (best for time trends - use this one!)
     - **Don't use:** "Line (discrete)" or "Dual line" for this visualization
   - **Or keep as bar chart:** Right-click date → "Month" or "Day" to group dates

3. **Add trend line:**
   - Right-click chart → "Trend Lines" → "Show Trend Lines"

---

### Visualization 3: Transaction Amount Distribution

**Goal:** Compare amounts for fraud vs normal transactions

1. **Create new sheet:** "Amount Analysis"

2. **Build the visualization:**
   - Drag `amount` to **Columns** shelf
   - Drag `fraud_prediction` to **Rows** shelf
   - Drag your count measure to **Size** on Marks card, OR drag `amount` → Right-click → "Measure" → "Count"
   - Change chart type: Click "Show Me" → Select "Box Plot"
   - This shows distribution of amounts for fraud vs normal

3. **Alternative - Histogram:**
   - Drag `amount` to **Columns** shelf
   - Right-click `amount` → "Create" → "Bins" → Set bin size (e.g., 100)
   - Drag your count measure to **Rows** shelf, OR drag `amount` → Right-click → "Measure" → "Count"
   - Drag `fraud_prediction` to **Color**

---

### Visualization 4: Fraud Probability Distribution

**Goal:** Show distribution of fraud probabilities

1. **Create new sheet:** "Fraud Probability"

2. **Build the visualization:**
   - Drag `fraud_probability` to **Columns** shelf
   - Right-click `fraud_probability` → "Create" → "Bins" → Set bin size (e.g., 0.1)
   - Drag your count measure to **Rows** shelf, OR drag `fraud_probability` → Right-click → "Measure" → "Count"
   - Drag `actual_label` to **Color** (to compare predictions vs actual)
   - This creates a histogram showing probability distribution

---

### Visualization 5: Top Customers by Fraud Risk

**Goal:** Identify high-risk customers

1. **Create new sheet:** "High-Risk Customers"

2. **Build the visualization:**
   - Drag `customer_id` to **Rows** shelf
   - Drag `fraud_probability` to **Columns** shelf
   - Right-click `fraud_probability` → "Measure" → "Average"
   - **To show column headers:**
     - Right-click on the chart area → "Show Header" (if not visible)
     - Or: Format → Show Headers
   - **To sort in descending order:**
     - **Method 1:** Click on the **column header** (the "AVG(fraud_probability)" text at the top of the bars)
     - A sort icon (up/down arrow) will appear
     - Click it to toggle between ascending/descending
     - OR right-click the column header → "Sort" → "Descending"
     - **Method 2:** Right-click `customer_id` in Rows shelf → "Sort" → Choose "Sort by Field" → Select "AVG(fraud_probability)" → "Descending" → "OK"
   - **To add size (optional):**
     - Drag `amount` to **Size** on Marks card → Right-click → "Measure" → "Count" (or use Sum)
   - **To limit to top customers:**
     - Right-click `customer_id` in Rows shelf → "Filter"
     - In filter dialog: Select "Top" tab
     - Choose "By field" → Select "Top 20" → "By: AVG(fraud_probability)" → "Descending"
     - Click "OK"

---

### Visualization 6: Confusion Matrix

**Goal:** Show prediction accuracy

1. **Create new sheet:** "Confusion Matrix"

2. **Build the visualization:**
   - Drag `actual_label` to **Columns** shelf
   - Drag `fraud_prediction` to **Rows** shelf
   - Drag your count measure to **Text** on Marks card, OR drag any measure → Right-click → "Measure" → "Count"
   - Change chart type: Click "Show Me" → Select "Text Table"
   - Add color: Drag the same count measure to **Color** → Adjust color scale

3. **Add percentages:**
   - **Option A (Show both count and percentage):**
     - Right-click your count measure in the Data pane → "Duplicate"
     - Right-click the duplicated measure → "Quick Table Calculation" → "Percent of Total"
     - Drag the duplicated measure (now showing percentages) to **Text** shelf alongside the original count
   - **Option B (Replace count with percentage):**
     - Right-click the count measure already on **Text** shelf → "Quick Table Calculation" → "Percent of Total"
     - This will replace the count with percentages in the same field

---

## Part 4: Create a Dashboard

### Step 4.1: Create New Dashboard

1. Click **"New Dashboard"** button at the bottom (or Dashboard → New Dashboard)
2. Name it: "Fraud Detection Dashboard"

### Step 4.2: Add Visualizations

1. **Drag sheets to the dashboard:**
   - Drag "Fraud Overview" to the top-left
   - Drag "Fraud Trends" to the top-right
   - Drag "Amount Analysis" below "Fraud Overview"
   - Drag "Fraud Probability" below "Fraud Trends"
   - Drag "High-Risk Customers" to the bottom
   - Drag "Confusion Matrix" to the bottom-right

2. **Resize and arrange:**
   - Drag corners to resize each visualization
   - Arrange them in a logical layout

### Step 4.3: Add Filters

**Where to find Filters in Dashboard view:**

In the **left sidebar**, look for the **"Objects"** section. It should contain items like:
- **Text**
- **Image**
- **Web Page**
- **Blank**
- **Add Filter** (or **Filter**)

**If you don't see "Objects" section:**
- Make sure you're in **Dashboard** view (click the Dashboard tab at the bottom)
- The left sidebar should show: Dashboard pane → Objects → Sheets

**Steps to add filters:**

1. **Add date filter:**
   - **Method 1 (Using Objects - Recommended):**
     - In the left sidebar, find the **"Objects"** section
     - Look for **"Add Filter"** or **"Filter"** in that list
     - **Drag "Add Filter"** from Objects onto the dashboard canvas (or double-click it)
     - A dialog box will appear showing **all available fields from your data source**
     - Select `transaction_date` from the list and click **OK**
     - The filter will appear on your dashboard
   
   - **Method 2 (From a sheet on dashboard - Easiest):**
     - Right-click any sheet that's already on your dashboard (e.g., "Fraud Trends")
     - From the context menu, select **"Use as Filter"**
     - This automatically creates a filter based on that sheet's data
   
   - **Method 3 (If you see data fields):**
     - Switch to a Sheet view temporarily
     - Drag `transaction_date` from the data fields onto the dashboard
     - Or: In Dashboard view, if data fields are visible, drag directly

2. **Add fraud prediction filter:**
   - **Easiest:** Right-click a sheet on dashboard → **"Use as Filter"**
   - **Or:** Drag "Add Filter" from Objects → Select `fraud_prediction` from dialog

3. **Add amount filter:**
   - Drag "Add Filter" from Objects → Select `amount` from dialog
   - Right-click the filter on dashboard → "Edit Filter" → Set range (e.g., 0 to 10000)

**Alternative: Add filter from sheet context menu:**
- Right-click any sheet on your dashboard
- Look for **"Use as Filter"** in the context menu
- This is often the quickest way to add filters!

**Alternative method (if you want to add filters from data fields):**
- Drag a field (e.g., `transaction_date`) directly from the data fields list onto the dashboard canvas
- Tableau will automatically create a filter for that field

**Note:** The **"Objects"** section in the left sidebar contains options like "Add Filters", "Add Text", "Add Image", etc. Use "Add Filters" to add filter controls to your dashboard.

### Step 4.4: Add Title and Formatting

1. **Add title:**
   - Drag "Text" object to top of dashboard
   - Type: "Fraud Detection Dashboard"
   - Format: Large, bold font

2. **Format dashboard:**
   - Right-click dashboard → "Format Dashboard"
   - Set background color, borders, etc.

3. **Add summary text:**
   - Drag another "Text" object
   - Add key metrics or notes

### Step 4.5: Make Dashboard Full Screen

**Option 1: Full Screen Mode (Presentation Mode)**
1. While viewing your dashboard, press **F11** (Windows) or **F11** (Mac)
2. Or go to **Window** → **Full Screen**
3. Press **Esc** to exit full screen mode

**Option 2: Set Dashboard Size to Full Screen**
1. In the dashboard view, look at the **Dashboard** pane on the left
2. Under **Size**, click the dropdown (default is usually "Automatic" or "Fixed Size")
3. Select **"Desktop Browser"** or **"Desktop Browser - Fixed"**
4. Or select **"Custom"** and set:
   - Width: `1920` pixels (or your screen width)
   - Height: `1080` pixels (or your screen height)

**Option 3: Presentation Mode (Best for Sharing)**
1. Go to **Window** → **Presentation Mode**
2. This hides all Tableau UI elements (toolbar, menus, etc.)
3. Press **Esc** to exit presentation mode

**Option 4: Adjust Dashboard Layout for Full Screen**
1. In the **Dashboard** pane, set **Size** to **"Desktop Browser"**
2. Set **Layout** to **"Fixed"** if you want exact pixel control
3. Adjust individual sheet sizes to fill the available space
4. Use **Objects** → **Container** to organize sheets and make them responsive

**Tip:** For best results, use **Presentation Mode (F11)** when presenting, and set dashboard size to **"Desktop Browser"** for consistent viewing.

---

## Part 5: Advanced Features

### 5.1: Create Calculated Fields

**Create "Fraud Rate" calculation:**

1. Right-click in data pane → "Create Calculated Field"
2. Name: "Fraud Rate"
3. Formula:
   ```
   SUM(IF [fraud_prediction] = 1 THEN 1 ELSE 0 END) / COUNT([fraud_prediction])
   ```
4. Click "OK"
5. Use this field in visualizations

**Create "High Risk Flag" calculation:**

1. Create calculated field: "High Risk"
2. Formula:
   ```
   IF [fraud_probability] >= 0.7 THEN "High Risk"
   ELSEIF [fraud_probability] >= 0.5 THEN "Medium Risk"
   ELSE "Low Risk"
   END
   ```
3. Use this for risk categorization

### 5.2: Create Parameters

**Create "Probability Threshold" parameter:**

1. Right-click in data pane → "Create Parameter"
2. Name: "Probability Threshold"
3. Data type: Float
4. Current value: 0.5
5. Range: 0 to 1
6. Use this parameter to dynamically filter high-risk transactions

### 5.3: Add Actions

**Add highlight action:**

1. Dashboard → "Actions"
2. Click "Add Action" → "Highlight"
3. Source sheets: Select all sheets
4. Target sheets: Select all sheets
5. This allows clicking on one visualization to highlight related data in others

---

## Part 6: Best Practices for Fraud Detection Dashboards

### 6.1: Key Metrics to Display

- **Overall fraud rate** (percentage)
- **Total fraud amount** (sum of fraudulent transactions)
- **Number of high-risk transactions** (fraud_probability > threshold)
- **Prediction accuracy** (from confusion matrix)
- **False positive rate**
- **False negative rate**

### 6.2: Visual Design Tips

1. **Color coding:**
   - Red = Fraud/High Risk
   - Green = Normal/Low Risk
   - Yellow/Orange = Medium Risk

2. **Layout:**
   - Put most important metrics at the top
   - Group related visualizations together
   - Use consistent sizing

3. **Interactivity:**
   - Add tooltips with detailed information
   - Use filters to allow drilling down
   - Add actions for cross-filtering

### 6.3: Performance Optimization

1. **Limit data:**
   - Use date filters to limit time range
   - Filter out unnecessary columns
   - Use data extracts instead of live connections

2. **Optimize calculations:**
   - Pre-calculate complex formulas
   - Use aggregations where possible

---

## Part 7: Export and Share

### Step 7.1: Save Your Workbook

1. File → "Save As"
2. Name: "Fraud_Detection_Dashboard.twbx"
3. Choose location and save

### Step 7.2: Export Dashboard as Image

1. Dashboard → "Export Image"
2. Choose format (PNG, PDF, etc.)
3. Save for presentations

### Step 7.3: Publish to Tableau Server (Optional)

1. Server → "Publish Workbook"
2. Enter server details
3. Choose project and permissions
4. Publish

---

## Quick Reference: Common Tasks

### Change Chart Type
- Click "Show Me" button (top right)
- Select desired chart type

### Format Numbers
- Right-click measure → "Format"
- Choose number format, decimals, etc.

### Add Tooltips
- Drag fields to "Tooltip" on Marks card
- Customize tooltip text

### Create Groups
- Right-click dimension → "Create Group"
- Manually group categories

### Create Sets
- Right-click dimension → "Create Set"
- Define conditions (e.g., Top 10 customers)

---

## Troubleshooting

### Issue: Data not updating
**Solution:** Data → "Refresh" or "Update Now"

### Issue: Wrong data types
**Solution:** Right-click field → "Change Data Type"

### Issue: Calculations not working
**Solution:** Check syntax, use Tableau's formula editor help

### Issue: Dashboard too slow
**Solution:** Use data extracts, limit data range, optimize calculations

---

## Next Steps

1. ✅ Connect to your CSV file
2. ✅ Create basic visualizations
3. ✅ Build dashboard
4. ✅ Add filters and interactivity
5. ✅ Refine and customize
6. ✅ Share with stakeholders

**You're ready to build your fraud detection dashboard!** 🎉

Start with the basic visualizations and gradually add more advanced features as you become comfortable with Tableau.

