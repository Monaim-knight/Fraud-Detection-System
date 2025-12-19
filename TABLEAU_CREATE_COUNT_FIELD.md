# How to Create Count Calculated Field in Tableau

## Quick Answer

**Yes, you need to write something in the formula box!**

When creating the Count field:
- **Name:** `Count` (or any name)
- **Formula:** Just type `1` (the number one)

---

## Step-by-Step: Create Count Field

### Step 1: Open Calculated Field Dialog

1. **In the left sidebar** (data pane)
2. **Right-click** in an empty area (not on a field name)
3. Select **"Create Calculated Field..."**

### Step 2: Enter Name and Formula

1. **Name field:** Type `Count` (or `Record Count` or any name you prefer)

2. **Formula box:** Type just this:
   ```
   1
   ```
   - That's it! Just the number **1**
   - No quotes, no brackets, just the digit 1

3. **Check:** Tableau should show "The calculation is valid" (green checkmark)

4. **Click "OK"**

### Step 3: Use the Count Field

1. **Drag `Count` to Columns or Rows shelf**
2. **Right-click `Count`** → **"Measure"** → **"Sum"**
   - This sums all the 1s, which counts each record
   - Example: 100 records = 100 ones = Sum of 100

---

## Why This Works

- Each row gets a value of 1
- When you sum all the 1s, you get the total count of records
- Example: 5 rows = 1+1+1+1+1 = 5 (count of 5 records)

---

## Alternative: Use Existing Measure (Easier!)

**You don't actually need to create a calculated field!**

### Option 1: Use Any Measure's Count

1. **Drag any measure** (like `amount`) to Columns shelf
2. **Right-click it** → **"Measure"** → **"Count"**
3. This counts non-null values - works perfectly!

### Option 2: Look for Automatic Count

- Check if Tableau already created a count measure
- Look for "CNT(amount)" or similar in your measures list
- Use that if available

---

## Visual Guide

```
Create Calculated Field Dialog:
┌─────────────────────────────┐
│ Name: Count                 │ ← Type name here
│                             │
│ Formula:                    │
│ ┌─────────────────────────┐ │
│ │ 1                       │ │ ← Type just "1"
│ └─────────────────────────┘ │
│                             │
│ [OK] [Cancel] [Apply]      │
└─────────────────────────────┘
```

---

## Summary

**To create Count field:**
- Name: `Count`
- Formula: `1` (just the number one)
- Then use it with "Sum" aggregation

**OR use the easier method:**
- Drag any measure → Right-click → "Measure" → "Count"
- No calculated field needed!

---

**The easier method (Option 2) is recommended - no calculated field needed!** ✅



