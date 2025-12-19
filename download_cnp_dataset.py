"""
Script to download the CNP (Credit Card Fraud Detection) dataset from the Fraud Dataset Benchmark.

This script downloads the CNP dataset (ccfraud) which contains anonymized credit card 
transactions by European cardholders in September 2013.

Requirements:
1. Kaggle account and API credentials
2. Kaggle API token at: C:/Users/<username>/.kaggle/kaggle.json
   (Download from: https://www.kaggle.com/settings -> API -> Create New Token)

Usage:
    python download_cnp_dataset.py
"""

import os
import sys
import zipfile
import shutil

def check_kaggle_credentials():
    """Check if Kaggle credentials are set up."""
    kaggle_dir = os.path.join(os.path.expanduser("~"), ".kaggle")
    kaggle_json = os.path.join(kaggle_dir, "kaggle.json")
    
    if not os.path.exists(kaggle_json):
        print("ERROR: Kaggle credentials not found!")
        print(f"Expected location: {kaggle_json}")
        print("\nPlease follow these steps:")
        print("1. Go to https://www.kaggle.com/settings")
        print("2. Scroll to 'API' section")
        print("3. Click 'Create New Token'")
        print("4. Download the kaggle.json file")
        print(f"5. Place it in: {kaggle_dir}")
        return False
    
    print(f"✓ Kaggle credentials found at: {kaggle_json}")
    return True

def download_using_fdb():
    """Download CNP dataset using the Fraud Dataset Benchmark library."""
    try:
        # Add the fraud-dataset-benchmark to path
        sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'fraud-dataset-benchmark', 'src'))
        
        from fdb.datasets import FraudDatasetBenchmark
        
        print("\nDownloading CNP dataset using FDB...")
        print("This may take a few minutes...")
        
        # Download the dataset (don't delete after loading)
        obj = FraudDatasetBenchmark(
            key='ccfraud',
            load_pre_downloaded=False,
            delete_downloaded=False  # Keep the downloaded files
        )
        
        print("\n✓ Dataset downloaded successfully!")
        print(f"  Train set shape: {obj.train.shape}")
        print(f"  Test set shape: {obj.test.shape}")
        
        # Save to CSV files
        output_dir = "cnp_dataset"
        os.makedirs(output_dir, exist_ok=True)
        
        train_path = os.path.join(output_dir, "train.csv")
        test_path = os.path.join(output_dir, "test.csv")
        test_labels_path = os.path.join(output_dir, "test_labels.csv")
        
        obj.train.to_csv(train_path, index=False)
        obj.test.to_csv(test_path, index=False)
        obj.test_labels.to_csv(test_labels_path, index=False)
        
        print(f"\n✓ Dataset saved to:")
        print(f"  - {train_path}")
        print(f"  - {test_path}")
        print(f"  - {test_labels_path}")
        
        return True
        
    except ImportError as e:
        print(f"\nERROR: Could not import FDB library: {e}")
        print("Installing required packages...")
        return False
    except Exception as e:
        print(f"\nERROR: {e}")
        return False

def download_using_kaggle_api():
    """Download CNP dataset directly using Kaggle API."""
    try:
        import kaggle
        
        print("\nDownloading CNP dataset directly from Kaggle...")
        
        # Dataset configuration
        owner = "mlg-ulb"
        dataset = "creditcardfraud"
        filename = "creditcard.csv"
        
        output_dir = "cnp_dataset"
        os.makedirs(output_dir, exist_ok=True)
        
        # Download the entire dataset (newer API method)
        print("Downloading from Kaggle...")
        kaggle.api.dataset_download_files(
            dataset=f"{owner}/{dataset}",
            path=output_dir,
            unzip=True
        )
        
        # Check if file exists
        csv_path = os.path.join(output_dir, filename)
        if os.path.exists(csv_path):
            print(f"\n✓ Dataset downloaded successfully!")
            print(f"  Saved to: {csv_path}")
            return True
        else:
            # Try to find the file with different case or location
            import glob
            found_files = glob.glob(os.path.join(output_dir, "*.csv"))
            if found_files:
                print(f"\n✓ Dataset downloaded successfully!")
                print(f"  Found file: {found_files[0]}")
                return True
            else:
                print(f"\nERROR: File not found at {csv_path}")
                print(f"  Searched in: {output_dir}")
                return False
            
    except ImportError:
        print("\nERROR: Kaggle package not installed.")
        print("Installing kaggle package...")
        return False
    except Exception as e:
        print(f"\nERROR: {e}")
        import traceback
        traceback.print_exc()
        return False

def install_requirements():
    """Install required packages."""
    print("\nInstalling required packages...")
    try:
        import subprocess
        
        # Install the fraud-dataset-benchmark package
        benchmark_dir = os.path.join(os.path.dirname(__file__), "fraud-dataset-benchmark")
        if os.path.exists(benchmark_dir):
            subprocess.check_call([sys.executable, "-m", "pip", "install", "."], 
                                cwd=benchmark_dir)
            print("✓ Fraud Dataset Benchmark installed")
        
        # Install kaggle package
        subprocess.check_call([sys.executable, "-m", "pip", "install", "kaggle"])
        print("✓ Kaggle package installed")
        
        return True
    except Exception as e:
        print(f"ERROR installing packages: {e}")
        return False

def main():
    """Main function to download CNP dataset."""
    print("=" * 60)
    print("CNP Dataset Downloader")
    print("Credit Card Fraud Detection Dataset")
    print("=" * 60)
    
    # Check Kaggle credentials
    if not check_kaggle_credentials():
        return
    
    # Try to download using FDB first
    print("\nAttempting to download using Fraud Dataset Benchmark...")
    if download_using_fdb():
        print("\n" + "=" * 60)
        print("Download completed successfully!")
        print("=" * 60)
        return
    
    # If FDB fails, try installing requirements and retry
    print("\nFDB download failed. Installing requirements...")
    if install_requirements():
        print("\nRetrying download...")
        if download_using_fdb():
            print("\n" + "=" * 60)
            print("Download completed successfully!")
            print("=" * 60)
            return
    
    # Fallback to direct Kaggle API download
    print("\nTrying direct Kaggle API download...")
    if download_using_kaggle_api():
        print("\n" + "=" * 60)
        print("Download completed successfully!")
        print("=" * 60)
    else:
        print("\n" + "=" * 60)
        print("Download failed. Please check the error messages above.")
        print("=" * 60)

if __name__ == "__main__":
    main()

