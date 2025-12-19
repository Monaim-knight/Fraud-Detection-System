# How to Set Colors in Tableau - Step by Step

## Setting Colors for Fraud Detection Visualization

### Method 1: Using Edit Colors (Recommended)

**Step 1: Add field to Color**
1. Drag `fraud_prediction` to the **Color** shelf on the **Marks** card (bottom left)
2. A color legend will automatically appear on the right side of your screen

**Step 2: Open Edit Colors dialog**
1. **Right-click** on the color legend (the colored box showing your values)
2. Select **"Edit Colors..."** from the dropdown menu
3. The "Edit Colors" dialog box will open

**Step 3: Assign colors to values**
1. In the dialog, you'll see a list of your values (0 and 1)
2. **For value "0" (Normal transactions):**
   - Click on the **color box** next to "0"
   - A color palette will appear
   - Select **Green** (or any green shade you prefer)
   - Or click **"More Colors"** for more options
3. **For value "1" (Fraud transactions):**
   - Click on the **color box** next to "1"
   - Select **Red** (or any red shade you prefer)
   - Or click **"More Colors"** for more options
4. Click **"OK"** to apply the colors

**Result:** Your bars/chart will now show:
- Green = Normal transactions (0)
- Red = Fraud transactions (1)

---

### Method 2: Using Format Legend

**If "Edit Colors" doesn't appear:**

1. **Right-click** on the color legend
2. Select **"Format Legend..."**
3. In the Format pane (usually on the left):
   - Look for color options
   - Click on individual color boxes to change them

---

### Method 3: Using the Marks Card Directly

1. Click on the **Color** button on the Marks card (where you dragged `fraud_prediction`)
2. A color palette will appear
3. You can:
   - Select a color scheme from the dropdown
   - Click individual color boxes to customize
   - Use the "Edit Colors" option at the bottom

---

## Custom Color Schemes

### Creating a Custom Color Palette

1. **Right-click** color legend → **"Edit Colors..."**
2. Click **"More Colors"** for any value
3. In the color picker:
   - Use the color wheel to select exact shades
   - Or enter RGB/HEX values
   - Click **"OK"** when done

### Recommended Colors for Fraud Detection

**Standard Scheme:**
- **Normal (0):** Green - RGB(76, 175, 80) or #4CAF50
- **Fraud (1):** Red - RGB(244, 67, 54) or #F44336

**Alternative Schemes:**
- **Normal (0):** Light Blue - RGB(33, 150, 243)
- **Fraud (1):** Orange - RGB(255, 152, 0)

- **Normal (0):** Gray - RGB(158, 158, 158)
- **Fraud (1):** Dark Red - RGB(183, 28, 28)

---

## Setting Colors for Multiple Values

If you have more than 2 values (e.g., 0, 1, 2):

1. Follow Method 1 above
2. In "Edit Colors" dialog, you'll see all values listed
3. Assign a color to each value
4. Tableau will automatically create a gradient if needed

---

## Using Color Intensity (Gradient)

For continuous measures (like `fraud_probability`):

1. Drag `fraud_probability` to **Color** on Marks card
2. Tableau will automatically create a gradient
3. **To customize:**
   - Right-click color legend → **"Edit Colors..."**
   - Select a color scheme (e.g., "Red-Blue Diverging")
   - Adjust the range and center point
   - Click **"OK"**

---

## Troubleshooting

### Issue: Color legend doesn't appear
**Solution:**
- Make sure you've dragged a field to the Color shelf
- Check that the field is in the Marks card

### Issue: Can't find "Edit Colors" option
**Solution:**
- Try right-clicking directly on the color legend (not the field name)
- Or double-click the color legend
- Or click the Color button on Marks card → Look for "Edit Colors" at bottom

### Issue: Colors not changing
**Solution:**
- Make sure you clicked "OK" in the Edit Colors dialog
- Try refreshing the view (right-click sheet → "Refresh")

### Issue: Want to reset to default colors
**Solution:**
- Right-click color legend → "Edit Colors" → Click "Reset" or "Default"

---

## Quick Reference

**To set colors:**
1. Drag field to **Color** on Marks card
2. Right-click color legend → **"Edit Colors..."**
3. Click color box → Choose color → Click **"OK"**

**To remove colors:**
- Drag the field off the Color shelf, OR
- Right-click on Color shelf → "Remove"

**To change color scheme:**
- Right-click color legend → "Edit Colors" → Select different scheme

---

## Visual Guide

```
Marks Card (bottom left):
┌─────────────────┐
│ Color           │ ← Drag fraud_prediction here
│ Size            │
│ Label           │
│ Detail          │
│ Tooltip         │
└─────────────────┘

Color Legend (right side):
┌─────────────────┐
│ fraud_prediction│
│                 │
│ 0  [Green]      │ ← Right-click here
│ 1  [Red]        │
└─────────────────┘
```

---

**That's it! Your visualization should now show green for normal transactions and red for fraud transactions.** ✅



