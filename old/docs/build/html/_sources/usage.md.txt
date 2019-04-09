Usage
=====



## Example usage case 1: Both reference genomes are in `fasta` format

You need to specify:
- the path the paired-end `fastq` sequencing files
- the path to the two reference genomes `fasta` files
- the names of the two reference species

Example:
```
nextflow run maxibor/coproid --genome1 'path/to/data/genomes/hsapiens.fa' --genome2 'path/to/data/genomes/cfamiliaris.fa' --name1 'data/genomes/Homo_sapiens' --name2 'Canis_familiaris' --reads '*_R{1,2}.fastq.gz'
```

## Example usage case 2: Both reference genomes are indexed by bowtie2

You need to specify:
- the path the paired-end `fastq` sequencing files
- the path to the two reference genomes `bowtie2` index files
- the names of the two reference species
- the genome size of the two reference species

Example:
```
nextflow run maxibor/coproid --index1 'path/to/data/genomes/hsapiens/Bowtie2Index/*.bt2' --index2 'path/to/data/genomes/cfamiliaris/Bowtie2Index/*.bt2' --name1 'Homo_sapiens' --name2 'Canis_familiaris' --genome1Size 3099922541 --genome2size 2327650711 --reads '*_R{1,2}.fastq.gz'
```
## Example usage case 3: One reference genome in `fasta` format, the other is indexed by bowtie2

You need to specify:
- the path the paired-end `fastq` sequencing files
- the path the reference genomes `fasta` files
- the path to other reference genomes `bowtie2` index files
- the names of the two reference species
- the genome size of the `bowtie2` indexed reference species

Example:
```
nextflow run maxibor/coproid --genome1 'path/to/data/genomes/hsapiens.fa' --index2 'data/genomes/cfamiliaris/Bowtie2Index/*.bt2' --name1 'Homo_sapiens' --name2 'Canis_familiaris' --genome2size 2327650711 --reads '*_R{1,2}.fastq.gz'
```

## To collapse or not collapse

Depending on the size of your DNA fragments, you might want to play with the `--collapse` option.
You can start by leaving it to default (`--collapse yes`), and changing it to `--collapse no` if you find that most of your reads aren't merged/collapsed by `AdapterRemoval` (Plot in `multiqc` report)

## Using coproID on a cluster

To use **coproID** on a cluster, you add the `-profile` option.

### On a SLURM based cluster

Example:
```
nextflow run maxibor/coproid --genome1 'path/to/data/genomes/hsapiens.fa' --index2 'data/genomes/cfamiliaris/Bowtie2Index/*.bt2' --name1 'Homo_sapiens' --name2 'Canis_familiaris' --genome2size 2327650711 --reads '*_R{1,2}.fastq.gz' -profile slurm
```

### On SDAG

Example:
```
nextflow run maxibor/coproid --genome1 'path/to/data/genomes/hsapiens.fa' --index2 'data/genomes/cfamiliaris/Bowtie2Index/*.bt2' --name1 'Homo_sapiens' --name2 'Canis_familiaris' --genome2size 2327650711 --reads '*_R{1,2}.fastq.gz' -profile sdag
```
