#!/usr/bin/env python -W ignore::DeprecationWarning

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import GridSearchCV
from sklearn.model_selection import train_test_split
from sklearn import metrics
from . import normalize

from . import utils


class sourceforest():

    def __init__(self, source, sink):
        self.source = pd.read_csv(source, index_col=0)
        self.tmp_feat = self.source.drop(
            ['labels'], axis=0).apply(pd.to_numeric)
        self.y = self.source.loc['labels', :][1:]
        self.y = self.y.append(pd.Series(['unknown'], index=['unknown']))
        self.tmp_sink = pd.read_csv(sink, dtype='int64')
        self.combined = pd.DataFrame(pd.merge(
            left=self.tmp_feat, right=self.tmp_sink, how='outer', on='TAXID').fillna(0))
        return None

    def __repr__(self):
        return(f'A sourceforest object of source {self.source} and sink {self.sink}')

    def add_unknown(self, alpha):
        '''
        alpha: proportion of unknown for each OTU
        '''
        self._ = self.tmp_sink.drop('TAXID', 1)
        self.unknown = self._.multiply(alpha)
        self.unknown['TAXID'] = self.tmp_sink['TAXID']
        self.unknown.columns = ['UNKNOWN', 'TAXID']
        self.combined_unknown = pd.merge(left=self.combined, right=self.unknown,
                                         on='TAXID', how='outer').drop(['TAXID'], axis=1).fillna(0)

    def normalize(self, method):
        print(type(self.combined))
        if method == 'RLE':
            self.normalized = normalize.RLE_normalize(
                self.combined.drop(['TAXID'], axis=1))
        elif method == 'SUBSAMPLE':
            self.normalized = normalize.subsample_normalize_pd(
                self.combined.drop(['TAXID'], axis=1))
        elif method == 'CLR':
            self.normalized = normalize.CLR_normalize(
                self.combined.drop(['TAXID'], axis=1))
        self.normalized['UNKNOWN'] = self.combined_unknown['UNKNOWN']
        self.feat = self.normalized.loc[:, self.source.columns[1:]].T
        self.feat.loc['UNKNOWN', :] = self.normalized['UNKNOWN']
        self.sink = self.normalized.drop(self.source.columns[1:], axis=1).T
        self.sink = self.sink.drop('UNKNOWN', axis=0)
        return(self.feat, self.sink)

    def rndForest(self, seed, threads, ratio):
        train_features, test_features, train_labels, test_labels = train_test_split(
            self.feat, self.y, test_size=0.2, random_state=seed)
        self._forest = RandomForestClassifier(
            n_jobs=threads, n_estimators=1000, class_weight="balanced", random_state=seed)
        print("Training classifier")
        self._forest.fit(train_features, train_labels)
        y_pred = self._forest.predict(test_features)
        print("Training Accuracy:", metrics.accuracy_score(test_labels, y_pred))
        self.sink_pred = self._forest.predict_proba(self.sink)
        utils.print_class(classes=self._forest.classes_, pred=self.sink_pred)
        utils.print_ratio(classes=self._forest.classes_,
                          pred=self.sink_pred, ratio_orga=ratio)
