#!/usr/bin/env python

# Written by Meriam van Os, released under the MIT license
# See https://opensource.org/license/mit for details

import pandas as pd
import sys
import pathlib

def process_file(file_path):
    # Extract sample and taxa names from the directory structure
    sample_file = pathlib.Path(file_path).stem
    sample_name, taxa_name = sample_file.split("-")
    taxa_name = taxa_name.replace("_pydamage_results","")

    # Read the CSV file
    df = pd.read_csv(file_path)

    # Select relevant columns and add sample and taxa information
    df_filtered = df[['pvalue', 'damage_model_pmax']].copy()
    df_filtered['Sample'] = sample_name
    df_filtered['Taxa'] = taxa_name

    # Reorder columns
    return df_filtered[['Sample', 'Taxa', 'pvalue', 'damage_model_pmax']]

def main():
    if len(sys.argv) < 3:
        print("Usage: python script.py <output_file> <csv_file_1> <csv_file_2> ...")
        sys.exit(1)

    # Get output file name and input CSV file paths
    output_file = sys.argv[1]
    input_files = sys.argv[2:]

    # Process all input files
    results = [process_file(file_path) for file_path in input_files]

    # Combine results into a single DataFrame
    final_df = pd.concat(results, ignore_index=True)

    # Save the combined DataFrame to the output file
    final_df.to_csv(output_file, index=False)

if __name__ == "__main__":
    main()
