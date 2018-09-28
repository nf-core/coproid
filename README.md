[![Build Status](https://travis-ci.org/maxibor/coproID.svg?branch=master)](https://travis-ci.org/maxibor/coproID)   [![Documentation Status](https://readthedocs.org/projects/coproid/badge/?version=latest)](https://coproid.readthedocs.io/en/latest/?badge=latest) [![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

<img src="img/logo.png" height="150">  

## Introduction
**CoproID** helps you to identify the *"true maker"* of a sequenced Coprolite by comparing the reads mapping to each suspect genome.

## Documentation

The documentation of **coproID** can be found here [coproid.readthedocs.io](https://coproid.readthedocs.io)

## Requirements
- [Conda](https://conda.io/miniconda.html)
- Nextflow (`conda install -c bioconda nextflow`)

## How to run coproID

```
nextflow run maxibor/coproid --genome1 'genome1.fa' --genome2 'genome2.fa' --name1 'Homo_sapiens' --name2 'Canis_familiaris' --reads '*_R{1,2}.fastq.gz'
```

## Pipeline overview

![](img/dag.png)

## Get Help

```
$ nextflow run maxibor/coproid --help
N E X T F L O W  ~  version 0.31.1
Launching `maxibor/coproid` [irreverent_lumiere]

=========================================
 coproID: Coprolite Identification
 Homepage / Documentation: https://github.com/maxibor/coproid
 Author: Maxime Borry <borry@shh.mpg.de>
 Version 0.5
 Last updated on September 28th, 2018
=========================================
Usage:
The typical command for running the pipeline is as follows:
nextflow run maxibor/coproid --genome1 'genome1.fa' --genome2 'genome2.fa' --name1 'Homo_sapiens' --name2 'Canis_familiaris' --reads '*_R{1,2}.fastq.gz'
Mandatory arguments:
  --reads                       Path to input data (must be surrounded with quotes)
  --name1                       Name of candidate 1. Example: "Homo sapiens"
  --name2                       Name of candidate 2. Example: "Canis familiaris"

Options:
  --phred                       Specifies the fastq quality encoding (33 | 64). Defaults to 33
  --genome1                     Path to candidate 1 Coprolite maker's genome fasta file (must be surrounded with quotes) - Required if index1 is not set or mapdamage is activated
  --index1                      Path to Bowtie2 index genome andidate 1 Coprolite maker's genome, in the form of /path/to/*.bt2 - Required if genome1 is not set
  --genome1Size                 Size of candidate 1 Coprolite maker's genome in bp - If genome1 is not set
  --genome2                     Path to candidate 2 Coprolite maker's genome fasta file (must be surrounded with quotes)- Required if index2 is not set or mapdamage is activated
  --index2                      Path to Bowtie2 index genome andidate 2 Coprolite maker's genome, in the form of /path/to/*.bt2 - Required if genome2 is not set
  --genome2Size                 Size of candidate 2 Coprolite maker's genome in bp - If genome2 is not set
  --collapse                    Specifies if AdapterRemoval should merge the paired-end sequences or not (yes | no). Default = yes
  --identity                    Identity threshold to retain read alignment. Default = 0.85
  --bowtie                      Bowtie settings for sensivity (very-fast | very-sensitive). Default = very-sensitive
  --mapdamage                   Run mapDamage for DNA damage and aDNA authentification (yes | no). Default = yes

Other options:
  --results                     Name of result directory. Defaults to ./results
  --help  --h                   Shows this help page
```
