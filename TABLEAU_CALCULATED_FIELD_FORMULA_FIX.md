# Fix Calculated Field Formula Error

## Correct Formula (No Backticks)

When creating the calculated field, use this **exact formula**:

```
IF [fraud_prediction] = 1 THEN "Fraud" ELSE "Normal" END
```

**Important:** 
- No backticks (`) around the formula
- No quotes around the formula
- Just type it directly into the formula box

---

## Step-by-Step: Create the Calculated Field

### Step 1: Open Calculated Field Dialog

1. **In the left sidebar** (data pane)
2. **Right-click** in an empty area (not on a field)
3. Select **"Create Calculated Field..."**

### Step 2: Enter Details

1. **Name:** Type `fraud_status` (or any name you prefer)

2. **Formula box:** Type this exactly:
   ```
   IF [fraud_prediction] = 1 THEN "Fraud" ELSE "Normal" END
   ```

3. **Check syntax:**
   - Tableau should show "The calculation is valid" (green checkmark)
   - If you see red X, check the formula

4. **Click "OK"**

---

## Common Errors and Fixes

### Error 1: "Unknown field [fraud_prediction]"

**Fix:** 
- Make sure the field name matches exactly
- Check spelling: `fraud_prediction` (not `fraud_predicition` or `fraud_predictions`)
- The field name should appear in blue in the formula editor

### Error 2: "Cannot compare integer and string"

**Fix:**
- `fraud_prediction` might be a string, try:
  ```
  IF [fraud_prediction] = "1" THEN "Fraud" ELSE "Normal" END
  ```
- Or convert to number:
  ```
  IF INT([fraud_prediction]) = 1 THEN "Fraud" ELSE "Normal" END
  ```

### Error 3: "Syntax error"

**Fix:**
- Make sure you have spaces around operators
- Check that all quotes match (use double quotes for text)
- Make sure END is at the end

---

## Alternative Formulas to Try

### If fraud_prediction is numeric (0, 1):
```
IF [fraud_prediction] = 1 THEN "Fraud" ELSE "Normal" END
```

### If fraud_prediction is text ("0", "1"):
```
IF [fraud_prediction] = "1" THEN "Fraud" ELSE "Normal" END
```

### If fraud_prediction might be null:
```
IF [fraud_prediction] = 1 THEN "Fraud" 
ELSEIF [fraud_prediction] = 0 THEN "Normal"
ELSE "Unknown"
END
```

### Using INT() to convert:
```
IF INT([fraud_prediction]) = 1 THEN "Fraud" ELSE "Normal" END
```

---

## How to Check Field Type

1. **Look at `fraud_prediction` in the left sidebar:**
   - **# icon** = Number (use: `= 1`)
   - **Abc icon** = Text/String (use: `= "1"`)

2. **Or check in the data:**
   - Look at sample values
   - Numbers: 0, 1
   - Text: "0", "1"

---

## Step-by-Step with Screenshots Guide

1. **Right-click in data pane** → "Create Calculated Field"

2. **Dialog opens:**
   ```
   Name: fraud_status
   
   Formula:
   ┌─────────────────────────────────────┐
   │ IF [fraud_prediction] = 1 THEN      │
   │   "Fraud"                           │
   │ ELSE                                │
   │   "Normal"                          │
   │ END                                 │
   └─────────────────────────────────────┘
   ```

3. **As you type, Tableau will:**
   - Show field names in blue
   - Highlight syntax
   - Show error if invalid

4. **Click "OK"** when formula is valid

---

## Troubleshooting

### If formula still shows error:

1. **Check field name:**
   - Click the dropdown arrow in formula editor
   - Select `fraud_prediction` from the list (don't type it)
   - This ensures correct spelling

2. **Try simpler formula first:**
   ```
   [fraud_prediction]
   ```
   - If this works, the field exists
   - Then add the IF statement

3. **Check data type:**
   - Right-click `fraud_prediction` → "Properties"
   - Check the data type
   - Adjust formula accordingly

---

## Quick Test

**Test if field exists:**
1. Create calculated field
2. Name: `test`
3. Formula: `[fraud_prediction]`
4. If this works, field exists
5. Then add IF statement

---

**Try the formula without backticks, and make sure the field name matches exactly!** ✅



