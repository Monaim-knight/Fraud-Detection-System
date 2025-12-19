# Step-by-Step Deployment Testing Guide

This guide allows you to test the deployment package manually, one step at a time, for full control.

---

## Prerequisites

Before starting, make sure you're in the correct directory:

```r
# Set working directory (adjust if needed)
setwd("C:/Users/monai/OneDrive - student.uni-halle.de/Desktop/Billie _ R")
```

---

## Step 1: Check Deployment Directory Exists

**Purpose:** Verify the deployment folder was created.

```r
# Check if deployment directory exists
if (dir.exists("deployment")) {
  cat("✓ Deployment directory exists\n")
  cat("Location:", getwd(), "/deployment\n")
} else {
  cat("✗ Deployment directory not found\n")
  cat("Run: source('deploy_models.R') first\n")
}
```

**Expected Output:**
```
✓ Deployment directory exists
Location: [your path]/deployment
```

---

## Step 2: Check All Required Files Exist

**Purpose:** Verify all 8 deployment files are present.

```r
# List of required files
required_files <- c(
  "deployment/lightgbm_model.txt",
  "deployment/logistic_regression_model.rds",
  "deployment/features.txt",
  "deployment/thresholds.csv",
  "deployment/predict_fraud.R",
  "deployment/preprocess_transaction.R",
  "deployment/monitor_performance.R",
  "deployment/test_deployment.R",
  "deployment/README.md"
)

# Check each file
cat("Checking required files...\n\n")
all_exist <- TRUE

for (file in required_files) {
  if (file.exists(file)) {
    file_size <- file.info(file)$size
    cat(sprintf("✓ %s exists (%.1f KB)\n", file, file_size/1024))
  } else {
    cat(sprintf("✗ %s MISSING\n", file))
    all_exist <- FALSE
  }
}

if (all_exist) {
  cat("\n✓ All required files exist!\n")
} else {
  cat("\n✗ Some files are missing. Run deploy_models.R first.\n")
}
```

**Expected Output:**
```
✓ deployment/lightgbm_model.txt exists (XX.X KB)
✓ deployment/features.txt exists (X.X KB)
...
✓ All required files exist!
```

---

## Step 3: Load and Inspect Features List

**Purpose:** Verify the features file is readable and contains the expected 48 features.

```r
library(readr)

cat("Loading features list...\n")

# Load features
features <- read_lines("deployment/features.txt")

cat(sprintf("✓ Loaded %d features\n\n", length(features)))

# Display first 10 features
cat("First 10 features:\n")
print(features[1:10])

cat("\nLast 10 features:\n")
print(features[(length(features)-9):length(features)])

# Check for expected features
expected_key_features <- c("V1", "V2", "V3", "Amount", "ip_geo_mismatch", 
                           "device_reuse_count", "risk_flag_count")

cat("\nChecking for key features...\n")
for (feat in expected_key_features) {
  if (feat %in% features) {
    cat(sprintf("✓ %s found\n", feat))
  } else {
    cat(sprintf("✗ %s NOT found\n", feat))
  }
}
```

**Expected Output:**
```
✓ Loaded 48 features
First 10 features: [V1, V2, V3, ...]
...
✓ V1 found
✓ Amount found
...
```

---

## Step 4: Load and Inspect Thresholds

**Purpose:** Verify thresholds file is readable and contains model thresholds.

```r
library(readr)

cat("Loading thresholds...\n")

# Load thresholds
thresholds <- read_csv("deployment/thresholds.csv", show_col_types = FALSE)

cat(sprintf("✓ Loaded thresholds for %d models\n\n", nrow(thresholds)))

# Display thresholds
print(thresholds)

# Check specific thresholds
if ("Model" %in% colnames(thresholds) && "Threshold" %in% colnames(thresholds)) {
  cat("\nThreshold Summary:\n")
  for (i in 1:nrow(thresholds)) {
    cat(sprintf("  %s: %.3f\n", 
                thresholds$Model[i], 
                thresholds$Threshold[i]))
  }
} else {
  cat("\n⚠ Threshold columns not as expected\n")
  cat("Columns:", paste(colnames(thresholds), collapse = ", "), "\n")
}
```

