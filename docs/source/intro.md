Introduction
============

<img src="_static/_img/logo.png" height="150">

**coproID** (**CO**prolite **ID**entification) is a tool developed at the [Max Planck insitute for the Science of Human History](http://www.shh.mpg.de/en) by [Maxime Borry](https://github.com/maxibor)

The purpose of **coproID** is to help identify the host of given sequenced microbiome when there is a doubt between two species.

**coproID** is a pipeline developed using [Nextflow](https://www.nextflow.io/) and [Conda](https://conda.io/docs/) to ensure scalability and reproducibility.

Even though it was developed with coprolite host identification in mind, it can be applied to any microbiome, provided they contain host DNA.

To run **coproID** you need to provide as input:
- microbiome sequencing paired end `fastq` files
- **two** reference genomes (either in `fasta` format, or already `bowtie2` indexed)
- the names of the two reference species
- if you choose to give the reference genomes as indexed `bowtie2` files, you also need to provide the genomes sizes.

## Quick start

Example:
```
nextflow run maxibor/coproid --genome1 'genome1.fa' --genome2 'genome2.fa' --name1 'Homo_sapiens' --name2 'Canis_familiaris' --reads '*_R{1,2}.fastq.gz'
```

## coproID help menu

```
$ nextflow run maxibor/coproid --help
N E X T F L O W  ~  version 0.31.1
Launching `maxibor/coproid` [special_laplace] - revision: b579d0002f

=========================================
 coproID: Coprolite Identification
 Homepage: https://github.com/maxibor/coproid
 Documentation: https://coproid.readthedocs.io
 Author: Maxime Borry <borry@shh.mpg.de>
 Version 0.6
 Last updated on October 11th, 2018
=========================================
Usage:
The typical command for running the pipeline is as follows:
nextflow run maxibor/coproid --genome1 'genome1.fa' --genome2 'genome2.fa' --name1 'Homo_sapiens' --name2 'Canis_familiaris' --reads '*_R{1,2}.fastq.gz'
Mandatory arguments:
  --reads                       Path to input data (must be surrounded with quotes)
  --name1                       Name of candidate 1. Example: "Homo sapiens"
  --name2                       Name of candidate 2. Example: "Canis familiaris"
  --genome1                     Path to candidate 1 Coprolite maker's genome fasta file (must be surrounded with quotes)
  --genome2                     Path to candidate 2 Coprolite maker's genome fasta file (must be surrounded with quotes)

Options:
  --phred                       Specifies the fastq quality encoding (33 | 64). Defaults to 33
  --index1                      Path to Bowtie2 index genome andidate 1 Coprolite maker's genome, in the form of /path/to/*.bt2 - Required if genome1 is not set
  --index2                      Path to Bowtie2 index genome andidate 2 Coprolite maker's genome, in the form of /path/to/*.bt2 - Required if genome2 is not set
  --collapse                    Specifies if AdapterRemoval should merge the paired-end sequences or not (yes | no). Default = yes
  --identity                    Identity threshold to retain read alignment. Default = 0.95
  --bowtie                      Bowtie settings for sensivity (very-fast | very-sensitive). Default = very-sensitive
Other options:
  --results                     Name of result directory. Defaults to ./results
  --help  --h                   Shows this help page
```

## coproID example workFlow

![](_static/_img/dag.png)
