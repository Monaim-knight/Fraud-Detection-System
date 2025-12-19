# Setting Colors When You See Palette Options

## Problem
When you right-click the color legend, you see:
- Palette-Automatic
- Start-automatic
- Centre-automatic
- End-automatic
- Stepped color
- Reverse
- And numbers (like 492)

**This means Tableau is treating your field as continuous (numeric) instead of discrete (categorical).**

---

## Solution: Make fraud_prediction Discrete

### Method 1: Change Field to Discrete (Recommended)

1. **In the left sidebar (data pane):**
   - Find `fraud_prediction` in your fields list
   - **Right-click** on `fraud_prediction`
   - Select **"Convert to Discrete"** (or "Change Data Type" → "String")
   - The icon should change from a # (number) to Abc (text/string)

2. **Remove and re-add to Color:**
   - Drag `fraud_prediction` OFF the Color shelf
   - Drag `fraud_prediction` BACK to the Color shelf
   - Now right-click the color legend again

3. **You should now see "Edit Colors..." option:**
   - Right-click color legend → "Edit Colors..."
   - Assign Green to 0, Red to 1

---

### Method 2: Use the Palette Menu You're Seeing

If you want to use the palette options you're seeing:

1. **Right-click color legend** (you're already here)
2. **Select "Palette"** → Choose a color scheme:
   - Try "Red-Green Diverging" or "Traffic Light"
   - This will automatically assign colors to your values

3. **To customize further:**
   - After selecting a palette, look for "Edit Colors" option
   - Or try double-clicking the color legend

---

### Method 3: Create a String Version of fraud_prediction

1. **Create a calculated field:**
   - Right-click in data pane → "Create Calculated Field"
   - Name: `fraud_status`
   - Formula:
     ```
     IF [fraud_prediction] = 1 THEN "Fraud"
     ELSE "Normal"
     END
     ```
   - Click "OK"

2. **Use this new field instead:**
   - Drag `fraud_status` to **Color** on Marks card
   - Right-click color legend → "Edit Colors..."
   - Set: "Fraud" = Red, "Normal" = Green

---

### Method 4: Use the Stepped Color Option

1. **Right-click color legend** → Select **"Stepped Color"**
2. **Set number of steps:**
   - Choose 2 steps (for 0 and 1)
3. **Then customize:**
   - You should be able to set colors for each step

---

## Quick Fix: Try This First

**The easiest solution:**

1. **In left sidebar, find `fraud_prediction`**
2. **Right-click it** → **"Convert to Discrete"**
3. **Remove it from Color shelf** (drag it off)
4. **Drag it back to Color shelf**
5. **Right-click color legend** → You should now see **"Edit Colors..."**

---

## What Each Option Does

- **Palette-Automatic:** Color scheme for gradient
- **Start-automatic:** Starting color of gradient
- **Centre-automatic:** Middle color of gradient
- **End-automatic:** Ending color of gradient
- **Stepped color:** Creates distinct color steps instead of gradient
- **Reverse:** Reverses the color order
- **Numbers (492, etc.):** Color values or steps

**For discrete values (0 and 1), you want "Edit Colors" not these palette options.**

---

## Verify It's Working

After converting to discrete:
- The color legend should show individual values (0, 1) not a gradient
- Right-clicking should show "Edit Colors..." option
- You can assign specific colors to each value

---

**Try Method 1 first - it's the most straightforward!** ✅



