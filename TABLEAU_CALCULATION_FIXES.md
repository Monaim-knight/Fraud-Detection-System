# Tableau Calculation Fixes
## Common Errors and Solutions

**Purpose:** Fix common calculation errors in Tableau dashboard

---

## Error: "The calculation contains errors"

### Issue 1: False Positive Rate Calculation

**Error Message:**
```
The calculation contains errors
```

**Problem:**
The formula tries to use `SUM([Total Legitimate])` but `Total Legitimate` might already be aggregated, causing a double aggregation error.

**Solution 1: Use Inline Calculation (Recommended)**
```
SUM([False Positive]) / SUM(IF [actual_label] = 0 THEN 1 ELSE 0 END)
```

**Solution 2: If Total Legitimate is a Row-Level Field**
If `Total Legitimate` is defined as:
```
IF [actual_label] = 0 THEN 1 ELSE 0 END
```
Then use:
```
SUM([False Positive]) / SUM([Total Legitimate])
```

**Solution 3: Use ATTR() for Non-Aggregated Fields**
```
SUM([False Positive]) / ATTR([Total Legitimate])
```

---

## Error: "Cannot mix aggregate and non-aggregate arguments"

### Issue 2: Fraud Capture Rate

**Error Message:**
```
Cannot mix aggregate and non-aggregate arguments
```

**Problem:**
Mixing aggregated and non-aggregated fields in the same calculation.

**Solution:**
Ensure all fields are aggregated:
```
SUM([True Positive]) / SUM([actual_label])
```

If `actual_label` is not numeric, use:
```
SUM([True Positive]) / SUM(IF [actual_label] = 1 THEN 1 ELSE 0 END)
```

---

## Error: "Field not found"

### Issue 3: Field Name Mismatch

**Error Message:**
```
Field "[Field Name]" not found
```

**Problem:**
Field name doesn't match exactly (case-sensitive, spaces, etc.)

**Solutions:**
1. Check exact field name in Data pane
2. Use square brackets: `[Field Name]`
3. Match case exactly
4. Check for extra spaces

**Common Issues:**
- `actual_label` vs `Actual_Label` vs `Actual Label`
- `fraud_prediction` vs `Fraud_Prediction`
- `queue_status` vs `Queue Status`

---

## Error: "Division by zero"

### Issue 4: Division by Zero

**Error Message:**
```
Division by zero
```

**Problem:**
Denominator can be zero, causing division error.

**Solution: Add NULL Check**
```
IF SUM([actual_label]) > 0 
THEN SUM([True Positive]) / SUM([actual_label])
ELSE 0
END
```

**For False Positive Rate:**
```
IF SUM(IF [actual_label] = 0 THEN 1 ELSE 0 END) > 0
THEN SUM([False Positive]) / SUM(IF [actual_label] = 0 THEN 1 ELSE 0 END)
ELSE 0
END
```

---

## Corrected Field Definitions

### 1. True Positive
```
IF [actual_label] = 1 AND [fraud_prediction] = 1 THEN 1 ELSE 0 END
```

### 2. False Positive
```
IF [actual_label] = 0 AND [fraud_prediction] = 1 THEN 1 ELSE 0 END
```

### 3. False Negative
```
IF [actual_label] = 1 AND [fraud_prediction] = 0 THEN 1 ELSE 0 END
```

### 4. True Negative
```
IF [actual_label] = 0 AND [fraud_prediction] = 0 THEN 1 ELSE 0 END
```

### 5. Total Legitimate (Row-Level)
```
IF [actual_label] = 0 THEN 1 ELSE 0 END
```

### 6. Fraud Capture Rate (Safe Version)
```
IF SUM([actual_label]) > 0 
THEN SUM([True Positive]) / SUM([actual_label])
ELSE 0
END
```

### 7. False Positive Rate (Safe Version - RECOMMENDED)
```
IF SUM(IF [actual_label] = 0 THEN 1 ELSE 0 END) > 0
THEN SUM([False Positive]) / SUM(IF [actual_label] = 0 THEN 1 ELSE 0 END)
ELSE 0
END
```

### 8. False Positive Rate (Alternative - If Total Legitimate exists)
```
IF SUM([Total Legitimate]) > 0
THEN SUM([False Positive]) / SUM([Total Legitimate])
ELSE 0
END
```

---

## Step-by-Step Fix for False Positive Rate

### Option A: Create Field Without Total Legitimate

1. Right-click in Data pane → "Create Calculated Field"
2. Name: **`False Positive Rate`**
3. Formula:
```
IF SUM(IF [actual_label] = 0 THEN 1 ELSE 0 END) > 0
THEN SUM([False Positive]) / SUM(IF [actual_label] = 0 THEN 1 ELSE 0 END)
ELSE 0
END
```
4. Click "OK"

