Methods
=======

## Pipeline overview:
 - **0 - Fastqc:** Quality reporting on the `.fastq` files

 - **1.1 - AdapterRemoval:** Adapter trimming, quality filtering, and read merging (if specified)

 - **1.2 - Bowtie2:** Indexing of Genome1

 - **1.3 - Bowtie2:** Indexing of Genome2

 - **2.1 - Bowtie2:** Reads alignment on Genome1

 - **2.2 - Bowtie2:** Reads alignment on Genome2

 - **3 - PMDtools:** Filtering out reads without Post Mortem Damage (PMD).

 - **4 - normalizedReadCount:** Count aligned bp in each read passing an identity threshold, on each genome, and compute ratio

 - **5 - MapDamage:** DNA damage assessment and aDNA identification

 - **6 - plotAndReport:** Make plots and write Markdown report

 - **7 - Pandoc:** Convert Markdown report to HTML

 - **8 - MultiQC:** Generates QC report

## Read ratio computation

The following equation is used to compute the read ratio

$$NormalizedRead_{Ratio} = \log2\left(\frac{\frac{N_{\ aDNA\ bp \ aligned \ genome1}}{size_{genome2} }}{\frac{N_{ \ aDNA \ bp \ aligned \ genome2}}{size_{genome2}}}\right)$$


**A read is considered as an aDNA read when `PMDscore > --pmdscore`**



An increase of the NormalizedReadRatio by 1 is equivalent to a two fold increase of the number of base pairs.

Note that only basepairs originating from PMD carrying reads (as identified by PMDtools) and aligned to a reference genome with an identity greater than the predefined threshold, are taken into account for the calculation of the NormalizedReadRatio.


 ## Example pipeline graph

 ![](_static/_img/dag.png)
