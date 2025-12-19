# Population Stability Index (PSI) Calculation Guide
## For Tableau Dashboard

**Purpose:** Calculate PSI for drift monitoring in Tableau

---

## PSI Formula

```
PSI = Σ((Actual % - Expected %) × ln(Actual % / Expected %))
```

Where:
- **Expected %** = Distribution in baseline period (e.g., last 30 days)
- **Actual %** = Distribution in current period (e.g., today)
- **Σ** = Sum across all bins/categories

---

## Method 1: Pre-calculate PSI in Data Source (Recommended)

### SQL Example

```sql
WITH baseline AS (
  -- Baseline period: Last 30 days
  SELECT 
    CASE 
      WHEN fraud_probability < 0.1 THEN '0-0.1'
      WHEN fraud_probability < 0.2 THEN '0.1-0.2'
      WHEN fraud_probability < 0.3 THEN '0.2-0.3'
      WHEN fraud_probability < 0.4 THEN '0.3-0.4'
      WHEN fraud_probability < 0.5 THEN '0.4-0.5'
      WHEN fraud_probability < 0.6 THEN '0.5-0.6'
      WHEN fraud_probability < 0.7 THEN '0.6-0.7'
      WHEN fraud_probability < 0.8 THEN '0.7-0.8'
      WHEN fraud_probability < 0.9 THEN '0.8-0.9'
      ELSE '0.9-1.0'
    END AS prob_bin,
    COUNT(*) * 1.0 / SUM(COUNT(*)) OVER () AS expected_pct
  FROM transactions
  WHERE transaction_date >= DATEADD(day, -30, GETDATE())
    AND transaction_date < DATEADD(day, -1, GETDATE())
  GROUP BY prob_bin
),
current_period AS (
  -- Current period: Today
  SELECT 
    CASE 
      WHEN fraud_probability < 0.1 THEN '0-0.1'
      WHEN fraud_probability < 0.2 THEN '0.1-0.2'
      WHEN fraud_probability < 0.3 THEN '0.2-0.3'
      WHEN fraud_probability < 0.4 THEN '0.3-0.4'
      WHEN fraud_probability < 0.5 THEN '0.4-0.5'
      WHEN fraud_probability < 0.6 THEN '0.5-0.6'
      WHEN fraud_probability < 0.7 THEN '0.6-0.7'
      WHEN fraud_probability < 0.8 THEN '0.7-0.8'
      WHEN fraud_probability < 0.9 THEN '0.8-0.9'
      ELSE '0.9-1.0'
    END AS prob_bin,
    COUNT(*) * 1.0 / SUM(COUNT(*)) OVER () AS actual_pct
  FROM transactions
  WHERE transaction_date >= CAST(GETDATE() AS DATE)
  GROUP BY prob_bin
)
SELECT 
  COALESCE(b.prob_bin, c.prob_bin) AS prob_bin,
  COALESCE(b.expected_pct, 0) AS expected_pct,
  COALESCE(c.actual_pct, 0) AS actual_pct,
  CASE 
    WHEN COALESCE(b.expected_pct, 0) = 0 OR COALESCE(c.actual_pct, 0) = 0 THEN 0
    ELSE (COALESCE(c.actual_pct, 0) - COALESCE(b.expected_pct, 0)) * 
         LN(COALESCE(c.actual_pct, 0) / NULLIF(COALESCE(b.expected_pct, 0), 0))
  END AS psi_component
FROM baseline b
FULL OUTER JOIN current_period c ON b.prob_bin = c.prob_bin
```

Then calculate total PSI:
```sql
SELECT 
  transaction_date,
  SUM(psi_component) AS psi_score
FROM psi_calculation
GROUP BY transaction_date
```

---

## Method 2: Python/R Script for PSI

### Python Script

```python
import pandas as pd
import numpy as np

def calculate_psi(expected, actual, bins=10):
    """
    Calculate Population Stability Index
    
    Parameters:
    expected: Series of expected values
    actual: Series of actual values
    bins: Number of bins for distribution
    
    Returns:
    PSI score
    """
    # Create bins
    breakpoints = np.linspace(0, 1, bins + 1)
    
    # Calculate distributions
    expected_dist = pd.cut(expected, breakpoints, include_lowest=True).value_counts(normalize=True)
    actual_dist = pd.cut(actual, breakpoints, include_lowest=True).value_counts(normalize=True)
    
    # Align indices
    expected_dist = expected_dist.reindex(actual_dist.index, fill_value=0.0001)
    actual_dist = actual_dist.reindex(expected_dist.index, fill_value=0.0001)
    
    # Calculate PSI
    psi = 0
    for idx in expected_dist.index:
        expected_pct = expected_dist[idx]
        actual_pct = actual_dist[idx]
        
        if expected_pct > 0 and actual_pct > 0:
            psi += (actual_pct - expected_pct) * np.log(actual_pct / expected_pct)
    
    return psi

# Usage
df = pd.read_csv('transactions.csv')
baseline = df[df['transaction_date'] < '2024-01-01']['fraud_probability']
current = df[df['transaction_date'] >= '2024-01-01']['fraud_probability']

psi_score = calculate_psi(baseline, current)
print(f"PSI Score: {psi_score}")
```

