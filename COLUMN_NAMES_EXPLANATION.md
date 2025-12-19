# CNP Dataset Column Names - Explanation

## Your Column Names Are CORRECT! ✅

The column names in your dataset are **exactly as they should be**. This is the standard format for the Credit Card Fraud Detection dataset.

## Column Name Breakdown

```
Time   → Seconds elapsed since the first transaction
V1-V28 → PCA-transformed features (28 features)
Amount → Transaction amount in the original currency
Class  → Fraud label (0 = normal, 1 = fraud)
```

## Why V1-V28?

The **V1 through V28** columns are **Principal Component Analysis (PCA)** transformed features. This means:

1. **Original features were anonymized** for privacy reasons
2. **PCA transformation** was applied to reduce dimensionality and protect sensitive information
3. **V1-V28** represent the principal components (the most important patterns in the data)

This is **standard practice** for financial fraud datasets to protect:
- Cardholder privacy
- Merchant information
- Transaction details
- Geographic data

## Are These Names a Problem?

**NO!** These are the **official column names** from the dataset source (Kaggle/Machine Learning Group - ULB).

### Advantages of Keeping Original Names:
- ✅ **Standard format** - matches research papers and benchmarks
- ✅ **Compatibility** - works with existing code and tutorials
- ✅ **Clarity** - V1-V28 clearly indicates PCA features
- ✅ **No confusion** - everyone using this dataset recognizes these names

### If You Want to Rename (Optional):
You can rename them if you prefer, but it's **not necessary**:

```r
# Optional renaming (not required)
df <- df %>%
  rename(
    transaction_time = Time,
    transaction_amount = Amount,
    fraud_label = Class
  )
# V1-V28 can stay as they are
```

## Updated Cleaning Script

The `clean_cnp_dataset.R` script has been updated to:
- ✅ **Preserve original column names** (Time, V1-V28, Amount, Class)
- ✅ Work with the original naming convention
- ✅ Add new derived columns without changing originals
- ✅ Keep `Amount_original` column when winsorizing

## Summary

**Your dataset column names are perfect!** No changes needed. The cleaning script will work with them as-is.






