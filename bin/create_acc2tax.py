#!/usr/bin/env python

# Written by Maxime Borry, released under the MIT license
# See https://opensource.org/license/mit for details

"""Creates an acc2tax mapping file from a genome FASTA."""

import argparse
import pysam
from pathlib import Path

def parse_args():
    parser = argparse.ArgumentParser("Create acc2tax file")
    parser.add_argument("genome", type=Path, help="Path to genome file")
    parser.add_argument("-t", type=int, dest="taxid", help="taxid")

    return parser.parse_args()


def acc2tax(genome, taxid):
    entry_dict = dict()
    with pysam.FastxFile(genome) as fh:
        for entry in fh:
            entry_dict[entry.name] = [entry.name.split(".")[0], taxid]
    with open(f"{taxid}.accession2taxid", "w") as fh:
        fh.write("accession\taccession.version\ttaxid\n")
        for k, v in entry_dict.items():
            fh.write(f"{v[0]}\t{k}\t{v[1]}\n")


if __name__ == "__main__":
    args = parse_args()
    acc2tax(args.genome, args.taxid)
