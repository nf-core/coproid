Output
======

## coproID results

 `results/{fastq_file_basename}.html`  

 This file is the report of **coproID** and contains explanations on how the calculation was performed, the files used, and your result.

 An example **coproID** output file file can be found [here](_static/simulated_coprolyte.html)

## coproID logs

You can generate a log file report of coproID run by using nextflow reporting option `-with-report`

Example:
```
nextflow run maxibor/coproid --genome1 'path/to/data/genomes/hsapiens.fa' --genome2 'path/to/data/genomes/cfamiliaris.fa' --name1 'data/genomes/Homo_sapiens' --name2 'Canis_familiaris' --reads '*_R{1,2}.fastq.gz' -with-report report.html
```

The log file will be saved in `report.html`
