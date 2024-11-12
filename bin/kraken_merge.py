#!/usr/bin/env python

# Written by Maxime Borry and released under the MIT license.
# See git repository (https://github.com/nf-core/eager) for full license text.

import argparse
import os
import pandas as pd
import numpy as np


def _get_args():
    """This function parses and return arguments passed in"""
    parser = argparse.ArgumentParser(
        prog="merge_kraken_res",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description="Merging csv count files in one table",
    )
    parser.add_argument(
        "-or",
        dest="readout",
        default="kraken_read_count_table.csv",
        help="Read count output file. Default = kraken_read_count_table.csv",
    )
    args = parser.parse_args()

    readout = args.readout

    return readout


def get_csv():
    tmp = [i for i in os.listdir() if ".csv" in i]
    read = [i for i in tmp if ".read_" in i]
    return read


def _get_basename(file_name):
    if ("/") in file_name:
        basename = file_name.split("/")[-1].split(".")[0]
    else:
        basename = file_name.split(".")[0]
    return basename


def merge_csv(all_csv):
    df = pd.read_csv(all_csv[0], index_col=0)
    for i in range(1, len(all_csv)):
        df_tmp = pd.read_csv(all_csv[i], index_col=0)
        df = pd.merge(left=df, right=df_tmp, on="TAXID", how="outer")
    df.fillna(0, inplace=True)
    return df


def write_csv(pd_dataframe, outfile):
    pd_dataframe.to_csv(outfile)


if __name__ == "__main__":
    READOUT = _get_args()
    reads = get_csv()
    read_df = merge_csv(reads)
    write_csv(read_df, READOUT)
