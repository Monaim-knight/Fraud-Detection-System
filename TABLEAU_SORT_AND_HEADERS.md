# How to Sort and Show Column Headers in Tableau

## Problem: No Column Headers and Can't Sort

When building visualizations, you need to:
1. Show column headers
2. Sort in descending order

---

## Show Column Headers

### Method 1: Right-Click on Chart
1. **Right-click** anywhere on the chart/visualization area
2. Look for **"Show Header"** or **"Show Column Headers"**
3. Click it to show headers

### Method 2: Format Menu
1. Click **"Format"** menu at the top
2. Select **"Show Headers"** or **"Headers"**
3. Check the options to show row/column headers

### Method 3: Right-Click on Axis
1. **Right-click** on the axis (where numbers/values appear)
2. Look for header options
3. Enable "Show Header"

---

## Sort in Descending Order

### Method 1: Click Column Header (Easiest)

1. **Look for the column header** at the top of your bars/chart
   - It might say "AVG(fraud_probability)" or similar
   - If you don't see it, show headers first (see above)

2. **Click on the column header**
   - A sort icon (up/down arrow) should appear

3. **Click the sort icon** to toggle:
   - First click: Ascending (low to high)
   - Second click: Descending (high to low) ← **Use this!**

### Method 2: Right-Click Column Header

1. **Right-click** on the column header
2. Select **"Sort"**
3. Choose **"Descending"**

### Method 3: Right-Click Field in Rows Shelf

1. **Right-click** on `customer_id` (or the field in Rows shelf)
2. Select **"Sort..."**
3. In Sort dialog:
   - Choose **"Sort by Field"**
   - Select **"AVG(fraud_probability)"** (or your measure)
   - Choose **"Descending"**
   - Click **"OK"**

### Method 4: Use Sort Icon on Toolbar

1. **Select the field** you want to sort by (in Rows or Columns shelf)
2. Look for **sort icons** in the toolbar
3. Click the **descending arrow** (↓)

---

## For High-Risk Customers Visualization

### Complete Steps:

1. **Drag `customer_id` to Rows shelf**
2. **Drag `fraud_probability` to Columns shelf**
3. **Right-click `fraud_probability`** → "Measure" → "Average"
4. **Show headers:**
   - Right-click chart → "Show Header"
5. **Sort descending:**
   - Click column header "AVG(fraud_probability)"
   - Click sort icon → Choose descending
   - OR: Right-click `customer_id` in Rows → "Sort" → "Sort by Field" → "AVG(fraud_probability)" → "Descending"
6. **Limit to top 20:**
   - Right-click `customer_id` → "Filter" → "Top" tab
   - Select "Top 20" → "By: AVG(fraud_probability)" → "Descending"
   - Click "OK"

---

## Visual Guide

```
Chart Area:
┌─────────────────────────────────┐
│ AVG(fraud_probability)  [↓]    │ ← Click here to sort
├─────────────────────────────────┤
│ Customer 1  ████████           │
│ Customer 2  ██████             │
│ Customer 3  █████████          │
└─────────────────────────────────┘
```

**Click the column header to sort!**

---

## Troubleshooting

### Issue: Can't see column header
**Solution:**
- Right-click chart → "Show Header"
- Or Format → Show Headers

### Issue: Sort icon doesn't appear
**Solution:**
- Make sure you're clicking directly on the column header text
- Try right-clicking the header → "Sort"
- Or use Method 3 (right-click field in shelf)

### Issue: Sort not working
**Solution:**
- Make sure you have a measure (not just dimensions)
- Try sorting from the Rows shelf instead
- Check that the field is aggregated (Average, Sum, etc.)

---

## Quick Reference

**Show Headers:**
- Right-click chart → "Show Header"

**Sort Descending:**
- Click column header → Click sort icon → Descending
- OR: Right-click field in shelf → "Sort" → "Descending"

**That's it!** ✅



