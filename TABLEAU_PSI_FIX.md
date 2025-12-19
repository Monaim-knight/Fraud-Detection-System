# PSI Status Calculation Fix
## How to Fix "Calculation Contains Errors" for PSI Status

---

## Problem

You're getting "The calculation contains errors" when creating the `PSI Status` field.

**Most Common Cause:** The `psi_score` field doesn't exist in your data source.

---

## Solution 1: Check if `psi_score` Exists

### Step 1: Verify Field Exists

1. In Tableau, look at the **Data pane** (left side)
2. Search for "psi" or "PSI"
3. Check if `psi_score` field is listed

### Step 2A: If Field EXISTS

Use this formula:
```
IF ISNULL([psi_score]) THEN "No Data"
ELSEIF [psi_score] < 0.10 THEN "No Drift"
ELSEIF [psi_score] < 0.25 THEN "Minor Drift"
ELSE "Major Drift"
END
```

### Step 2B: If Field DOES NOT EXIST

**Option 1: Skip This Field (Recommended for Now)**
- Don't create `PSI Status` field yet
- Continue building other parts of the dashboard
- Add PSI later when data is available

**Option 2: Add PSI Data First**
- Run `prepare_tableau_data.sql` to create PSI views
- Or add `psi_score` column to your CSV
- Then create the `PSI Status` field

---

## Solution 2: Use Correct Tableau Syntax

Tableau uses `ISNULL()` instead of `IS NULL`. Use this corrected formula:

**Field Name: `PSI Status`**
```
IF ISNULL([psi_score]) THEN "No Data"
ELSEIF [psi_score] < 0.10 THEN "No Drift"
ELSEIF [psi_score] < 0.25 THEN "Minor Drift"
ELSE "Major Drift"
END
```

**Field Name: `Drift Alert`**
```
IF ISNULL([psi_score]) THEN "NO DATA"
ELSEIF [psi_score] >= 0.25 THEN "CRITICAL"
ELSEIF [psi_score] >= 0.10 THEN "WARNING"
ELSE "OK"
END
```

---

## Solution 3: If Using SQL View with Aggregated PSI

If you're connecting to `tableau_psi_score` SQL view, the PSI might be aggregated:

**Field Name: `PSI Status`**
```
IF ISNULL(AVG([psi_score])) THEN "No Data"
ELSEIF AVG([psi_score]) < 0.10 THEN "No Drift"
ELSEIF AVG([psi_score]) < 0.25 THEN "Minor Drift"
ELSE "Major Drift"
END
```

---

## Solution 4: Create PSI Data First

If you don't have PSI data yet, you need to create it:

### Option A: Using SQL (Recommended)

1. Run `prepare_tableau_data.sql` in your database
2. This creates `tableau_psi_score` view with `psi_score` field
3. Connect Tableau to this view
4. Then create `PSI Status` field

### Option B: Add to CSV

1. Calculate PSI using Python/R (see `TABLEAU_PSI_CALCULATION.md`)
2. Add `psi_score` column to your CSV
3. Reconnect Tableau to updated CSV
4. Then create `PSI Status` field

### Option C: Calculate in Tableau (Complex)

See `TABLEAU_PSI_CALCULATION.md` for detailed methods (not recommended - very complex).

---

## Quick Decision Tree

```
Do you have psi_score in your data?
│
├─ YES → Use Solution 2 (corrected formula with ISNULL)
│
└─ NO → 
   │
   ├─ Using SQL? → Run prepare_tableau_data.sql → Use Solution 2
   │
   ├─ Using CSV? → Add psi_score column → Use Solution 2
   │
   └─ Don't need PSI yet? → SKIP this field → Add later
```

---

## Recommended Approach

**For Now:**
1. ✅ **SKIP** the `PSI Status` and `Drift Alert` fields
2. ✅ Continue building other dashboard components:
   - Fraud Capture Rate ✅
   - False Positive Rate ✅
   - Case Queue Overview ✅
3. ✅ Add PSI fields later when data is ready

**When Ready for PSI:**
1. Ensure `psi_score` exists in your data
2. Create `PSI Status` field using Solution 2 formula
3. Add PSI visualizations to dashboard

---

## Testing

After creating the field:

1. **Test in a simple sheet:**
   - Drag `PSI Status` to Rows
   - Drag `transaction_date` to Columns
   - Should display without errors

2. **If still getting errors:**
   - Check exact field name: `psi_score` (case-sensitive)
   - Verify field exists in Data pane
   - Check data type (should be numeric)

---

## Alternative: Use PSI Directly Without Status Field

Instead of creating `PSI Status`, you can:

1. Use `psi_score` directly in visualizations
2. Add color coding:
   - Green: < 0.10
   - Yellow: 0.10 - 0.25
   - Red: > 0.25
3. Add reference lines at 0.10 and 0.25

This avoids the calculated field entirely!

---

**Last Updated:** [Current Date]  
**Error:** PSI Status calculation contains errors  
**Solution:** Use ISNULL() and verify psi_score field exists






