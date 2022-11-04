# Output

This document describes the output produced by the coproID pipeline.
Results are found in the `results` directory (default, specified by `--outdir`).

## MultiQC report

File `multiqc_report.html`

### FastQC section

[FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) gives general quality metrics about your reads. It provides information about the quality score distribution across your reads, the per base sequence content (%T/A/G/C). You get information about adapter contamination and other overrepresented sequences.

For further reading and documentation see the [FastQC help](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/).

> **NB:** The FastQC plots displayed in the MultiQC report shows _untrimmed_ reads. They may contain adapter sequence and potentially regions with low quality.

### AdapterRemoval section

[AdapterRemoval](https://github.com/MikkelSchubert/adapterremoval) searches for and removes remnant adapter sequences from High-Throughput Sequencing (HTS) data and (optionally) trims low quality bases from the 3' end of reads following adapter removal. AdapterRemoval can analyze both single end and paired end data, and can be used to merge overlapping paired-ended reads into (longer) consensus sequences.

- _Retained and Discarded Paired-End Collapsed_: This plot shows the number/proportion of reads that passed adapter removal and trimming filters.
- _Length Distribution Paired End Collapsed_: This plot shows the length distribution of the different read categories.

### Bowtie2

[Bowtie 2](http://bowtie-bio.sourceforge.net/bowtie2/index.shtml) is an ultrafast and memory-efficient tool for aligning sequencing reads to long reference sequences.
This plot shows the number of reads aligning to the reference in different ways.

### DamageProfiler

[DamageProfiler](https://github.com/Integrative-Transcriptomics/DamageProfiler) calculates damage profiles of mapped reads.
These plots represents the damage patterns and read length distribution.

### nf-core/coproid Software Versions

This section shows the version of the different softwares used in this pipeline.

## coproID_report.html

This file contains the coproID report

### coproID summary table

This table summarizes the read ratios and microbiome source proportions as computed by coproID and sourcepredict.
You can download the table in `.csv` format by clicking on the green "Download" button.

### coproID summary plot

This plot summarizes the coproID prediction.
> **Note:** This plot is only available when coproID is used with 2 organisms

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

## alignments

This directory contains the alignment `.bam` files for aligned and aligned sequences to each target genome.

## pmdtools

This directory contains the alignment `.bam` files for aligned and aligned **ancient DNA** sequences to each target genome, according to [PMDTools](https://github.com/pontussk/PMDtools).

## pipeline_info

This directory contains all the informations about the pipeline run.

### execution_report.html

Interactive report showing resources used in the execution of the pipeline

### execution_timeline.html

Timeline of pipeline execution

### execution_trace.txt

Log of pipeline execution

### pipeline_dag.svg

Pipeline workflow overview

### pipeline_report.html

nf-core log of pipeline metadata and execution

### pipeline_report.txt

Same as above, in text format

### results_description.html

The content of this page

### software_versions.csv

List of softwares and their versions.
