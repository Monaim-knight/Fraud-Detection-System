# Project Structure Guide

This document explains the organization of the Fraud Detection System project.

## Directory Structure

```
fraud-detection-system/
│
├── README.md                    # Main project documentation
├── LICENSE                      # MIT License
├── CONTRIBUTING.md              # Contribution guidelines
├── .gitignore                   # Git ignore rules
├── R_requirements.txt           # R package dependencies
│
├── cnp_dataset/                 # Dataset directory
│   ├── creditcard.csv          # Original dataset (not tracked in git)
│   ├── synthetic/              # Synthetic datasets (not tracked)
│   ├── labeled/                # Labeled datasets (not tracked)
│   └── feature_engineered/     # Feature-engineered datasets (not tracked)
│
├── scripts/                     # R scripts (organized by stage)
│   ├── 01_data_cleaning/
│   │   ├── clean_cnp_dataset.R
│   │   └── load_dataset.R
│   │
│   ├── 02_feature_engineering/
│   │   ├── feature_engineering.R
│   │   └── implement_placeholder_features.R
│   │
│   ├── 03_model_training/
│   │   └── train_fraud_models.R
│   │
│   ├── 04_evaluation/
│   │   ├── evaluate_models.R
│   │   └── fix_temporal_validation.R
│   │
│   ├── 05_deployment/
│   │   ├── retrain_stable_models.R
│   │   └── deploy_models.R
│   │
│   └── 06_tableau/
│       ├── prepare_tableau_data.R
│       └── export_mysql_for_tableau.R
│
├── models/                      # Trained models (not tracked in git)
│   ├── stable/                 # Production-ready models
│   └── [other model versions]
│
├── evaluation/                  # Evaluation results
│   ├── comprehensive_metrics.csv
│   ├── segment_analysis.csv
│   └── temporal_validation.csv
│
├── deployment/                  # Deployment package
│   ├── lightgbm_model.txt
│   ├── features.txt
│   ├── thresholds.csv
│   ├── predict_fraud.R
│   ├── preprocess_transaction.R
│   ├── monitor_performance.R
│   ├── test_deployment.R
│   └── README.md
│
├── tableau_exports/            # Data exports for Tableau
│   ├── tableau_fraud_data.csv
│   ├── tableau_summary_stats.csv
│   └── [other exports]
│
└── docs/                        # Documentation
    ├── README.md               # Documentation index
    ├── reports/                # Analysis reports
    ├── guides/                 # Step-by-step guides
    └── troubleshooting/        # Troubleshooting guides
```

## File Naming Conventions

### Scripts
- Use descriptive names: `train_fraud_models.R`
- Prefix with stage number if sequential: `01_clean_data.R`
- Use snake_case: `prepare_tableau_data.R`

### Documentation
- Use descriptive names: `Model_Training_Report.md`
- Use Title_Case for reports: `Evaluation_Report.md`
- Use UPPER_CASE for guides: `TABLEAU_DASHBOARD_GUIDE.md`

### Data Files
- Use descriptive names: `creditcard_features_complete.csv`
- Include version/date if needed: `fraud_data_2024.csv`

## Key Directories

### `scripts/`
Contains all R scripts organized by workflow stage. Each script is self-contained and can be run independently.

### `models/`
Contains trained model files. Production models are in `models/stable/`. These files are typically large and not tracked in git.

### `evaluation/`
Contains evaluation results and metrics. CSV files with performance metrics, segment analysis, and validation results.

### `deployment/`
Contains production-ready deployment package with models, functions, and documentation.

### `docs/`
Contains all project documentation organized by category (reports, guides, troubleshooting).

## Data Flow

1. **Raw Data** → `cnp_dataset/creditcard.csv`
2. **Cleaned Data** → `cnp_dataset/cleaned/`
3. **Labeled Data** → `cnp_dataset/labeled/`
4. **Feature-Engineered Data** → `cnp_dataset/feature_engineered/`
5. **Trained Models** → `models/stable/`
6. **Evaluation Results** → `evaluation/`
7. **Tableau Exports** → `tableau_exports/`
8. **Deployment Package** → `deployment/`

## Git Tracking

### Tracked Files
- All R scripts
- All documentation (Markdown files)
- Configuration files (`.gitignore`, `R_requirements.txt`)
- Small CSV files (templates, examples)

### Not Tracked (in .gitignore)
- Large datasets (`*.csv` except templates)
- Model files (`*.rds`, `*.txt` models)
- Temporary files (`tmp/`, `*.log`)
- IDE files (`.Rproj.user/`, `.vscode/`)
- Sensitive data (`.env`, credentials)

## Best Practices

1. **Keep scripts modular**: Each script should do one thing well
2. **Document your code**: Add comments for complex logic
3. **Use version control**: Commit frequently with descriptive messages
4. **Test before committing**: Ensure scripts run without errors
5. **Update documentation**: Keep docs in sync with code changes


