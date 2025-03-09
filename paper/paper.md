---
title: 'nf-core/coproID: XXX'
tags:
  - Nextflow
  - nf-core
  - Metagenomics
  - Palaeogenomics
authors:
  - name: Meriam van Os
    orcid:
    affiliation: "1, 2"
    corresponding: true
  - name: Christina Warinner
    orcid:
    affiliation: "2, 3, 4"
  - name: Maxime Borry
    affiliation: "2, 3"
    orcid:

affiliations:
 - name: Department of Anatomy, University of Otago, Dunedin, New Zealand
   index: 1
 - name: Microbiome Sciences Group, Department of Archaeogenetics, Max Planck Institute for Evolutionary Anthropology, Leipzig, Germany
   index: 2
 - name: Associated Research Group of Archaeogenetics, Leibniz Institute for Natural Product Research and Infection Biology Hans Knöll Institute, Jena, Germany
   index: 3
 - name: Department of Anthropology, Harvard University, Cambridge, MA, USA
   index: 4


date: X March 2025
bibliography: paper.bib

---

# Summary

XX

# Statement of need

XX


# Materials and Methods

nf-core/coproID is a bioinformatics pipeline that helps you identify the "true depositor" of Illumina
sequenced (palaeo)faeces by analysing the microbiome composition and the endogenous host DNA.

It combines the analysis of the putative host (ancient) DNA with a machine learning prediction of the faeces source,
based on microbiome taxonomic composition:

(A) First, coproID performs comparative mapping of all reads agains two (or more) target genomes (genome1, genome2, ..., genomeX)
and computes a host-DNA species ratio (NormalisedProportion).
(B) Next, coproID performs metagenomic taxonomic profiling, and compares the obtained profiles to modern reference samples
of the target species metagenomes. Using machine learning, coproID then estimates the host source from the metagenomic
taxonomic composition (SourcepredictProportion).
(C) Finally, coproID combines the A and B proportions to predict the likely host of the metagenomic sample.

## Workflow

The newest version of coproID, was entirely rewritten in the newest DSL2 language of Nextflow to enhance modularity, reusability,
and scalability. Additionally, various modifications were made to the workflow to improve accuracy and reporting.

\autoref{fig:Figure1} describes the newest workflow:


1. Quality check of the input fastq reads [andrews_fastqc_2010].
1. Fastp is used to remove adapters and low-complexity reads [Chen:2018].
1. Mapping of pre-processed reads to multiple reference genomes ([`Bowtie2`](https://bowtie-bio.sourceforge.net/bowtie2)).
1. Lowest Common Ancestor analysis with sam2lca [Borry2022] to retain only genome specific reads, i.e. reads that aligned equally well to multiple references were identify as belonging to a Lower Common Ancestor and removed from the read counts. The sam2lca read counts were normalised by the size of the genome. First, a normalisation factor was calculated per reference, or source species (sp):

$$
NormalisationFactor_{sp}  = AverageReferenceLength / ReferenceLength_{sp}
$$

The normalised read counts were then calculated by:

$$
NormalisedReads_{sp}  = sam2lcaReads_{sp} * NormalisationFactor_{sp}
$$

1. Taxonomic profiling is performed on pre-processed reads with ([`kraken2`](https://ccb.jhu.edu/software/kraken2/)), and by using a customer supplied database. Kraken2 reports are parsed and merged into one table, including all samples.
1. Sourcepredict [Borry2019Sourcepredict] is then used to predict the source proportions, based on the kraken2 taxonomic profiles, and by using customer supplied reference sources.
1. Both the host DNA (NormalisedReads) and sourcepredict proportion are used to predict by whom the (palaeo)faeces was produced. The probability of each reference species is calculated by:

$$
Probability_{sp}  = NormalisedSam2lcaProportion_{sp} * SourcepredictProportion_{sp}
$$

1. ([`MultiQC`](http://multiqc.info/)) aggregates results of several individual nf-core modules.
1. ([Quartonotebook])(https://quarto.org/) creates a report with an overview of all sample results (indcl. tables and figures). This includes the (normalised) sam2lca results and calculations, the sourcepredict results, and DNA damage patterns analysed by pyDamage and damgeprofiler.

## Output

The results are located in a nested folder architecture. Fourteen subfolders are created within the customer identified output folder:
- bowtie2
- create
- damageprofiler
- fastp
- fastqc
- kraken
- kraken2
- multiqc
- pipeline_info
- pydamage
- quartonotebook
- sam2lca
- samtools
- sourcepredict

These subfolders contain the main outputs from the concerned analyses. When the kraken2
database is supplied as a archive file (*.tar.gz), and/or the sourcepredict supplied taxa_sqlite file (ending in .xz), the additional folder
- untar
- xz
are created with the decompressed files/folders.

# Discussion and conclusions

Here we present a new version of the nf-core/coproID pipeline, designed to identify the true
depositor of (palaeo)faeces. Written in DSL2, coproID v2 is more modular, reusable,
and scalable. It includes several new features, including
fastp for faster pre-processing,
sam2lca to improve the host DNA prediction,
pyDamage to discriminate between ancient and modern DNA,
and the automated creation of a overall Quarto notebook html report.
The modular design of nf-core/coproID v2 by using Nextflow's most recent DSL2, also makes it easy
for users to customise the pipeline, for example by adding more modules and workflows.

# Figures

![Flowchart of nf-core/coproID workflow.\label{fig:Figure1}](XXX.jpg)


# Acknowledgements

XXX

# References
