Methods
=======

## Pipeline overview:
 - **0 - Fastqc:** Quality reporting on the `.fastq` files

 - **1.1 - AdapterRemoval:** Adapter trimming, quality filtering, and read merging (if specified)

 - **1.2 - Bowtie2:** Indexing of Genome1

 - **1.3 - Bowtie2:** Indexing of Genome2

 - **2.1 - Bowtie2:** Reads alignment on Genome1

 - **2.2 - Bowtie2:** Reads alignment on Genome2

 - **3.1 - normalizedReadCount:** Count bp aligned on Genome1 and normalise by Genome1 size -> Nnr1

 - **3.2 - normalizedReadCount:** Count bp aligned on Genome2 and normalise by Genome2 size -> Nnr2

 - **4 - ComputeRatio:** Compute read proportion Nnr1/Nnr2 and write Markdown report

 - **5 - Pandoc:** Convert Markdown report to HTML

 - **6 - MultiQC:** Generates QC report

 ## Example pipeline graph

 ![](_static/_img/dag.png)