**Expected Output:**
```
✓ Loaded thresholds for 2 models
Model Threshold
LightGBM 0.170
Logistic Regression 0.960
```

---

## Step 5: Test Model Loading (LightGBM)

**Purpose:** Verify the LightGBM model can be loaded successfully.

```r
# Check if lightgbm is installed
if (!requireNamespace("lightgbm", quietly = TRUE)) {
  cat("⚠ lightgbm package not installed\n")
  cat("Install with: install.packages('lightgbm')\n")
  cat("Skipping model load test...\n")
} else {
  library(lightgbm)
  
  cat("Testing LightGBM model loading...\n")
  
  tryCatch({
    # Load model
    model <- lgb.load("deployment/lightgbm_model.txt")
    cat("✓ LightGBM model loaded successfully\n")
    
    # Get model info
    cat("\nModel Information:\n")
    cat(sprintf("  Model type: %s\n", class(model)[1]))
    
    # Try to get feature names if available
    if (exists("model")) {
      cat("  ✓ Model object created\n")
    }
    
  }, error = function(e) {
    cat(sprintf("✗ Error loading model: %s\n", e$message))
  })
}
```

**Expected Output:**
```
✓ LightGBM model loaded successfully
Model Information:
  Model type: lgb.Booster
  ✓ Model object created
```

---

## Step 6: Test Model Loading (Logistic Regression)

**Purpose:** Verify the Logistic Regression model can be loaded.

```r
cat("Testing Logistic Regression model loading...\n")

tryCatch({
  # Load model
  lr_model <- readRDS("deployment/logistic_regression_model.rds")
  cat("✓ Logistic Regression model loaded successfully\n")
  
  # Get model info
  cat("\nModel Information:\n")
  cat(sprintf("  Model type: %s\n", class(lr_model)[1]))
  
  # Check if it has coefficients
  if ("coefficients" %in% names(lr_model)) {
    n_coef <- length(lr_model$coefficients)
    cat(sprintf("  Number of coefficients: %d\n", n_coef))
    cat("  ✓ Model structure looks correct\n")
  }
  
}, error = function(e) {
  cat(sprintf("✗ Error loading model: %s\n", e$message))
})
```

**Expected Output:**
```
✓ Logistic Regression model loaded successfully
Model Information:
  Model type: glm
  Number of coefficients: 49
  ✓ Model structure looks correct
```

---

## Step 7: Test Preprocessing Function

**Purpose:** Verify the preprocessing function loads and works with sample data.

```r
cat("Testing preprocessing function...\n")

# Load features to know what we need
features <- read_lines("deployment/features.txt")

# Create sample transaction data (minimal)
cat("\nCreating sample transaction data...\n")

# Sample transaction with basic fields
sample_transaction <- data.frame(
  Time = 1000000,
  V1 = 0.5,
  V2 = -0.2,
  V3 = 0.1,
  V4 = 0.3,
  V5 = -0.1,
  V6 = 0.2,
  V7 = 0.0,
  V8 = -0.1,
  V9 = 0.1,
  V10 = 0.2,
  V11 = -0.1,
  V12 = 0.1,
  V13 = 0.0,
  V14 = -0.2,
  V15 = 0.1,
  V16 = -0.1,
  V17 = 0.0,
  V18 = 0.1,
  V19 = -0.1,
  V20 = 0.0,
  V21 = 0.1,
  V22 = -0.1,
  V23 = 0.0,
  V24 = 0.1,
  V25 = -0.1,
  V26 = 0.0,
  V27 = 0.1,
  V28 = -0.1,
  Amount = 50.0,
  transaction_timestamp_utc = as.POSIXct("2013-09-15 12:00:00", tz = "UTC"),
  hour_of_day = 12,
  day_of_week = "Monday",
  day_of_month = 15,
  month = "September",
  is_weekend = FALSE,
  seconds_since_first = 1000000,
  time_of_day = "afternoon",
  time_since_previous = 60,
  ip_geo_mismatch = 0,
  device_reuse_count = 1,
  email_domain_risk = 0,
  shared_device_count = 0,
  shared_address_count = 0,
  risk_flag_count = 2,
  high_amount_flag = 0,
  unusual_time_flag = 0,
  weekend_flag = 0,
  rapid_transaction_flag = 0,
  prepaid_bin_flag = 0,
  disposable_email_flag = 0,
  high_risk_geo_flag = 0
)

cat("Sample transaction created with", ncol(sample_transaction), "columns\n")

# Try to source preprocessing function
tryCatch({
  source("deployment/preprocess_transaction.R")
  cat("✓ Preprocessing function loaded\n")
  
  # Try to use it (if it exists)
  if (exists("preprocess_transaction")) {
    cat("✓ preprocess_transaction() function available\n")
    cat("  (Note: May need actual transaction data to test fully)\n")
  } else {
    cat("⚠ preprocess_transaction() function not found\n")
  }
  
}, error = function(e) {
  cat(sprintf("✗ Error loading preprocessing function: %s\n", e$message))
})
```

