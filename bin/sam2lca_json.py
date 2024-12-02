#!/usr/bin/env python


import os
import json
import argparse
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser("Create sam2lca json file")
    parser.add_argument(
        "acc2taxid", type=Path, help="Path to accession2taxid gzip compressed file"
    )
    parser.add_argument(
        "md5",
        type=Path,
        help="Path to accession2taxid gzip compressed md5 checksum file",
    )

    return parser.parse_args()


def write_json(acc2taxid, md5, db_name="adnamap"):
    sam2lca_dict = {
        "mapfiles": {db_name: [acc2taxid.as_posix()]},
        "mapmd5": {db_name: [md5.as_posix()]},
        "map_db": {db_name: f"{db_name}.db"},
    }
    with open(f"{db_name}.sam2lca.json", "w") as fh:
        json.dump(sam2lca_dict, fh)


if __name__ == "__main__":
    args = parse_args()
    write_json(args.acc2taxid, args.md5)
