# nf-core/coproid: Documentation

<img src="_static/img/coproid_logo.png" height="200">

**coproID** (**CO**prolite **ID**entification) is a tool developed at the 
[Max Planck insitute for the Science of Human History](http://www.shh.mpg.de/en) 
by [Maxime Borry](https://github.com/maxibor)

The purpose of **coproID** is to help identify the host of given sequenced 
microbiome when there is a doubt between species.

**coproID** is a pipeline developed using [Nextflow](https://www.nextflow.io/)

and made available through [nf-core](https://github.com/nf-core)

Even though it was developed with coprolite host identification in mind, it can
 be applied to any microbiome, provided they contain host DNA.

1. [Installation](https://nf-co.re/usage/installation)
2. Pipeline configuration
    * [Local installation](https://nf-co.re/usage/local_installation)
    * [Adding your own system config](https://nf-co.re/usage/adding_own_config)
    * [Reference genomes](https://nf-co.re/usage/reference_genomes)
3. [Running the pipeline](usage.md)
4. [Output and how to interpret the results](output.md)
5. [Troubleshooting](https://nf-co.re/usage/troubleshooting)


## Quick start

Example:
```
nextflow run maxibor/coproid --genome1 'GRCh37' --genome2 'CanFam3.1' --name1 'Homo_sapiens' --name2 'Canis_familiaris' --reads '*_R{1,2}.fastq.gz'
```

## coproID help menu

```
$ nextflow run nf-core/coproid --help
N E X T F L O W  ~  version 19.01.0
Launching `./main.nf` [nasty_ride] - revision: 362ad5aeaf
----------------------------------------------------
                                        ,--./,-.
        ___     __   __   __   ___     /,-._.--~'
  |\ | |__  __ /  ` /  \ |__) |__         }  {
  | \| |       \__, \__/ |  \ |___     \`-._,-`-,
                                        `._,._,'
  nf-core/coproid v1.0dev
----------------------------------------------------


 coproID: Coprolite Identification
 Homepage: https://github.com/nf-core/coproid
 Author: Maxime Borry <borry@shh.mpg.de>
 Version 1.0dev
=========================================
Usage:
The typical command for running the pipeline is as follows:
nextflow run maxibor/coproid --genome1 'GRCh37' --genome2 'CanFam3.1' --name1 'Homo_sapiens' --name2 'Canis_familiaris' --reads '*_R{1,2}.fastq.gz'
Mandatory arguments:
  --reads                       Path to input data (must be surrounded with quotes)
  --name1                       Name of candidate 1. Example: "Homo_sapiens"
  --fasta1                      Path to human genome fasta file (must be surrounded with quotes). Must be provided if --genome1 is not provided
  --genome1                     Name of iGenomes reference for Homo_sapiens. Must be provided if --fasta1 is not provided
  --name2                       Name of candidate 2. Example: "Canis_familiaris"
  --fasta2                      Path to canidate organism 2 genome fasta file (must be surrounded with quotes). Must be provided if --genome2 is not provided
  --genome2                     Name of iGenomes reference for candidate organism 2. Must be provided if --fasta2 is not provided
  --krakendb                    Path to MiniKraken2_v2_8GB Database

Options:
  --name3                       Name of candidate 1. Example: "Sus_scrofa"
  --fasta3                      Path to canidate organism 3 genome fasta file (must be surrounded with quotes). Must be provided if --genome3 is not provided
  --genome3                     Name of iGenomes reference for candidate organism 3. Must be provided if --fasta3 is not provided
  --adna                        Specified if data is modern (false) or ancient DNA (true). Default = true
  --phred                       Specifies the fastq quality encoding (33 | 64). Defaults to 33
  --singleEnd                   Specified if reads are single-end (true | false). Default = false
  --index1                      Path to Bowtie2 index of genome candidate 1, in the form of "/path/to/bowtie_index/basename"
  --index2                      Path to Bowtie2 index genome candidate 2 Coprolite maker's genome, in the form of "/path/to/bowtie_index/basename"
  --index3                      Path to Bowtie2 index genome candidate 3 Coprolite maker's genome, in the form of "/path/to/bowtie_index/basename"
  --collapse                    Specifies if AdapterRemoval should merge the paired-end sequences or not (true | false). Default = true
  --identity                    Identity threshold to retain read alignment. Default = 0.95
  --pmdscore                    Minimum PMDscore to retain read alignment. Default = 3
  --library                     DNA preparation library type ( classic | UDGhalf). Default = classic
  --bowtie                      Bowtie settings for sensivity (very-fast | very-sensitive). Default = very-sensitive
  --minKraken                   Minimum number of Kraken hits per Taxonomy ID to report. Default = 50

 Other options:
  --outdir                      The output directory where the results will be saved. Defaults to ./results
  --email                       Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits
  --maxMultiqcEmailFileSize     Theshold size for MultiQC report to be attached in notification email. If file generated by pipeline exceeds the threshold, it will not be attached (Default: 25MB)
  -name                         Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.
  --help  --h                   Shows this help page
```

## coproID example workFlow

![](_static/img/coproid_dag.png)

## How to cite coproID

The coproID article is coming.