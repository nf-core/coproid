Methods
=======

## Pipeline overview:
 - **0.1 - Fastqc:** Quality reporting on the `.fastq` files

 - **0.2 - Bowtie2:** Indexing of each genomes (if no index provided)

 - **1 - AdapterRemoval:** Adapter trimming, quality filtering, and read merging (if specified)

 - **2 - Bowtie2:** Reads alignment on each genome

 - **3 - PMDtools:** Filtering out reads without Post Mortem Damage (PMD).

 - **4 - countBp2/3genomes:** Count aligned bp in each read passing an identity threshold, on each genome, and compute ratio

 - **5 - damageProfiler:** DNA damage assessment

 - **6 - generateReport:** Make plots and write html report

 - **8 - MultiQC:** Generates QC report

## Read ratio computation

The following equation is used to compute the read ratio.

$$NormalizedReadRatio_{genome1} = \log2\left(\frac{\frac{N_{\ aDNA\ bp \ aligned \ genome1}}{size_{genome1} }}{\frac{N_{\ aDNA\ bp \ aligned \ genome1}}{size_{genome1} }+\frac{N_{ \ aDNA \ bp \ aligned \ genome2}}{size_{genome2}}}\right)$$


**A read is considered as an aDNA read when `PMDscore > --pmdscore`**


Because of the log2, an increase of the NormalizedReadRatio by 1 is equivalent to a two fold increase of the number of base pairs.

Note that only basepairs originating from Post Mortem Damage carrying reads (as identified by PMDtools) and aligned to a reference genome with an identity greater than the predefined threshold, are taken into account for the calculation of the NormalizedReadRatio.