### Option B: Use Existing Total Legitimate Field

1. Check if `Total Legitimate` exists in your data
2. If it's a row-level field (0 or 1 per row):
   ```
   IF SUM([Total Legitimate]) > 0
   THEN SUM([False Positive]) / SUM([Total Legitimate])
   ELSE 0
   END
   ```
3. If it's already aggregated, use Option A instead

---

## Testing Your Calculations

### Test Each Field Individually

1. Create a simple sheet
2. Drag the calculated field to Rows
3. Drag a date field to Columns
4. Check if it displays correctly
5. If error, check the formula syntax

### Common Syntax Issues

**Wrong:**
```
SUM([False Positive]) / SUM(SUM([Total Legitimate]))  // Double SUM
SUM([False Positive]) / [Total Legitimate]            // Missing aggregation
```

**Correct:**
```
SUM([False Positive]) / SUM([Total Legitimate])       // If Total Legitimate is row-level
SUM([False Positive]) / SUM(IF [actual_label] = 0 THEN 1 ELSE 0 END)  // Inline calculation
```

---

## Quick Reference: All Corrected Formulas

| Field Name | Formula |
|------------|---------|
| **True Positive** | `IF [actual_label] = 1 AND [fraud_prediction] = 1 THEN 1 ELSE 0 END` |
| **False Positive** | `IF [actual_label] = 0 AND [fraud_prediction] = 1 THEN 1 ELSE 0 END` |
| **False Negative** | `IF [actual_label] = 1 AND [fraud_prediction] = 0 THEN 1 ELSE 0 END` |
| **True Negative** | `IF [actual_label] = 0 AND [fraud_prediction] = 0 THEN 1 ELSE 0 END` |
| **Total Legitimate** | `IF [actual_label] = 0 THEN 1 ELSE 0 END` |
| **Fraud Capture Rate** | `IF SUM([actual_label]) > 0 THEN SUM([True Positive]) / SUM([actual_label]) ELSE 0 END` |
| **False Positive Rate** | `IF SUM(IF [actual_label] = 0 THEN 1 ELSE 0 END) > 0 THEN SUM([False Positive]) / SUM(IF [actual_label] = 0 THEN 1 ELSE 0 END) ELSE 0 END` |

---

## Error: PSI Status Calculation

### Issue 5: PSI Score Field Not Found

**Error Message:**
```
Field "[psi_score]" not found
```

**Problem:**
The `psi_score` field doesn't exist in your data source.

**Solution 1: Use Pre-calculated PSI (Recommended)**
1. Connect to your SQL database
2. Use the `tableau_psi_score` view (from `prepare_tableau_data.sql`)
3. The view already has `psi_score` calculated

**Solution 2: Create PSI Score Field First**
If calculating PSI in Tableau, you need to create `PSI Score` field first, then use it in `PSI Status`.

**Solution 3: Skip PSI Status (Temporary)**
1. Don't create `PSI Status` field yet
2. Use `psi_score` directly in visualizations
3. Add color coding based on value ranges

**Solution 4: Use Alternative Field Name**
If your PSI field has a different name, update the formula:
```
IF [your_psi_field_name] IS NULL THEN "No Data"
ELSEIF [your_psi_field_name] < 0.10 THEN "No Drift"
ELSEIF [your_psi_field_name] < 0.25 THEN "Minor Drift"
ELSE "Major Drift"
END
```

### Corrected PSI Status Formula

**Field Name: `PSI Status`**
```
IF [psi_score] IS NULL THEN "No Data"
ELSEIF [psi_score] < 0.10 THEN "No Drift"
ELSEIF [psi_score] < 0.25 THEN "Minor Drift"
ELSE "Major Drift"
END
```

**If using aggregated PSI:**
```
IF AVG([psi_score]) IS NULL THEN "No Data"
ELSEIF AVG([psi_score]) < 0.10 THEN "No Drift"
ELSEIF AVG([psi_score]) < 0.25 THEN "Minor Drift"
ELSE "Major Drift"
END
```

---

## Still Having Issues?

### Check These:

1. **Field Names:**
   - Are they spelled exactly as in your data?
   - Are they in square brackets?
   - Case-sensitive?

2. **Data Types:**
   - Is `actual_label` numeric (0/1)?
   - Is `fraud_prediction` numeric (0/1)?

3. **Aggregation Context:**
   - Are you using the field in a table/chart?
   - Tableau might need different aggregation

4. **Test with Simple Formula:**
   ```
   SUM([False Positive])
   ```
   If this works, the issue is with the division part.

---

**Last Updated:** [Current Date]  
**Common Error:** False Positive Rate calculation  
**Solution:** Use inline calculation instead of nested SUM()

