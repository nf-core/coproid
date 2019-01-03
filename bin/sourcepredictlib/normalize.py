#!/usr/bin/env python -W ignore::DeprecationWarning

from numpy import log, average, inf, nan, median, exp, interp, floor
import pandas as pd
from functools import partial


def RLE_normalize(pd_dataframe):
    '''
    Normalize with Relative Log Expression
    INPUT:
        pd_dataframe(pandas DataFrame): Colums as Samples, Rows as OTUs
    OUTPUT:
        step7(pandas DataFrame): RLE Normalized. Colums as Samples, Rows as OTUs
    '''
    step1 = pd_dataframe.apply(log, 0)
    step2 = step1.apply(average, 1)
    step3 = step2[step2.replace([inf, -inf], nan).notnull()]
    step4_1 = step1[step1.replace(
        [inf, -inf], nan).notnull().all(axis=1)]
    step4 = step4_1.subtract(step3, 0)
    step5 = step4.apply(median, 0)
    step6 = step5.apply(exp)
    step7 = pd_dataframe.divide(step6, 1).apply(round, 1)
    return(step7)


def subsample_normalize_pd(pd_dataframe):
    '''
    Normalize with Subsampling
    INPUT:
        pd_dataframe(pandas DataFrame): Colums as Samples, Rows as OTUs
    OUTPUT:
        step7(pandas DataFrame): SubSample Normalized. Colums as Samples, Rows as OTUs
    '''
    def subsample_normalize(serie, omax):
        '''
        imin: minimum of input range
        imax: maximum of input range
        omin: minimum of output range
        omax: maximum of output range
        x in [imin,imax]
        f(x) in [omin, omax]

                 x - imin
        f(x) = ------------ x (omax - omin) + omin
               imax - imin

        '''
        imin = min(serie)
        imax = max(serie)
        omin = 0
        if imax > 0:
            newserie = serie.apply(lambda x: (
                (x - imin)/(imax - imin)*(omax-omin)+omin))
        else:
            newserie = serie
        return(newserie)

    step1 = pd_dataframe.apply(max, 1)
    themax = max(step1)

    step2 = pd_dataframe.apply(
        subsample_normalize, axis=0, args=(themax,))
    step3 = step2.apply(floor, axis=1)
    return(step3)


def CLR_normalize(pd_dataframe):
    d = pd_dataframe
    d = d+1
    step1_1 = d.apply(log, 0)
    step1_2 = step1_1.apply(average, 0)
    step1_3 = step1_2.apply(exp)
    step2 = d.divide(step1_3, 1)
    step3 = step2.apply(log, 0)
    return(step3)
