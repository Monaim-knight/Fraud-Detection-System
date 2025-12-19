"""
Export MySQL Data to CSV for Tableau (ARM Windows Compatible)
This script connects directly to MySQL (no ODBC needed) and exports data for Tableau
"""

# =============================================================================
# CONFIGURATION - EDIT THESE VALUES
# =============================================================================

MYSQL_HOST = "localhost"
MYSQL_PORT = 3306
MYSQL_USER = "root"
MYSQL_PASSWORD = ""  # Enter your MySQL password here
MYSQL_DATABASE = "fraud_detection_db"

# Output directory for CSV files
OUTPUT_DIR = "tableau_exports"

# =============================================================================
# SETUP
# =============================================================================

import os
import csv
import sys

try:
    import mysql.connector
    from mysql.connector import Error
except ImportError:
    print("Installing mysql-connector-python...")
    os.system(f"{sys.executable} -m pip install mysql-connector-python")
    import mysql.connector
    from mysql.connector import Error

# Create output directory
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)
    print(f"Created output directory: {OUTPUT_DIR}")

# =============================================================================
# CONNECT TO MYSQL
# =============================================================================

print("Connecting to MySQL...")

try:
    connection = mysql.connector.connect(
        host=MYSQL_HOST,
        port=MYSQL_PORT,
        user=MYSQL_USER,
        password=MYSQL_PASSWORD,
        database=MYSQL_DATABASE
    )
    
    if connection.is_connected():
        print("✓ Connected to MySQL successfully!\n")
        
        cursor = connection.cursor()
        
        # =============================================================================
        # GET LIST OF TABLES AND VIEWS
        # =============================================================================
        
        print("Getting list of tables and views...")
        cursor.execute("SHOW FULL TABLES")
        tables = cursor.fetchall()
        print(f"Found {len(tables)} tables/views\n")
        
        # =============================================================================
        # EXPORT EACH TABLE/VIEW
        # =============================================================================
        
        exported_files = []
        
        for (table_name, table_type) in tables:
            print(f"Exporting: {table_name} ({table_type})...", end=" ")
            
            try:
                # Read data from table/view
                cursor.execute(f"SELECT * FROM `{table_name}`")
                columns = [desc[0] for desc in cursor.description]
                data = cursor.fetchall()
                
                # Create filename (replace dots with underscores for CSV compatibility)
                filename = table_name.replace(".", "_")
                filepath = os.path.join(OUTPUT_DIR, f"{filename}.csv")
                
                # Write to CSV
                with open(filepath, 'w', newline='', encoding='utf-8') as csvfile:
                    writer = csv.writer(csvfile)
                    writer.writerow(columns)  # Write header
                    writer.writerows(data)    # Write data
                
                print(f"✓ ({len(data)} rows, {len(columns)} columns)")
                exported_files.append(filepath)
                
            except Error as e:
                print(f"✗ Error: {e}")
        
        # =============================================================================
        # EXPORT SPECIFIC VIEWS FOR TABLEAU (if they exist)
        # =============================================================================
        
        print("\n--- Exporting Tableau-specific views ---")
        
        # List of views that might exist (from prepare_tableau_data_mysql.sql)
        tableau_views = [
            "tableau_fraud_data",
            "tableau_fraud_summary",
            "tableau_fraud_trends",
            "tableau_customer_analysis",
            "tableau_transaction_details"
        ]
        
        for view_name in tableau_views:
            if any(t[0] == view_name for t in tables):
                print(f"Exporting view: {view_name}...", end=" ")
                
                try:
                    cursor.execute(f"SELECT * FROM `{view_name}`")
                    columns = [desc[0] for desc in cursor.description]
                    data = cursor.fetchall()
                    
                    filename = view_name.replace(".", "_")
                    filepath = os.path.join(OUTPUT_DIR, f"{filename}.csv")
                    
                    with open(filepath, 'w', newline='', encoding='utf-8') as csvfile:
                        writer = csv.writer(csvfile)
                        writer.writerow(columns)
                        writer.writerows(data)
                    
                    print(f"✓ ({len(data)} rows)")
                    exported_files.append(filepath)
                    
                except Error as e:
                    print(f"✗ Error: {e}")
        
        # =============================================================================
        # SUMMARY
        # =============================================================================
        
        print("\n" + "=" * 60)
        print("EXPORT COMPLETE!")
        print("=" * 60 + "\n")
        print(f"Exported {len(exported_files)} files to: {OUTPUT_DIR}\n")
        print("Files exported:")
        for file in exported_files:
            file_size = os.path.getsize(file) / 1024  # Size in KB
            print(f"  - {os.path.basename(file)} ({file_size:.2f} KB)")
        
        print("\nNext steps:")
        print("1. Open Tableau Desktop")
        print("2. Connect to 'Text file' or 'Microsoft Excel'")
        print(f"3. Select one of the CSV files from: {OUTPUT_DIR}")
        print("4. Build your dashboard!\n")
        
        cursor.close()
        connection.close()
        print("✓ MySQL connection closed")
        
except Error as e:
    print(f"\n✗ ERROR: Could not connect to MySQL")
    print(f"Error message: {e}\n")
    print("Please check:")
    print("  - MySQL service is running")
    print("  - Host, port, username, password are correct")
    print("  - Database name is correct")
    print("  - mysql-connector-python package is installed")
    print("\nTo install mysql-connector-python:")
    print(f"  {sys.executable} -m pip install mysql-connector-python")



