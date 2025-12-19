# Fraud Detection System - Machine Learning Project

[![R](https://img.shields.io/badge/R-4.0+-blue.svg)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-Production%20Ready-success.svg)]()

A comprehensive end-to-end fraud detection system using machine learning, featuring advanced feature engineering, model training, evaluation, and deployment with interactive Tableau dashboards for monitoring.

## 🎯 Project Overview

This project implements a complete fraud detection pipeline for Card-Not-Present (CNP) transactions, addressing the critical challenge of identifying fraudulent transactions in real-time while minimizing false positives. The system uses advanced machine learning techniques, cost-sensitive optimization, and temporal validation to ensure robust performance.

### Key Features

- **Advanced Feature Engineering**: 48 engineered features including velocity features, identity consistency checks, graph features, and risk flags
- **Multiple ML Models**: Logistic Regression, LightGBM, and XGBoost with optimized hyperparameters
- **Cost-Sensitive Learning**: Optimized for business costs (FN:FP = 10:1 ratio)
- **Temporal Validation**: Walk-forward validation to ensure model stability over time
- **Production-Ready Deployment**: Complete deployment package with monitoring capabilities
- **Interactive Dashboards**: Tableau dashboards for fraud monitoring, drift detection, and case queue management

## 📊 Results Summary

### Model Performance (Best Model: LightGBM)

| Metric | Value |
|--------|-------|
| **Cost Saved** | 533.00 units (81.14% savings) |
| **Precision** | 41.61% |
| **Recall** | 60.19% |
| **F1-Score** | 0.5127 |
| **ROC AUC** | 0.9930 |
| **PR AUC** | 0.9098 |
| **Cost per Transaction** | 0.0327 |

### Business Impact

- **81.14% cost reduction** compared to no model scenario
- **60.19% fraud capture rate** (catches majority of fraudulent transactions)
- **Low false positive rate** minimizing customer inconvenience
- **Production-ready** with comprehensive monitoring

## 🏗️ Project Structure

```
fraud-detection-system/
├── README.md                    # Main documentation
├── LICENSE                      # MIT License
├── R_requirements.txt          # R package dependencies
│
├── run_complete_pipeline.R     # ⭐ ONE-CLICK REPRODUCTION
│
├── scripts/                    # Organized workflow scripts
│   ├── data_preparation/        # Data generation & preparation
│   ├── feature_engineering/     # Feature creation
│   ├── model_training/          # Model training scripts
│   ├── evaluation/              # Model evaluation
│   ├── deployment/              # Deployment preparation
│   └── tableau/                 # Tableau data preparation
│
├── docs/
│   ├── reports/                 # Analysis reports
│   │   ├── Model_Training_Report.md
│   │   ├── Evaluation_Report.md
│   │   └── Deployment_Report.md
│   └── guides/                  # User guides
│       ├── QUICK_START.md
│       └── TABLEAU_DASHBOARD_GUIDE.md
│
├── deployment/                  # Production deployment package
├── tableau_exports/             # Tableau data exports
└── cnp_dataset/                 # Dataset directory (not tracked)
```

## 🚀 Quick Start

### ⚡ One-Click Reproduction

**Reproduce the entire pipeline with a single command:**

```r
# In R or RStudio:
source("run_complete_pipeline.R")
```

Or from command line:
```bash
Rscript run_complete_pipeline.R
```

**What it does:**
- ✅ Installs all required packages
- ✅ Generates synthetic dataset (50,000 transactions)
- ✅ Performs feature engineering (48 features)
- ✅ Trains 3 ML models (Logistic Regression, LightGBM, XGBoost)
- ✅ Evaluates and compares models
- ✅ Retrains with stable features
- ✅ Creates deployment package

**Expected runtime**: ~10-15 minutes

📖 See [`docs/guides/QUICK_START.md`](docs/guides/QUICK_START.md) for detailed instructions.

### Prerequisites

- **R** (version 4.0 or higher) - [Download](https://www.r-project.org/)
- **RStudio** (recommended) - [Download](https://www.rstudio.com/products/rstudio/download/)

## 📚 Documentation

### Reports
- [`Model_Training_Report.md`](docs/reports/Model_Training_Report.md) - Model training process and results
- [`Evaluation_Report.md`](docs/reports/Evaluation_Report.md) - Comprehensive model evaluation
- [`Deployment_Report.md`](docs/reports/Deployment_Report.md) - Deployment preparation and validation

### Guides
- [`QUICK_START.md`](docs/guides/QUICK_START.md) - Step-by-step reproduction guide
- [`TABLEAU_DASHBOARD_GUIDE.md`](docs/guides/TABLEAU_DASHBOARD_GUIDE.md) - Tableau dashboard setup

### Additional Documentation
- [`PRODUCTION_DECISION_STRATEGY.md`](PRODUCTION_DECISION_STRATEGY.md) - Production decision framework
- [`PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md) - Detailed project organization

## 🔧 Technical Details

### Models Implemented

1. **Logistic Regression** - Baseline model with interpretable coefficients
2. **LightGBM** - Gradient boosting (best performing model)
3. **XGBoost** - Alternative gradient boosting implementation

### Feature Engineering

- **Velocity Features**: Transaction frequency in 10m/1h/24h windows
- **Identity Consistency**: Device reuse, IP-geo mismatch, email domain risk
- **Risk Flags**: Prepaid cards, high-risk geography, disposable emails
- **Temporal Features**: Time of day, day of week, weekend flags
- **Amount Features**: High-amount flags, normalized amounts

### Evaluation Metrics

- **Cost-Sensitive Metrics**: Total cost, cost per transaction
- **Classification Metrics**: Precision, Recall, F1-Score, ROC AUC, PR AUC
- **Business Metrics**: Cost saved, cost saved percentage
- **Segment Analysis**: Performance by merchant, geography, account age
- **Temporal Validation**: Walk-forward validation for stability

## 🎯 Use Cases

- **Real-time Fraud Detection**: Score transactions in production
- **Fraud Monitoring**: Track fraud rates and model performance
- **Case Management**: Review queue for flagged transactions
- **Model Monitoring**: Detect concept drift and performance degradation

## 📈 Performance Highlights

- **81.14% cost savings** compared to baseline
- **60.19% fraud recall** (catches majority of fraud)
- **0.9930 ROC AUC** (excellent discrimination)
- **0.9098 PR AUC** (strong precision-recall balance)
- **Production-ready** with monitoring and deployment package

## 🤝 Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for contribution guidelines.

## 📄 License

This project is licensed under the MIT License - see the [`LICENSE`](LICENSE) file for details.

## 👤 Author

**Islam Md Monaim**

- GitHub: [@Monaim-Knight](https://github.com/Monaim-knight)
- LinkedIn: [md-monaim-islam](https://www.linkedin.com/in/md-monaim-islam-295928161/)

## 🙏 Acknowledgments

- Credit Card Fraud Detection dataset
- R community for excellent ML packages
- Tableau for visualization capabilities

---

**⭐ Star this repository if you find it useful!**
