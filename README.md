[![Build Status](https://travis-ci.org/maxibor/coproID.svg?branch=master)](https://travis-ci.org/maxibor/coproID)

<img src="img/logo.png" height="150">
## Introduction
**CoproID** helps you to identify the *"true maker"* of a sequenced Coprolite by comparing the reads mapping to suspects genomes.

The mapped read count for each suspect's genome is normalized by the suspect's genome size.  

**Currently in development**

## Requirements
- [Conda](https://conda.io/miniconda.html)
- Nextflow (`conda install -c bioconda nextflow`)

## How to run coproID

```
nextflow run maxibor/coproid --genome1 'genome1.fa' --genome2 'genome2.fa' --reads '*_R{1,2}.fastq.gz'
```


## Get Help

```
$ nextflow run maxibor/coproid --help
N E X T F L O W  ~  version 0.31.1
Launching `main.nf` [tiny_colden] - revision: 17ab817ad7

=========================================
 coproID: Coprolite Identification
 Homepage / Documentation: https://github.com/maxibor/coproid
 Author: Maxime Borry <borry@shh.mpg.de>
 Version 0.1
 Last updated on September 18th, 2018
=========================================
Usage:
The typical command for running the pipeline is as follows:
nextflow run maxibor/coproid --genome1 'genome1.fa --name1 'Homo_sapiens' --genome2 'genome2.fa' --name2 'Canis_familiaris' --reads '*_R{1,2}.fastq.gz'
Mandatory arguments:
  --reads                       Path to input data (must be surrounded with quotes)

Options:
  --phred                       Specifies the fastq quality encoding (33 | 64). Defaults to 33
  --genome1                     Path to candidate 1 Coprolite maker's genome fasta file (must be surrounded with quotes) - If index1 is not set
  --index1                      Path to Bowtie2 index genome andidate 1 Coprolite maker's genome, in the form of /path/to/bt_index/*.bt2 - If genome1 is not set
  --genome1Size                 Size of candidate 1 Coprolite maker's genome in bp - If genome1 is not set
  --name1                       Name of candidate 1. Example: "Homo_sapiens"
  --genome2                     Path to candidate 2 Coprolite maker's genome fasta file (must be surrounded with quotes)- If index2 is not set
  --index2                      Path to Bowtie2 index genome andidate 2 Coprolite maker's genome, in the form of /path/to/bt_index/*.bt2 - If genome2 is not set
  --genome2Size                 Size of candidate 2 Coprolite maker's genome in bp - If genome2 is not set
  --name2                       Name of candidate 2. Example: "Canis_familiaris"

Other options:
  --results                     Name of result directory. Defaults to ./results
  --help  --h                   Shows this help page
```