### R Script

```r
calculate_psi <- function(expected, actual, bins = 10) {
  # Create bins
  breakpoints <- seq(0, 1, length.out = bins + 1)
  
  # Calculate distributions
  expected_cut <- cut(expected, breakpoints, include.lowest = TRUE)
  actual_cut <- cut(actual, breakpoints, include.lowest = TRUE)
  
  expected_dist <- prop.table(table(expected_cut))
  actual_dist <- prop.table(table(actual_cut))
  
  # Align distributions
  all_levels <- union(names(expected_dist), names(actual_dist))
  expected_dist <- expected_dist[all_levels]
  actual_dist <- actual_dist[all_levels]
  expected_dist[is.na(expected_dist)] <- 0.0001
  actual_dist[is.na(actual_dist)] <- 0.0001
  
  # Calculate PSI
  psi <- sum((actual_dist - expected_dist) * log(actual_dist / expected_dist))
  
  return(psi)
}

# Usage
df <- read.csv('transactions.csv')
baseline <- df[df$transaction_date < '2024-01-01', 'fraud_probability']
current <- df[df$transaction_date >= '2024-01-01', 'fraud_probability']

psi_score <- calculate_psi(baseline, current)
cat("PSI Score:", psi_score, "\n")
```

---

## Method 3: Tableau Calculated Fields (Complex)

### Step 1: Create Bins

1. Right-click `fraud_probability` → Create → Bins
2. Bin size: 0.1
3. Name: "Probability Bin"

### Step 2: Create Baseline Distribution

**Calculated Field: Baseline Distribution**
```
{ FIXED [Probability Bin]:
  COUNTD(IF [transaction_date] >= DATEADD('day', -30, TODAY()) 
         AND [transaction_date] < TODAY()
    THEN [transaction_id] END) / 
  COUNTD(IF [transaction_date] >= DATEADD('day', -30, TODAY()) 
         AND [transaction_date] < TODAY()
    THEN [transaction_id] END)
}
```

### Step 3: Create Current Distribution

**Calculated Field: Current Distribution**
```
{ FIXED [Probability Bin]:
  COUNTD(IF [transaction_date] = TODAY() 
    THEN [transaction_id] END) / 
  COUNTD(IF [transaction_date] = TODAY() 
    THEN [transaction_id] END)
}
```

### Step 4: Calculate PSI Component

**Calculated Field: PSI Component**
```
IF [Baseline Distribution] > 0 AND [Current Distribution] > 0 THEN
  ([Current Distribution] - [Baseline Distribution]) * 
  LN([Current Distribution] / [Baseline Distribution])
ELSE 0
END
```

### Step 5: Calculate Total PSI

**Calculated Field: PSI Score**
```
{ FIXED [transaction_date]:
  SUM([PSI Component])
}
```

---

## PSI Interpretation

| PSI Value | Interpretation | Action |
|-----------|----------------|--------|
| < 0.10 | No significant drift | Continue monitoring |
| 0.10 - 0.25 | Minor drift | Investigate cause |
| > 0.25 | Major drift | Retrain model |

---

## Feature-Level PSI

Calculate PSI for each important feature:

1. **Amount PSI:**
   - Bin transaction amounts
   - Compare distributions

2. **Time PSI:**
   - Bin by hour of day
   - Compare time patterns

3. **Geographic PSI:**
   - Compare country distributions
   - Monitor location shifts

---

## Automation

### Schedule PSI Calculation

1. **Daily:** Calculate PSI for previous day
2. **Weekly:** Calculate PSI for previous week
3. **Monthly:** Calculate PSI for previous month

### Alert Setup

- PSI > 0.25: Critical alert
- PSI > 0.10: Warning alert
- Send email/Slack notification

---

**Note:** Pre-calculating PSI in your data source is recommended for better performance and accuracy.






