# Quick Start Guide - One-Click Reproduction

## For Recruiters and Evaluators

This guide will help you reproduce the entire Fraud Detection System with a single command.

## Prerequisites

1. **R** (version 4.0 or higher)
   - Download from: https://cran.r-project.org/
   - Or use: `brew install r` (Mac) / `sudo apt-get install r-base` (Linux)

2. **RStudio** (optional but recommended)
   - Download from: https://www.rstudio.com/products/rstudio/download/

## One-Click Reproduction

### Option 1: Using R Console

1. Open R or RStudio
2. Set working directory to the project folder:
   ```r
   setwd("path/to/Fraud-Detection-System")
   ```
3. Run the complete pipeline:
   ```r
   source("run_complete_pipeline.R")
   ```

### Option 2: Using RScript (Command Line)

```bash
Rscript run_complete_pipeline.R
```

## What the Script Does

The `run_complete_pipeline.R` script automatically:

1. ✅ **Installs Required Packages** - Checks and installs all necessary R packages
2. ✅ **Creates Directory Structure** - Sets up all required folders
3. ✅ **Generates Synthetic Dataset** - Creates realistic fraud detection data (50,000 transactions)
4. ✅ **Feature Engineering** - Creates 40+ advanced features (velocity, risk flags, temporal features)
5. ✅ **Model Training** - Trains 3 models:
   - Logistic Regression
   - LightGBM (Gradient Boosting)
   - XGBoost
6. ✅ **Model Evaluation** - Compares models using cost-sensitive metrics
7. ✅ **Stable Feature Retraining** - Retrains best model with stable features
8. ✅ **Deployment Preparation** - Creates production-ready deployment package

## Expected Runtime

- **Full Pipeline**: ~10-15 minutes (depending on system)
- **Package Installation**: ~2-5 minutes (first run only)
- **Data Generation**: ~1-2 minutes
- **Feature Engineering**: ~2-3 minutes
- **Model Training**: ~5-8 minutes

## Output Files

After running, you'll find:

```
models/
├── stable/
│   ├── lightgbm_stable.txt          # Production model
│   ├── stable_features.txt          # Feature list
│   └── optimal_thresholds_stable.csv

deployment/
├── lightgbm_model.txt               # Deployment model
├── features.txt                     # Required features
└── thresholds.csv                   # Decision thresholds

cnp_dataset/
├── synthetic/                       # Generated synthetic data
└── feature_engineered/              # Complete feature set

evaluation/                          # Evaluation results
```

## Verification

After the script completes, you should see:

```
================================================================================
PIPELINE COMPLETE!
================================================================================

Summary:
  Dataset: 50000 transactions
  Features: [X] total, [Y] stable
  Best Model: LightGBM
  Final Cost per Transaction: [value]
  Precision: [value]%
  Recall: [value]%

✓ All steps completed successfully!
```

## Troubleshooting

### Issue: Package Installation Fails

**Solution**: Install packages manually:
```r
install.packages(c("readr", "dplyr", "caret", "pROC", "lightgbm", "xgboost"))
```

### Issue: LightGBM Installation Error

**Solution**: Install from GitHub:
```r
devtools::install_github("Microsoft/LightGBM", subdir = "R-package")
```

### Issue: Out of Memory

**Solution**: Reduce dataset size in the script:
```r
N_TRANSACTIONS <- 25000  # Instead of 50000
```

### Issue: Script Stops at Feature Engineering

**Solution**: This step can be slow. Wait 2-3 minutes. The script will continue automatically.

## What to Look For

When evaluating this project, check:

1. **Code Quality**: Clean, well-documented R code
2. **Reproducibility**: Single script runs entire pipeline
3. **Model Performance**: Cost-sensitive evaluation metrics
4. **Feature Engineering**: Advanced features (velocity, risk flags, temporal)
5. **Production Readiness**: Deployment package with models and functions
6. **Documentation**: Comprehensive guides and reports

## Next Steps

After running the pipeline:

1. Review model performance in `models/model_comparison.csv`
2. Check feature importance in model outputs
3. Examine deployment package in `deployment/`
4. Review documentation in project README

## Contact

**Author**: Islam Md Monaim  
**GitHub**: https://github.com/Monaim-knight  
**LinkedIn**: https://www.linkedin.com/in/md-monaim-islam-295928161/

---

**Note**: This is a complete, production-ready fraud detection system. All code is reproducible and well-documented.

