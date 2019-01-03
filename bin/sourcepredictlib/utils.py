import sys
import random
import numpy as np


def print_class(classes, pred):
    [print(f'{i}:{j}') for i, j in zip(list(classes), list(pred[0, :]))]


def print_ratio(classes, pred, ratio_orga):
    pred_class = {i: j for i, j in zip(list(classes), list(pred[0, :]))}
    num = pred_class[ratio_orga]
    denom = 0
    for i in pred_class.keys():
        if i != ratio_orga:
            denom += pred_class[i]
    print(np.log(num/denom))


def check_norm(method):
    methods = ['RLE', 'CLR', 'SUBSAMPLE']
    method = method.upper()
    if method not in methods:
        print("Please check the normalization method (RLE or Subsample)")
        sys.exit(1)
    else:
        return(method)


def check_gen_seed(seed):
    if seed is None:
        return(random.randint(1, 10000))
    else:
        return(int(seed))