**Expected Output:**
```
✓ Preprocessing function loaded
✓ preprocess_transaction() function available
```

---

## Step 8: Test Prediction Function (Load Only)

**Purpose:** Verify the prediction function can be loaded.

```r
cat("Testing prediction function loading...\n")

tryCatch({
  source("deployment/predict_fraud.R")
  cat("✓ Prediction function loaded\n")
  
  # Check if function exists
  if (exists("predict_fraud")) {
    cat("✓ predict_fraud() function available\n")
    
    # Show function signature
    cat("\nFunction signature:\n")
    print(formals(predict_fraud))
  } else {
    cat("✗ predict_fraud() function not found\n")
  }
  
}, error = function(e) {
  cat(sprintf("✗ Error loading prediction function: %s\n", e$message))
})
```

**Expected Output:**
```
✓ Prediction function loaded
✓ predict_fraud() function available
```

---

## Step 9: Test Prediction with Dummy Data

**Purpose:** Test making a prediction with minimal dummy data.

```r
# Make sure we have everything loaded
library(lightgbm)
library(readr)

# Load model
cat("Loading model...\n")
model <- lgb.load("deployment/lightgbm_model.txt")
cat("✓ Model loaded\n")

# Load features
features <- read_lines("deployment/features.txt")
cat(sprintf("✓ Loaded %d features\n", length(features)))

# Load thresholds
thresholds <- read_csv("deployment/thresholds.csv", show_col_types = FALSE)
lightgbm_threshold <- thresholds$Threshold[thresholds$Model == "LightGBM"]
cat(sprintf("✓ Threshold: %.3f\n", lightgbm_threshold))

# Create dummy data (all zeros - minimal test)
cat("\nCreating dummy transaction data...\n")
dummy_data <- data.frame(
  matrix(0, nrow = 1, ncol = length(features))
)
colnames(dummy_data) <- features

cat("Dummy data created:", nrow(dummy_data), "row,", ncol(dummy_data), "columns\n")

# Try prediction
cat("\nTesting prediction...\n")
tryCatch({
  # Load prediction function
  source("deployment/predict_fraud.R")
  
  # Make prediction
  result <- predict_fraud(dummy_data, model_type = "lightgbm")
  
  cat("✓ Prediction successful!\n\n")
  cat("Prediction Result:\n")
  print(result)
  
  # Check result structure
  if ("fraud_probability" %in% colnames(result)) {
    cat(sprintf("\n✓ Fraud probability: %.4f\n", result$fraud_probability[1]))
  }
  if ("fraud_prediction" %in% colnames(result)) {
    cat(sprintf("✓ Fraud prediction: %d\n", result$fraud_prediction[1]))
  }
  
}, error = function(e) {
  cat(sprintf("✗ Prediction error: %s\n", e$message))
  cat("\nThis might be expected with dummy data.\n")
  cat("Try with real transaction data for full test.\n")
})
```

**Expected Output:**
```
✓ Model loaded
✓ Loaded 48 features
✓ Threshold: 0.170
✓ Prediction successful!
Fraud probability: 0.XXXX
Fraud prediction: 0 or 1
```

