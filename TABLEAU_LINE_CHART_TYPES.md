# Which Line Chart Type to Use in Tableau

## For Fraud Trends Over Time

When you see three line chart options:
- **Line (discrete)**
- **Line (continuous)**
- **Dual line**

## Answer: Use "Line (continuous)"

**For showing fraud trends over time, use "Line (continuous)"**

### Why "Line (continuous)"?
- Shows smooth trends over time
- Best for date/time data
- Connects all points with a continuous line
- Most common for time series analysis

### When to use each:

**Line (continuous):**
- ✅ **Use this for fraud trends over time**
- Shows continuous time series
- Best for dates (transaction_date)
- Smooth line connecting all points

**Line (discrete):**
- Use for categorical data
- Shows separate points for each category
- Good for comparing distinct groups
- Not ideal for time trends

**Dual line:**
- Use when comparing TWO different measures
- Example: Comparing amount and fraud_probability on same chart
- Requires two different measures
- Not needed for simple fraud trends

---

## Quick Steps

1. **Drag `transaction_date` to Columns**
2. **Drag `amount` to Rows**
3. **Right-click `amount` → "Measure" → "Count"** (to count records)
4. **Drag `fraud_prediction` to Color**
5. **Click "Show Me" → Select "Line (continuous)"**

---

## If You Don't Have "Number of Records"

**Use any measure's count function:**

1. **Drag `amount` to Rows shelf**
2. **Right-click `amount`** → **"Measure"** → **"Count"**
3. This counts all records (same as "Number of Records")

**OR create a calculated field:**

1. Right-click in data pane → "Create Calculated Field"
2. Name: `Count`
3. Formula: `1`
4. Click "OK"
5. Drag `Count` to Rows
6. Right-click `Count` → "Measure" → "Sum"

---

**Use "Line (continuous)" for your fraud trends chart!** ✅



