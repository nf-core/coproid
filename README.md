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
$ nextflow run main.nf --h
N E X T F L O W  ~  version 0.31.1
Launching `main.nf` [tender_khorana] - revision: c2b2913992

=========================================
 coproID: Coprolite Identification
 Homepage / Documentation: https://github.com/maxibor/coproid
 Author: Maxime Borry <borry@shh.mpg.de>
 Version 0.1
 Last updated on September 14th, 2018
=========================================
Usage:
The typical command for running the pipeline is as follows:
nextflow run maxibor/coproid --genome1 'genome1.fa' --genome2 'genome2.fa' --reads '*_R{1,2}.fastq.gz'
Mandatory arguments:
  --reads                       Path to input data (must be surrounded with quotes)
  --genome1                     Path to candidate 1 Coprolite maker's genome fasta file (must be surrounded with quotes)
  --genome2                     Path to candidate 1 Coprolite maker's genome fasta file (must be surrounded with quotes)

Options:
  --phred                       Specifies the fastq quality encoding (33 | 64). Defaults to 33
  --trimmingCPU                 Specifies the number of CPU used to trimming/cleaning by AdapterRemoval. Defaults to 4
  --bowtieCPU                   Specifies the number of CPU used by bowtie2 aligner. Defaults to 4
  --countCPU                    Specifies the number of CPU used for counting and normalizing reads. Defaults to 4

Other options:
  --results                     Name of result directory. Defaults to ./results
  --help  --h                   Shows this help page
```
