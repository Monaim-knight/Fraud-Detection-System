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
.
├── README.md                          # This file
├── LICENSE                            # MIT License
├── .gitignore                         # Git ignore rules
├── R_requirements.txt                 # R package dependencies
│
├── data/                              # Data directory
│   └── cnp_dataset/                   # CNP fraud dataset
│
├── scripts/                           # R scripts organized by stage
│   ├── 01_data_cleaning/              # Data cleaning scripts
│   ├── 02_feature_engineering/        # Feature engineering scripts
│   ├── 03_model_training/            # Model training scripts
│   ├── 04_evaluation/                # Model evaluation scripts
│   ├── 05_deployment/                # Deployment scripts
│   └── 06_tableau/                   # Tableau data preparation
│
├── models/                            # Trained models
│   └── stable/                        # Production-ready models
│
├── evaluation/                        # Evaluation results
│   ├── comprehensive_metrics.csv
│   ├── segment_analysis.csv
│   └── temporal_validation.csv
│
├── deployment/                        # Deployment package
│   ├── lightgbm_model.txt
│   ├── features.txt
│   ├── thresholds.csv
│   ├── predict_fraud.R
│   └── README.md
│
├── tableau_exports/                   # Data exports for Tableau
│
└── docs/                              # Documentation
    ├── reports/                       # Analysis reports
    ├── guides/                        # Step-by-step guides
    └── troubleshooting/               # Troubleshooting guides
```

## 🚀 Quick Start

### Prerequisites

- **R** (version 4.0 or higher)
- **RStudio** (recommended)
- **MySQL** (optional, for database integration)
- **Tableau** (optional, for dashboards)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Monaim-Knight/fraud-detection-system.git
   cd fraud-detection-system
   ```

2. **Install R packages:**
   ```r
   # Install required packages
   install.packages(c(
     "readr", "dplyr", "tidyr", "lubridate",
     "caret", "pROC", "ROSE",
     "lightgbm", "xgboost",
     "igraph", "DescTools"
   ))
   ```

   Or use the requirements file:
   ```r
   source("install_packages.R")  # If available
   ```

3. **Download the dataset:**
   - Place your CNP dataset in `cnp_dataset/creditcard.csv`
   - Or use the synthetic dataset generation script

### Basic Usage

1. **Data Cleaning:**
   ```r
   source("clean_cnp_dataset.R")
   ```

2. **Feature Engineering:**
   ```r
   source("feature_engineering.R")
   source("implement_placeholder_features.R")
   ```

3. **Model Training:**
   ```r
   source("train_fraud_models.R")
   ```

4. **Model Evaluation:**
   ```r
   source("evaluate_models.R")
   ```

5. **Deployment Preparation:**
   ```r
   source("retrain_stable_models.R")
   source("deploy_models.R")
   ```

## 📈 Workflow

### Stage 1: Data Collection & Cleaning
- Dataset loading and validation
- Missing value handling
- Outlier detection and treatment
- Data quality assessment

### Stage 2: Feature Engineering
- **Velocity Features**: Transaction frequency within time windows
- **Identity Consistency**: Device reuse, IP-geo mismatch, email domain risk
- **Graph Features**: Shared devices, shared addresses, network analysis
- **Risk Flags**: High amount, unusual time, weekend, rapid transactions, prepaid cards, disposable emails, high-risk geography
- **Temporal Features**: Day of month, week of month, rolling fraud rates

### Stage 3: Model Training
- **Logistic Regression**: Baseline interpretable model
- **LightGBM**: High-performance gradient boosting (best model)
- **XGBoost**: Alternative high-performance model
- **Class Imbalance Handling**: Class weights and cost-sensitive learning
- **Threshold Optimization**: Finding optimal decision threshold based on cost

### Stage 4: Model Evaluation
- **Comprehensive Metrics**: Accuracy, Precision, Recall, F1, ROC AUC, PR AUC
- **Cost Analysis**: Expected cost saved, cost per transaction
- **Segment Analysis**: Performance by geography, merchant, account age
- **Temporal Validation**: Walk-forward validation on future data

### Stage 5: Deployment
- Model stability analysis
- Feature selection (48 stable features)
- Production-ready model packaging
- Monitoring setup
- Real-world testing

### Stage 6: Dashboard Creation
- **Tableau Dashboards**: Interactive fraud monitoring
- **Metrics**: Fraud capture rate, false positive rate, PSI monitoring
- **Case Queue**: Operations team overview

## 🔬 Technical Details

### Model Architecture

**LightGBM (Best Model):**
- Algorithm: Gradient Boosting Decision Tree
- Class weights: Balanced for fraud class
- Optimal threshold: 0.170
- Features: 48 stable features
- Performance: 60.19% recall, 41.61% precision

### Feature Engineering

**48 Engineered Features:**
- 28 Original features (V1-V28, Time, Amount)
- 7 Risk flags
- 3 Velocity features
- 3 Identity consistency features
- 3 Graph features
- 4 Temporal features

### Cost-Sensitive Optimization

- **Cost of False Negative**: 10 units (missing fraud)
- **Cost of False Positive**: 1 unit (false alarm)
- **Optimization Goal**: Minimize total expected cost
- **Result**: 81.14% cost savings

## 📊 Monitoring & Dashboards

### Tableau Dashboards

1. **Fraud Capture Rate Dashboard**
   - Blocked fraud / Total fraud
   - Target: >95%
   - Color-coded alerts

2. **False Positive Rate Dashboard**
   - Blocked legitimate / Total legitimate
   - Target: <5%
   - Trend analysis

3. **Drift Monitoring Dashboard**
   - Population Stability Index (PSI)
   - Feature distribution shifts
   - Alert thresholds

4. **Case Queue Overview**
   - Operations team dashboard
   - Pending cases
   - Priority assignments
   - Analyst workload

## 📝 Documentation

Comprehensive documentation is available in the `docs/` directory:

- **Reports**: Detailed analysis reports for each stage
- **Guides**: Step-by-step implementation guides
- **Troubleshooting**: Common issues and solutions

Key documents:
- `docs/reports/Model_Training_Report.md`
- `docs/reports/Evaluation_Report.md`
- `docs/reports/Deployment_Report.md`
- `docs/guides/TABLEAU_DASHBOARD_BUILDING_GUIDE.md`

## 🧪 Testing

### Unit Testing
```r
# Test deployment package
source("deployment/test_deployment.R")
```

### Real Data Testing
```r
# Test with real transaction data
source("test_with_real_data.R")
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Islam Md Monaim**
- GitHub: [@Monaim-Knight](https://github.com/Monaim-Knight)
- LinkedIn: [Md Monaim Islam](https://www.linkedin.com/in/md-monaim-islam-295928161/)

## 🙏 Acknowledgments

- Credit Card Fraud Detection Dataset (CNP Dataset)
- LightGBM and XGBoost communities
- Tableau for visualization tools

## 📚 References

- [LightGBM Documentation](https://lightgbm.readthedocs.io/)
- [XGBoost Documentation](https://xgboost.readthedocs.io/)
- [Tableau Documentation](https://help.tableau.com/)

---

**Note**: This project is for educational and portfolio purposes. For production use, ensure proper security measures, data privacy compliance, and thorough testing.

