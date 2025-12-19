# How to Use Edit Colors Dialog in Tableau

## When You See "Select Data Item" Dialog

If you see this dialog with:
- Select Data Item - 284807
- Select colour palette - automatic
- Assign palette
- Reset, OK, Cancel, Apply

**This means you need to select individual values first, then assign colors.**

---

## Step-by-Step Instructions

### Method 1: Select Individual Values

1. **In the "Select Data Item" dropdown:**
   - Click the dropdown arrow next to "Select Data Item - 284807"
   - You should see a list of values: **0** and **1**
   - **Select "0"** first

2. **Assign color to "0" (Normal):**
   - After selecting "0", look for color options
   - Click on the color box or "Select colour palette"
   - Choose **Green** color
   - Click **"Apply"** or the color will be assigned

3. **Select "1" (Fraud):**
   - Click "Select Data Item" dropdown again
   - **Select "1"**

4. **Assign color to "1" (Fraud):**
   - Click on the color box or "Select colour palette"
   - Choose **Red** color
   - Click **"Apply"**

5. **Finish:**
   - Click **"OK"** to close the dialog

---

### Method 2: Use "Assign Palette"

1. **In the Edit Colors dialog:**
   - Click **"Select colour palette"** dropdown
   - Choose a palette like:
     - **"Red-Green Diverging"** (best for 2 values)
     - **"Traffic Light"**
     - **"Color Blind 10"** (then customize)

2. **Click "Assign palette"**
   - This will automatically assign colors from the palette

3. **Customize if needed:**
   - Select each data item (0, then 1)
   - Adjust colors individually
   - Click "Apply" after each change

4. **Click "OK"** when done

---

### Method 3: Direct Color Selection

1. **Select Data Item "0":**
   - Click "Select Data Item" → Choose "0"

2. **Click on the color box** (if visible)
   - A color picker should appear
   - Select **Green**
   - Click "Apply"

3. **Select Data Item "1":**
   - Click "Select Data Item" → Choose "1"

4. **Click on the color box**
   - Select **Red**
   - Click "Apply"

5. **Click "OK"**

---

## If You Don't See 0 and 1 in the Dropdown

**The dropdown might be showing aggregated values. Try this:**

1. **Click "Reset"** to clear current settings

2. **Look for a list or table** in the dialog showing your values
   - You might see a table with:
     - Value | Color
     - 0     | [color box]
     - 1     | [color box]

3. **Click directly on the color boxes** next to each value
   - Click color box next to "0" → Choose Green
   - Click color box next to "1" → Choose Red

4. **Click "OK"**

---

## Alternative: Use the Color Palette Directly

If the individual selection is confusing:

1. **Click "Select colour palette"** dropdown
2. **Choose "Red-Green Diverging"** or **"Traffic Light"**
3. **Click "Assign palette"**
4. **Click "OK"**

This will automatically assign:
- Green/light color to lower value (0)
- Red/dark color to higher value (1)

---

## Visual Guide

```
Edit Colors Dialog:
┌─────────────────────────────┐
│ Select Data Item: [0 ▼]     │ ← Click here, select 0
│                             │
│ Select colour palette:      │
│ [Automatic ▼]               │
│                             │
│ [Color Box] ← Click here    │ ← Click to choose color
│                             │
│ [Assign palette] [Reset]    │
│                             │
│ [OK] [Cancel] [Apply]      │
└─────────────────────────────┘
```

---

## Quick Steps Summary

1. **Click "Select Data Item"** → Choose **"0"**
2. **Click color box** → Choose **Green** → Click **"Apply"**
3. **Click "Select Data Item"** → Choose **"1"**
4. **Click color box** → Choose **Red** → Click **"Apply"**
5. **Click "OK"**

---

## Troubleshooting

### Issue: Can't find 0 and 1 in dropdown
**Solution:** Look for a table/list in the dialog showing values, or click "Reset" first

### Issue: Color box not visible
**Solution:** Try "Select colour palette" → Choose a palette → "Assign palette"

### Issue: Changes not applying
**Solution:** Make sure to click "Apply" after each color change, then "OK" at the end

### Issue: Still seeing gradient instead of distinct colors
**Solution:** Make sure you converted to discrete, and try "Reset" then reassign colors

---

**Try Method 1 first - selecting each value individually and assigning colors!** ✅



