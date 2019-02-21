#!/usr/bin/env python3


import argparse
import pandas as pd
import sys


def get_args():
    '''This function parses and return arguments passed in'''
    parser = argparse.ArgumentParser(
        prog='normalizedReadCount',
        description='Counts reads aligned to genome, and normalize by genome size')
    parser.add_argument(
        '-c',
        dest='countfile',
        default=None,
        help="normalized read count csv file")
    parser.add_argument(
        '-s',
        dest='sourcepredict',
        default=None,
        help="sourcepredict csv file")
    parser.add_argument(
        '-o',
        dest='output',
        default=None,
        help="output csv file")

    args = parser.parse_args()
    cf = args.countfile
    sp = args.sourcepredict
    out = args.output

    return(cf, sp, out)


def indicator(x):
    if x > 0.5:
        return(0)
    return(1)


def check_learning(orga, col_list):
    if orga not in col_list:
        print(f"{orga} not in machine learning dataset")
        sys.exit(1)


def compute_coproba(indic, nrr, sp):
    return(indic*nrr*sp)


if __name__ == "__main__":
    CF, SP, OUTPUT = get_args()

    dcf = pd.read_csv(CF, index_col=0)
    if dcf.shape[1] < 12:
        dcf.columns = ['Organism_name1',
                       'Organism_name2',
                       'Genome1_size',
                       'Genome2_size',
                       'nb_bp_aligned_genome1',
                       'nb_bp_aligned_genome2',
                       'normalized_nb_bp_aligned_genome1',
                       'normalized_nb_bp_aligned_genome2',
                       'NormalizedReadRatio_1',
                       'NormalizedReadRatio_2']
        orga1 = dcf['Organism_name1'][0]
        orga2 = dcf['Organism_name2'][0]
    else:
        dcf.columns = ['Organism_name1',
                       'Organism_name2',
                       'Organism_name3',
                       'Genome1_size',
                       'Genome2_size',
                       'Genome3_size',
                       'nb_bp_aligned_genome1',
                       'nb_bp_aligned_genome2',
                       'nb_bp_aligned_genome3',
                       'normalized_nb_bp_aligned_genome1',
                       'normalized_nb_bp_aligned_genome2',
                       'normalized_nb_bp_aligned_genome3',
                       'NormalizedReadRatio_1',
                       'NormalizedReadRatio_2',
                       'NormalizedReadRatio_3']
        orga3 = dcf['Organism_name3'][0]

    dsp = pd.read_csv(SP, index_col=0).T

    if orga3:
        check_learning(orga1, dsp.columns)
        check_learning(orga2, dsp.columns)
        check_learning(orga3, dsp.columns)
    else:
        check_learning(orga1, dsp.columns)
        check_learning(orga2, dsp.columns)

    d = dcf.merge(dsp, left_index=True, right_index=True)

    coproba_list_orga1 = [compute_coproba(
        indic=indicator(a), nrr=b, sp=c) for a, b, c in zip(list(d['unknown']), list(d['normalized_nb_bp_aligned_genome1']), list(d[orga1]))]
    coproba_list_orga2 = [compute_coproba(
        indic=indicator(a), nrr=b, sp=c) for a, b, c in zip(list(d['unknown']), list(d['normalized_nb_bp_aligned_genome2']), list(d[orga2]))]
    if orga3:
        coproba_list_orga3 = [compute_coproba(indic=indicator(a), nrr=b, sp=c) for a, b, c in zip(
            list(d['unknown']), list(d['normalized_nb_bp_aligned_genome3']), list(d[orga3]))]

    d2 = pd.DataFrame()
    d2[f"normalized_bp_proportion_aligned_{orga1}"] = d['nb_bp_aligned_genome1']
    d2[f"normalized_bp_proportion_aligned_{orga2}"] = d['nb_bp_aligned_genome2']
    if orga3:
        d2[f"nb_bp_aligned_{orga3}"] = d['nb_bp_aligned_genome3']
    d2[f"metagenomic_proportion_{orga1}"] = d[orga1]
    d2[f"metagenomic_proportion_{orga2}"] = d[orga2]
    if orga3:
        d2[f"metagenomic_proportion_{orga3}"] = d[orga3]
    d2[f"coproID_proba_{orga1}"] = coproba_list_orga1
    d2[f"coproID_proba_{orga2}"] = coproba_list_orga2
    if orga3:
        d2[f"coproID_proba_{orga3}"] = coproba_list_orga3
    d2.index = d.index

    d2.to_csv(OUTPUT)
