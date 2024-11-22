#!/usr/bin/env python

# Written by Meriam van Os
import sys
import os
import pandas as pd

# Get command-line arguments
if len(sys.argv) < 3:
    print("Usage: python script.py <output_file> <csv_file_1> <csv_file_2> ...")
    sys.exit(1)

# Extract output file and CSV files
output_file = sys.argv[1]
csv_files = sys.argv[2:]

# Initialize an empty list to store filtered dataframes
filtered_data = []

# Loop through each CSV file
for file in csv_files:
    # Extract sample name from the file name
    sample_name = os.path.basename(file).split(".")[0]
    
    # Read the CSV file
    df = pd.read_csv(file)
    
    # Filter rows where 'count_taxon' > 0
    df_filtered = df[df['count_taxon'] > 0].copy()
    
    # Keep relevant columns and rename 'count_taxon' to the sample name
    df_filtered = df_filtered[['TAXID', 'name', 'rank', 'count_taxon']].rename(columns={'count_taxon': sample_name})
    
    # Append to the list
    filtered_data.append(df_filtered)

# Merge all filtered dataframes on TAXID, name, and rank
final_df = filtered_data[0]
for df in filtered_data[1:]:
    final_df = pd.merge(final_df, df, on=['TAXID', 'name', 'rank'], how='outer')

# Save the final table to the specified output file
final_df.to_csv(output_file, index=False)