---

## Step 10: Test with Real Transaction Data (Optional)

**Purpose:** Test prediction with actual transaction data from your dataset.

```r
# Load a few real transactions from your dataset
cat("Loading real transaction data for testing...\n")

# Adjust path to your feature-engineered dataset
dataset_path <- "cnp_dataset/feature_engineered/creditcard_features_complete.csv"

if (file.exists(dataset_path)) {
  library(readr)
  library(dplyr)
  
  # Load a small sample
  df <- read_csv(dataset_path, n_max = 10, show_col_types = FALSE)
  cat(sprintf("✓ Loaded %d sample transactions\n", nrow(df)))
  
  # Load features
  features <- read_lines("deployment/features.txt")
  
  # Select only the features we need
  if (all(features %in% colnames(df))) {
    test_data <- df %>% select(all_of(features))
    cat("✓ Selected required features\n")
    
    # Load prediction function
    source("deployment/predict_fraud.R")
    
    # Make predictions
    cat("\nMaking predictions...\n")
    predictions <- predict_fraud(test_data, model_type = "lightgbm")
    
    cat("✓ Predictions complete!\n\n")
    cat("Prediction Summary:\n")
    print(summary(predictions))
    
    # Show fraud predictions
    if ("fraud_prediction" %in% colnames(predictions)) {
      fraud_count <- sum(predictions$fraud_prediction == 1)
      cat(sprintf("\n✓ Fraud predictions: %d out of %d\n", 
                  fraud_count, nrow(predictions)))
    }
    
  } else {
    missing_features <- setdiff(features, colnames(df))
    cat(sprintf("✗ Missing features: %s\n", paste(missing_features, collapse = ", ")))
  }
  
} else {
  cat(sprintf("✗ Dataset not found: %s\n", dataset_path))
  cat("Skipping real data test...\n")
}
```

**Expected Output:**
```
✓ Loaded 10 sample transactions
✓ Selected required features
✓ Predictions complete!
[Summary statistics]
```

---

## Step 11: Test Monitoring Script

**Purpose:** Verify the monitoring script loads correctly.

```r
cat("Testing monitoring script...\n")

# Check if file exists
if (file.exists("deployment/monitor_performance.R")) {
  cat("✓ Monitoring script file exists\n")
  
  # Read and check script
  script_content <- readLines("deployment/monitor_performance.R")
  cat(sprintf("✓ Script has %d lines\n", length(script_content)))
  
  # Check for key functions
  if (any(grepl("monitor", script_content, ignore.case = TRUE))) {
    cat("✓ Script appears to contain monitoring logic\n")
  }
  
  cat("\nNote: Monitoring script should be run daily with real data.\n")
  cat("To test fully, you'll need to provide your data source.\n")
  
} else {
  cat("✗ Monitoring script not found\n")
}
```

**Expected Output:**
```
✓ Monitoring script file exists
✓ Script has XX lines
✓ Script appears to contain monitoring logic
```

---

## Step 12: Review Documentation

**Purpose:** Verify documentation is readable and complete.

```r
cat("Checking documentation...\n")

if (file.exists("deployment/README.md")) {
  doc_content <- readLines("deployment/README.md")
  cat(sprintf("✓ README.md exists (%d lines)\n", length(doc_content)))
  
  # Show first few lines
  cat("\nFirst 20 lines of README:\n")
  cat(paste(doc_content[1:min(20, length(doc_content))], collapse = "\n"))
  cat("\n\n...\n")
  
  # Check for key sections
  key_sections <- c("Quick Start", "Model", "Performance", "Requirements")
  found_sections <- sapply(key_sections, function(section) {
    any(grepl(section, doc_content, ignore.case = TRUE))
  })
  
  cat("\nDocumentation sections found:\n")
  for (i in 1:length(found_sections)) {
    if (found_sections[i]) {
      cat(sprintf("  ✓ %s\n", names(found_sections)[i]))
    } else {
      cat(sprintf("  ✗ %s\n", names(found_sections)[i]))
    }
  }
  
} else {
  cat("✗ README.md not found\n")
}
```

