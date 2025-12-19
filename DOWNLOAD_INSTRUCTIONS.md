# Download CNP Dataset Instructions

This guide will help you download the CNP (Credit Card Fraud Detection) dataset from the Fraud Dataset Benchmark.

## Dataset Information

- **Dataset Name**: Credit Card Fraud Detection
- **Dataset Key**: `ccfraud`
- **Source**: Kaggle (https://www.kaggle.com/mlg-ulb/creditcardfraud/)
- **Description**: Contains anonymized credit card transactions by European cardholders in September 2013
- **Training Records**: 227,845
- **Test Records**: 56,962
- **Features**: 28 numerical features (PCA transformed)
- **Fraud Rate**: 0.18%

## Prerequisites

1. **Kaggle Account**: You need a free Kaggle account
   - Sign up at: https://www.kaggle.com/

2. **Kaggle API Credentials**: 
   - Go to: https://www.kaggle.com/settings
   - Scroll to the "API" section
   - Click "Create New Token"
   - This will download a `kaggle.json` file
   - Place it in: `C:\Users\<YourUsername>\.kaggle\kaggle.json`
   - On Windows, create the `.kaggle` folder in your user directory if it doesn't exist

3. **Python 3.7+**: Make sure Python is installed

## Installation Steps

1. **Install Required Packages**:
   ```bash
   cd fraud-dataset-benchmark
   pip install .
   pip install kaggle
   ```

2. **Verify Kaggle Credentials**:
   The script will check if your Kaggle credentials are set up correctly.

## Download Methods

### Method 1: Using the Download Script (Recommended)

Run the provided Python script:

```bash
python download_cnp_dataset.py
```

This script will:
- Check for Kaggle credentials
- Download the dataset using the Fraud Dataset Benchmark library
- Save the dataset to `cnp_dataset/` folder with:
  - `train.csv` - Training data
  - `test.csv` - Test data  
  - `test_labels.csv` - Test labels

### Method 2: Using Python Code Directly

You can also use the FDB library directly in your Python code:

```python
from fdb.datasets import FraudDatasetBenchmark

# Download and load the CNP dataset
obj = FraudDatasetBenchmark(
    key='ccfraud',
    load_pre_downloaded=False,
    delete_downloaded=False  # Keep downloaded files
)

# Access the data
train_data = obj.train
test_data = obj.test
test_labels = obj.test_labels

# Save to CSV if needed
train_data.to_csv('cnp_train.csv', index=False)
test_data.to_csv('cnp_test.csv', index=False)
test_labels.to_csv('cnp_test_labels.csv', index=False)
```

### Method 3: Direct Kaggle Download

You can also download directly from Kaggle using the Kaggle CLI:

```bash
kaggle datasets download -d mlg-ulb/creditcardfraud
```

Then extract the zip file to get `creditcard.csv`.

## Troubleshooting

### Error: "Kaggle credentials not found"
- Make sure you've downloaded the `kaggle.json` file from Kaggle
- Place it in the correct location: `C:\Users\<YourUsername>\.kaggle\kaggle.json`
- On Windows, the `.kaggle` folder might be hidden - make sure to show hidden folders

### Error: "ApiException: (403)"
- Make sure you're signed in to Kaggle
- Verify your API token is valid (you may need to regenerate it)
- For some datasets (like `ieeecis`), you need to join the competition first, but `ccfraud` doesn't require this

### Error: "ModuleNotFoundError"
- Install the required packages:
  ```bash
  pip install kaggle pandas numpy scikit-learn
  cd fraud-dataset-benchmark
  pip install .
  ```

## Dataset Files

After successful download, you'll have:

- `cnp_dataset/train.csv` - Training dataset (227,845 rows)
- `cnp_dataset/test.csv` - Test dataset (56,962 rows)
- `cnp_dataset/test_labels.csv` - Test labels for evaluation

## License

The dataset is licensed under the Open Data Commons Database License (DbCL) v1.0.
See: https://opendatacommons.org/licenses/dbcl/1-0/

## Citation

If you use this dataset, please cite:

```bibtex
@misc{grover2023fraud,
      title={Fraud Dataset Benchmark and Applications}, 
      author={Prince Grover and Julia Xu and Justin Tittelfitz and Anqi Cheng and Zheng Li and Jakub Zablocki and Jianbo Liu and Hao Zhou},
      year={2023},
      eprint={2208.14417},
      archivePrefix={arXiv},
      primaryClass={cs.LG}
}
```






