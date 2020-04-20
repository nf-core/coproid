# Output

This document describes the output produced by the coproID pipeline.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/)
and processes data using the following steps:

## FastQC

[FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) gives general quality metrics about your reads. It provides information about the quality score distribution across your reads, the per base sequence content (%T/A/G/C). You get information about adapter contamination and other overrepresented sequences.

For further reading and documentation see the [FastQC help](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/).

> **NB:** The FastQC plots displayed in the MultiQC report shows _untrimmed_ reads. They may contain adapter sequence and potentially regions with low quality.

### AdapterRemoval

[AdapterRemoval](https://github.com/MikkelSchubert/adapterremoval) searches for and removes remnant adapter sequences from High-Throughput Sequencing (HTS) data and (optionally) trims low quality bases from the 3' end of reads following adapter removal. AdapterRemoval can analyze both single end and paired end data, and can be used to merge overlapping paired-ended reads into (longer) consensus sequences.

### Bowtie2

[Bowtie 2](http://bowtie-bio.sourceforge.net/bowtie2/index.shtml) is an ultrafast and memory-efficient tool for aligning sequencing reads to long reference sequences.
This plot shows the number of reads aligning to the reference in different ways.

### DamageProfiler

[DamageProfiler](https://github.com/Integrative-Transcriptomics/DamageProfiler) calculates damage profiles of mapped reads.
These plots represents the damage patterns and read length distribution.

## coproID_report.html

This file contains the coproID report

### coproID summary table

This table summarizes the read ratios and microbiome source proportions as computed by coproID and sourcepredict.
You can download the table in `.csv` format by clicking on the green "Download" button.

### microbiome profile embedding

This interactive plot shows the embedding of the microbiome samples by [sourcepredict](https://github.com/maxibor/sourcepredict)

### Damage plots

These plots represent the damage patterns computed by DamageProfiler

## coproID_result.csv

This table summarizes the read ratios and microbiome source proportions as computed by coproID and sourcepredict.

## coproID_bp.csv

This table contains the mapped base pair counts (ancient and modern reads) for each sample.

## kraken

This directory contains the merged OTU count for all samples of the run, as counted by [Kraken2](https://ccb.jhu.edu/software/kraken2/)

## damageprofiler

This directory contains all the output files of DamageProfiler (see multiqc section above)

## MultiQC

[MultiQC](http://multiqc.info) is a visualisation tool that generates a single HTML report summarising all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available in within the report data directory.

## alignments

This directory contains the alignment `.bam` files for aligned and aligned sequences to each target genome.

## pmdtools

This directory contains the alignment `.bam` files for aligned and aligned **ancient DNA** sequences to each target genome, according to [PMDTools](https://github.com/pontussk/PMDtools).