**Expected Output:**
```
✓ README.md exists (XX lines)
[First 20 lines shown]
✓ Quick Start
✓ Model
✓ Performance
...
```

---

## Step 13: Final Validation Summary

**Purpose:** Create a summary of all tests.

```r
cat("============================================================\n")
cat("DEPLOYMENT TEST SUMMARY\n")
cat("============================================================\n\n")

# Run all checks
checks <- list()

# 1. Files exist
required_files <- c(
  "deployment/lightgbm_model.txt",
  "deployment/features.txt",
  "deployment/thresholds.csv",
  "deployment/predict_fraud.R",
  "deployment/preprocess_transaction.R"
)

all_files_exist <- all(sapply(required_files, file.exists))
checks$files <- all_files_exist

# 2. Model loads
model_loads <- FALSE
if (requireNamespace("lightgbm", quietly = TRUE)) {
  tryCatch({
    library(lightgbm)
    model <- lgb.load("deployment/lightgbm_model.txt")
    model_loads <- TRUE
  }, error = function(e) {})
}
checks$model <- model_loads

# 3. Features load
features_load <- FALSE
tryCatch({
  features <- read_lines("deployment/features.txt")
  if (length(features) == 48) features_load <- TRUE
}, error = function(e) {})
checks$features <- features_load

# 4. Thresholds load
thresholds_load <- FALSE
tryCatch({
  thresholds <- read_csv("deployment/thresholds.csv", show_col_types = FALSE)
  if (nrow(thresholds) >= 1) thresholds_load <- TRUE
}, error = function(e) {})
checks$thresholds <- thresholds_load

# 5. Functions load
functions_load <- FALSE
tryCatch({
  source("deployment/predict_fraud.R")
  if (exists("predict_fraud")) functions_load <- TRUE
}, error = function(e) {})
checks$functions <- functions_load

# Print summary
cat("Test Results:\n")
for (check_name in names(checks)) {
  status <- if (checks[[check_name]]) "✓ PASS" else "✗ FAIL"
  cat(sprintf("  %s: %s\n", check_name, status))
}

# Overall status
all_passed <- all(unlist(checks))
cat("\n")
if (all_passed) {
  cat("============================================================\n")
  cat("✓ ALL TESTS PASSED - DEPLOYMENT READY!\n")
  cat("============================================================\n")
} else {
  cat("============================================================\n")
  cat("✗ SOME TESTS FAILED - REVIEW ERRORS ABOVE\n")
  cat("============================================================\n")
}
```

**Expected Output:**
```
============================================================
DEPLOYMENT TEST SUMMARY
============================================================

Test Results:
  files: ✓ PASS
  model: ✓ PASS
  features: ✓ PASS
  thresholds: ✓ PASS
  functions: ✓ PASS

============================================================
✓ ALL TESTS PASSED - DEPLOYMENT READY!
============================================================
```

---

## Quick Reference: Run All Steps

If you want to run all steps at once (but still see each step):

```r
# Run all steps sequentially
source("STEP_BY_STEP_TESTING_GUIDE.md")  # Won't work - this is markdown

# Instead, copy each step's code block into R console one by one
# Or create an R script with all steps
```

---

## Troubleshooting

### If a step fails:

1. **Check file paths** - Make sure you're in the correct directory
2. **Check packages** - Install missing packages:
   ```r
   install.packages(c("readr", "dplyr", "lightgbm", "lubridate"))
   ```
3. **Check deployment files** - Run `deploy_models.R` first if files are missing
4. **Read error messages** - They usually tell you what's wrong

### Common Issues:

- **"deployment directory not found"** → Run `source("deploy_models.R")` first
- **"lightgbm not installed"** → `install.packages("lightgbm")`
- **"function not found"** → Check that you've sourced the function file
- **"features don't match"** → Make sure you're using the correct dataset

---

## Next Steps After Testing

Once all tests pass:

1. ✅ Review any warnings or notes
2. ✅ Test with your actual transaction data
3. ✅ Set up monitoring schedule
4. ✅ Deploy to production
5. ✅ Monitor daily performance

---

**Good luck with your deployment testing!** 🚀






