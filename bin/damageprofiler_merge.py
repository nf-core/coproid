#!/usr/bin/env python
import sys
import pandas as pd

def merge_and_reshape(output_file, input_file_list):
    # Initialize a list to hold all dataframes
    data_frames = []

    for file_path in input_file_list:
        # Debug: print the file path
        print(f"Processing file: {file_path}")
        
        # Split the file path into components
        file_parts = file_path.split("/")
        
        # Check if we have enough parts in the path
        if len(file_parts) < 2:
            print(f"Warning: Invalid file path structure: {file_path}")
            continue
        
        # Extract the sample and genome name from the folder/file structure
        sample_genome = file_parts[-2]  # Folder name is the sample-genome
        
        # Split sample and genome based on the new naming convention
        try:
            sample, genome = sample_genome.split("-")
        except ValueError:
            print(f"Error: Could not split '{sample_genome}' into sample and genome.")
            continue
        
        # Extract frequency type (e.g., '3pGtoA' or '5pCtoT') from the file name
        freq_type = file_parts[-1].split("_")[0]  # File name without extension
        column_name_prefix = f"{sample}-{genome}-{freq_type}"
        
        # Read the file, skipping comment lines
        df = pd.read_csv(file_path, sep="\t", comment="#")
        
        # Rename the second column to match the desired column name format
        df.columns = ["pos", column_name_prefix]
        
        # Add the dataframe to the list
        data_frames.append(df)
    
    # Merge all dataframes on the 'pos' column
    merged_df = data_frames[0]
    for df in data_frames[1:]:
        merged_df = pd.merge(merged_df, df, on="pos", how="outer")
    
    # Melt the merged dataframe to long format
    df_long = pd.melt(merged_df, id_vars=["pos"], var_name="sample_reference_prime", value_name="value")
    
    # Split the combined column into separate columns
    df_long[["Sample", "Reference", "prime_end"]] = df_long["sample_reference_prime"].str.split("-", expand=True)
    
    # Pivot the table to the desired format
    reshaped_df = df_long.pivot_table(
        index=["Sample", "Reference", "prime_end"],
        columns="pos",
        values="value"
    ).reset_index()
    
    # Rename the columns to ensure positions are aligned as integers
    reshaped_df.columns.name = None  # Remove the pivot table's columns name
    reshaped_df.columns = ["Sample", "Reference", "prime_end"] + [str(col) for col in sorted(merged_df["pos"].unique())]
    
    # Save the output to a file
    reshaped_df.to_csv(output_file, index=False, sep="\t")
    print(f"Reshaped table saved to {output_file}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python script.py <output_file> <file_paths.txt>")
        sys.exit(1)

    output_file = sys.argv[1]
    file_paths_txt = sys.argv[2]

    # Read the file paths from file_paths.txt
    with open(file_paths_txt, 'r') as file:
        input_files = [line.strip() for line in file.readlines()]

    # Call the function with the list of file paths
    merge_and_reshape(output_file, input_files)
