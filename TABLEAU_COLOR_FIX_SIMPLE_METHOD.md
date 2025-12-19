# Simple Method to Set Colors When Dropdown Doesn't Work

## Problem
You can't select 0 or 1 from the "Select Data Item" dropdown in Edit Colors dialog.

## Solution: Use "Assign Palette" Method (Easiest)

### Step 1: In the Edit Colors Dialog

1. **Click "Select colour palette"** dropdown
2. **Choose one of these palettes:**
   - **"Red-Green Diverging"** (best for fraud detection)
   - **"Traffic Light"**
   - **"Color Blind 10"**

3. **Click "Assign palette"** button
   - This automatically assigns colors to your values
   - Lower value (0) gets one color
   - Higher value (1) gets the other color

4. **Click "OK"**

**Done!** Your chart should now show different colors for 0 and 1.

---

## Alternative: Create a Text Field (Most Reliable)

If the palette method doesn't give you the exact colors you want:

### Step 1: Create Calculated Field

1. **In left sidebar**, right-click in empty area → **"Create Calculated Field"**
2. **Name:** `fraud_status`
3. **Formula:**
   ```
   IF [fraud_prediction] = 1 THEN "Fraud"
   ELSE "Normal"
   END
   ```
4. **Click "OK"**

### Step 2: Use the New Field

1. **Remove `fraud_prediction` from Color shelf** (drag it off)
2. **Drag `fraud_status` to Color shelf** instead
3. **Right-click color legend** → **"Edit Colors..."**
4. **Now you should see:**
   - "Fraud" with a color box
   - "Normal" with a color box
5. **Click color box next to "Fraud"** → Choose **Red**
6. **Click color box next to "Normal"** → Choose **Green**
7. **Click "OK"**

**This method always works because text fields show individual values clearly!**

---

## Alternative: Use the Color Palette Directly

### Without Opening Edit Colors

1. **Right-click the color legend**
2. **Select "Palette"** → **"Red-Green Diverging"**
3. Colors should update automatically

---

## Alternative: Double-Click Method

1. **Double-click the color legend** (instead of right-click)
2. This might open a different color dialog
3. Look for individual value selection there

---

## Check: Is the Field Really Discrete?

Make sure `fraud_prediction` is discrete:

1. **In left sidebar**, look at `fraud_prediction`
2. **It should show as "Abc" icon** (text/discrete)
3. **If it shows "#" icon** (number/continuous):
   - Right-click it → **"Convert to Discrete"**
   - Remove from Color shelf
   - Add back to Color shelf
   - Try Edit Colors again

---

## Recommended: Use the Text Field Method

**The most reliable solution is to create the `fraud_status` calculated field** (Alternative method above). This always works because:
- Text fields are always discrete
- You see clear labels ("Fraud" and "Normal")
- Color assignment is straightforward
- No dropdown confusion

---

## Quick Summary

**Easiest:** Use "Assign Palette" method
**Most Reliable:** Create `fraud_status` text field

**Try the "Assign Palette" method first - it's the quickest!** ✅



