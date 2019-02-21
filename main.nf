#!/usr/bin/env nextflow

/*
========================================================================================
                                      CoproID
========================================================================================
 CoproID: Coprolite Identification
#### Homepage / Documentation
https://github.com/maxibor/coproid
#### Authors
 Maxime Borry <borry@shh.mpg.de>
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
Pipeline overview:
 - 0.0    Fastqc
 - 0.1    Rename reference genome fasta files
 - 1.1:   AdapterRemoval: Adapter trimming, quality filtering, and read merging
 - 1.2:   Bowtie Indexing of Genome1
 - 1.3:   Bowtie Indexing of Genome2
 - 2.1:   Reads alignment on Genome1
 - 2.2:   Reads alignment on Genome2
 - 3:     Checking for read PMD with PMDtools
 - 4:     Count aligned bp on each genome and compute ratio
 - 5:     MapDamage
 - 6:     Concatenate read ratios
 - 7:     Write Markdown report
 - 8:     Convert Markdown report to HTML
 - 9:     MultiQC

 ----------------------------------------------------------------------------------------
*/

def helpMessage() {
    log.info"""
    =========================================
     coproID: Coprolite Identification
     Homepage: https://github.com/maxibor/coproid
     Documentation: https://coproid.readthedocs.io
     Author: Maxime Borry <borry@shh.mpg.de>
     Version ${version}
     Last updated on ${version_date}
    =========================================
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run maxibor/coproid --genome1 'genome1.fa' --genome2 'genome2.fa' --name1 'Homo_sapiens' --name2 'Canis_familiaris' --reads '*_R{1,2}.fastq.gz'
    Mandatory arguments:
      --reads                       Path to input data (must be surrounded with quotes)
      --name2                       Name of candidate 2. Example: "Canis_familiaris"
      --hgenome                     Path to human genome fasta file (must be surrounded with quotes)
      --genome2                     Path to candidate 2 Coprolite maker's genome fasta file (must be surrounded with quotes)
      --krakendb                    Path to MiniKraken2_v2_8GB Database

    Options:
      --name3                       Name of candidate 1. Example: "Sus_scrofa"
      --genome3                     Path to candidate 3 Coprolite maker's genome fasta file (must be surrounded with quotes)
      --adna                        Specified if data is modern (false) or ancient DNA (true). Default = ${params.adna}
      --phred                       Specifies the fastq quality encoding (33 | 64). Defaults to ${params.phred}
      --singleEnd                   Specified if reads are single-end (true | false). Default = ${params.singleEnd}
      --hgindex                     Path to Bowtie2 index oh human genome, in the form of /path/to/*.bt2
      --index2                      Path to Bowtie2 index genome candidate 2 Coprolite maker's genome, in the form of /path/to/*.bt2
      --index3                      Path to Bowtie2 index genome candidate 3 Coprolite maker's genome, in the form of /path/to/*.bt2
      --collapse                    Specifies if AdapterRemoval should merge the paired-end sequences or not (true | false). Default = ${params.collapse}
      --identity                    Identity threshold to retain read alignment. Default = ${params.identity}
      --pmdscore                    Minimum PMDscore to retain read alignment. Default = ${params.pmdscore}
      --library                     DNA preparation library type ( classic | UDGhalf). Default = ${params.library}
      --bowtie                      Bowtie settings for sensivity (very-fast | very-sensitive). Default = ${params.bowtie}
      --minKraken                   Minimum number of Kraken hits per Taxonomy ID to report. Default = ${params.minKraken}
      --removeHuman                 Remove human reads for metagenomic taxonomic classification. Default = ${params.removeHuman}
    Other options:
      --results                     Name of result directory. Defaults to ${params.results}
      --help  --h                   Shows this help page

    """.stripIndent()
}


version = "0.6.2"
version_date = "November 23rd, 2018"

params.phred = 33

params.adna = true
params.results = "./results"
params.reads = ''
params.singleEnd = false
params.genome1 = ''
params.genome2 = ''
params.genome3 = ''
params.hgindex = ''
params.index2 = ''
params.index3 = ''
params.name1 = 'Homo_sapiens'
params.name2 = ''
params.name3 = ''
params.collapse = true
params.identity = 0.95
params.pmdscore = 3
params.library = 'classic'
params.bowtie = 'very-sensitive'
params.krakendb =''
params.minKraken = 50
params.removeHuman = false
css = baseDir+'/res/pandoc.css'

sp_sources = "$baseDir/data/sourcepredict/ modern_gut_microbiomes_sources.csv"
sp_labels = "$baseDir/data/sourcepredict/modern_gut_microbiomes_labels.csv"

bowtie_setting = ''
collapse_setting = ''
multiqc_conf = "$baseDir/conf/.multiqc_config.yaml"

// Show help message
params.help = false
params.h = false
if (params.help || params.h){
    helpMessage()
    exit 0
}

// Bowtie setting check
if (params.bowtie == 'very-fast'){
    bowtie_setting = '--very-fast'
} else if (params.bowtie == 'very-sensitive'){
    bowtie_setting = '--very-sensitive -N 1'
} else {
    println "Problem with --bowtie. Make sure to choose between 'very-fast' or 'very-sensitive'"
    exit(1)
}

//Library setting check

if ((params.library != 'classic' && params.library != 'UDGhalf' ) && (params.h == false || params.help == false) ){
    println 'ERROR: You did not specify --library'
    exit(1)
}
if (params.library == 'classic'){
    library = ''
} else {
    library = '--UDGhalf'
}

if( ! nextflow.version.matches(">= 0.30") ){
    println "Your version of Nextflow is too old, please update to Nextflow >= 0.30"
    exit(1)
}

println(params.singleEnd)
println(params.singleEnd.getClass())
// Creating reads channel
Channel
    .fromFilePairs( params.reads, size: params.singleEnd ? 1 : 2 )
    .ifEmpty { exit 1, "Cannot find any reads matching: ${params.reads}\n" }
	.into { reads_to_trim; reads_fastqc }

// Creating genome1 channels
Channel
    .fromPath(params.genome1)
    .ifEmpty {exit 1, "Cannot find any file for Genome1 matching: ${params.genome1}\n" }
    .set {genome1rename}

if(params.hgindex != '') {
    Channel
        .fromPath(params.hgindex)
        .ifEmpty {exit 1, "Cannot find any index matching : ${params.hgindex}\n"}
        .set {bt_index_genome1}
}


// Creating genome2 channels
Channel
    .fromPath(params.genome2)
    .ifEmpty {exit 1, "Cannot find any file for Genome2 matching: ${params.genome2}\n" }
    .set {genome2rename}

if (params.index2 != '') {
    Channel
        .fromPath(params.index2)
        .ifEmpty {exit 1, "Cannot find any index matching : ${params.index2}\n"}
        .set {bt_index_genome2}
}

// Creating genome3 channels
if (params.name3 != '')
Channel
    .fromPath(params.genome3)
    .ifEmpty {exit 1, "Cannot find any file for Genome2 matching: ${params.genome3}\n" }
    .set {genome3rename}

if (params.name3 != '' && params.index3 != '') {
    Channel
        .fromPath(params.index3)
        .ifEmpty {exit 1, "Cannot find any index matching : ${params.index3}\n"}
        .set {bt_index_genome3}
}



//Logging parameters
log.info "================================================================"
log.info " coproID: Coprolite Identification"
log.info " Homepage / Documentation: https://github.com/maxibor/coproid"
log.info " Author: Maxime Borry <borry@shh.mpg.de>"
log.info " Version ${version}"
log.info " Last updated on ${version_date}"
log.info "================================================================"
def summary = [:]
summary['Reads'] = params.reads
summary['phred quality'] = params.phred
summary['identity threshold'] = params.identity
summary['collapse'] = params.collapse
summary['Ancient DNA'] = params.adna
summary['singleEnd'] = params.singleEnd
summary['bowtie setting'] = params.bowtie
summary['Genome1'] = params.genome1
if (params.hgindex != '') {
    summary["Genome1 BT2 index"] = params.hgindex
}
summary['Genome2'] = params.genome2
if (params.index2 != '') {
    summary["Genome2 BT2 index"] = params.index2
}
if (params.index3 != ''){
    summary['Genome3'] = params.genome3
}
if (params.index3 != '') {
    summary["Genome3 BT3 index"] = params.index3
}
summary['Kraken DB'] = params.krakendb
summary['Min Kraken Hits to report Clade'] = params.minKraken
summary['Organism 1'] = params.name1
summary['Organism 2'] = params.name2
if (params.name3 != ''){
    summary['Organism 3'] = params.name3
}
summary['PMD Score'] = params.pmdscore
summary['Library type'] = params.library
summary["Result directory"] = params.results
log.info summary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "========================================="


// 0: FASTQC
process fastqc {
    tag "$name"

    conda 'bioconda::fastqc'

    label 'ristretto'

    input:
        set val(name), file(reads) from reads_fastqc

    output:
        file '*_fastqc.{zip,html}' into fastqc_results
    script:
        """
        fastqc -q $reads
        """
}


// 0.1    Rename reference genome fasta files
process renameGenome1 {
    label 'ristretto'

    input:
        file (genome) from genome1rename
    output:
        file (params.name1+".fa") into (genome1Fasta, genome1Size, genome1Log, genome1mapdamage)
    script:
        outname = params.name1+".fa"
        """
        mv $genome $outname
        """
}

process renameGenome2 {
    label 'ristretto'

    input:
        file (genome) from genome2rename
    output:
        file (params.name2+".fa") into (genome2Fasta, genome2Size, genome2Log, genome2mapdamage)
    script:
        outname = params.name2+".fa"
        """
        mv $genome $outname
        """
}

if (params.name3 != ''){
    process renameGenome3 {
        label 'ristretto'

        input:
            file (genome) from genome3rename
        output:
            file (params.name3+".fa") into (genome3Fasta, genome3Size, genome3Log, genome3mapdamage)
        script:
            outname = params.name3+".fa"
            """
            mv $genome $outname
            """
    }
}


// 1.1:   AdapterRemoval: Adapter trimming, quality filtering, and read merging
if (params.collapse == true && params.singleEnd == false){
    process AdapterRemovalCollapse {
        tag "$name"

        conda 'bioconda::adapterremoval'

        label 'expresso'

        input:
            set val(name), file(reads) from reads_to_trim

        output:
            set val(name), file('*.trimmed.fastq') into trimmed_reads_genome1, trimmed_reads_genome2, trimmed_reads_genome3, trimmed_reads_kraken
            file("*.settings") into adapter_removal_results

        script:
            out1 = name+".pair1.discarded.fastq"
            out2 = name+".pair2.discarded.fastq"
            col_out = name+".trimmed.fastq"
            settings = name+".settings"
            """
            AdapterRemoval --basename $name --file1 ${reads[0]} --file2 ${reads[1]} --trimns --trimqualities --collapse --minquality 20 --minlength 30 --output1 $out1 --output2 $out2 --outputcollapsed $col_out --threads ${task.cpus} --qualitybase ${params.phred} --settings $settings
            """
    }
} else if (params.collapse == false || params.singleEnd == true) {
    process AdapterRemovalNoCollapse {
        tag "$name"

        conda 'bioconda::adapterremoval'

        label 'expresso'

        input:
            set val(name), file(reads) from reads_to_trim

        output:
            set val(name), file('*.trimmed.fastq') into trimmed_reads_genome1, trimmed_reads_genome2, trimmed_reads_genome3
            file("*.settings") into adapter_removal_results

        script:
            out1 = name+".pair1.trimmed.fastq"
            out2 = name+".pair2.trimmed.fastq"
            se_out = name+".trimmed.fastq"
            settings = name+".settings"
            if (params.singleEnd == false) {
                """
                AdapterRemoval --basename $name --file1 ${reads[0]} --file2 ${reads[1]} --trimns --trimqualities --minquality 20 --minlength 30 --output1 $out1 --output2 $out2 --threads ${task.cpus} --qualitybase ${params.phred} --settings $settings
                """
            } else {
                """
                AdapterRemoval --basename $name --file1 ${reads[0]} --trimns --trimqualities --minquality 20 --minlength 30 --output1 $se_out --threads ${task.cpus} --qualitybase ${params.phred} --settings $settings
                """
            }
            
    }
} else {
    println "Problem with --collapse. If --singleEnd is set to true, you have to set --collapse to false"
    exit(1)
}

if (params.hgindex == ''){
    // 1.2:   Bowtie Indexing of Genome1
    process BowtieIndexGenome1 {
        tag "${params.name1}"

        conda 'bioconda::bowtie2'

        label 'intenso'

        input:
            file(fasta) from genome1Fasta
        output:
            file("*.bt2") into bt_index_genome1
        script:
            """
            bowtie2-build --threads ${task.cpus} $fasta ${params.name1}
            """
    }
}

// 2.1:   Reads alignment on Genome1 (Human genome)
process AlignCollapseToGenome1 {
    tag "$name"

    conda 'bioconda::bowtie2 bioconda::samtools'

    label 'intenso'

    errorStrategy 'ignore'

    input:
        set val(name), file(reads) from trimmed_reads_genome1
        file(index) from bt_index_genome1.collect()
    output:
        set val(name), file("*.aligned.sorted.bam") into alignment_genome1, filter_bam1
        set val(name), file("*.unaligned.sorted.bam") into unaligned_genome1
    script:
        index_name = index.toString().tokenize(' ')[0].tokenize('.')[0]
        outfile = name+"_"+params.name1+".aligned.sorted.bam"
        outfile_unalign = name+"_"+params.name1+".unaligned.sorted.bam"
        if (params.collapse == true || params.singleEnd == true) {
            """
            bowtie2 -x $index_name -U ${reads[0]} $bowtie_setting --threads ${task.cpus} > aligned_human.sam
            samtools view -S -b -F 4 -@ ${task.cpus} aligned_human.sam | samtools sort -@ ${task.cpus} -o $outfile
            samtools view -S -b -f 4 -@ ${task.cpus} aligned_human.sam | samtools sort -@ ${task.cpus} -o $outfile_unalign
            """
        } else if (params.collapse == false){
            """
            bowtie2 -x $index_name -1 ${reads[0]} -2 ${reads[1]} $bowtie_setting --threads ${task.cpus} > aligned_human.sam
            samtools view -S -b -F 4 -@ ${task.cpus} aligned_human.sam | samtools sort -@ ${task.cpus} -o $outfile
            samtools view -S -b -f 4 -@ ${task.cpus} aligned_human.sam | samtools sort -@ ${task.cpus} -o $outfile_unalign
            """
        }            
}

process bam2fq {
    tag "$name"

    conda 'bioconda::bedtools'

    label 'intenso'

    errorStrategy 'ignore'

    input:
        set val(name), file(bam) from unaligned_genome1
    output:
        set val(name), file("*.fastq") into unmapped_humans_reads
    script:
        if (params.pairedEnd && params.collapse == false){
            out1 = name+"_"+params.name1+".unaligned_R1.fastq"
            out2 = name+"_"+params.name1+".unaligned_R2.fastq"
            """
            bedtools bamtofastq -i $bam -fq $out1 -fq2 $out2
            """
        } else {
            out = name+"_"+params.name1+".unaligned.fastq"
            """
            bedtools bamtofastq -i $bam -fq $out
            """
        }
}   

if (params.index2 == ''){
    // 1.3:   Bowtie Indexing of Genome2
    process BowtieIndexGenome2 {
        tag "${params.name2}"

        conda 'bioconda::bowtie2'

        label 'intenso'

        input:
            file(fasta) from genome2Fasta
        output:
            file("*.bt2") into bt_index_genome2
        script:
            """
            bowtie2-build --threads ${task.cpus} $fasta ${params.name2}
            """
    }
}
if (params.name3 != '' && params.index3 == ''){
    // 1.3:   Bowtie Indexing of Genome2
    process BowtieIndexGenome3 {
        tag "${params.name2}"

        conda 'bioconda::bowtie2'

        label 'intenso'

        input:
            file(fasta) from genome3Fasta
        output:
            file("*.bt2") into bt_index_genome3
        script:
            """
            bowtie2-build --threads ${task.cpus} $fasta ${params.name3}
            """
    }
}


// 2.2:   Reads alignment on Genome2
if (params.collapse == true || params.singleEnd == true){
    process AlignCollapseToGenome2 {
        tag "$name"

        conda 'bioconda::bowtie2 bioconda::samtools'

        label 'intenso'

        // errorStrategy 'ignore'

        //publishDir "${params.results}/alignment", mode: 'copy'

        input:
            set val(name), file(reads) from trimmed_reads_genome2
            file(index) from bt_index_genome2.collect()
        output:
            set val(name), file("*.sorted.bam") into alignment_genome2, filter_bam2
        script:
            index_name = index.toString().tokenize(' ')[0].tokenize('.')[0]
            outfile = name+"_"+params.name2+".sorted.bam"
            """
            bowtie2 -x $index_name -U $reads $bowtie_setting --threads ${task.cpus} | samtools view -S -b -F 4 - | samtools sort -o $outfile
            """
    }
} else if (params.collapse == false){
    process AlignNoCollapseToGenome2 {
        tag "$name"

        conda 'bioconda::bowtie2 bioconda::samtools'

        label 'intenso'

        // errorStrategy 'ignore'

        //publishDir "${params.results}/alignment", mode: 'copy'

        input:
            set val(name), file(reads) from trimmed_reads_genome2
            file(index) from bt_index_genome2.collect()
        output:
            set val(name), file("*.sorted.bam") into alignment_genome2, filter_bam2
        script:
            index_name = index.toString().tokenize(' ')[0].tokenize('.')[0]
            outfile = name+"_"+params.name2+".sorted.bam"
            """
            bowtie2 -x $index_name -1 ${reads[0]} -2 ${reads[1]} $bowtie_setting --threads ${task.cpus} | samtools view -S -b -F 4 -@ ${task.cpus} - | samtools sort -@ ${task.cpus} -o $outfile
            """
    }
}

// 2.2:   Reads alignment on Genome3
if (params.name3 && (params.collapse == true || params.singleEnd == true)){
    process AlignCollapseToGenome3 {
        tag "$name"

        conda 'bioconda::bowtie2 bioconda::samtools'

        label 'intenso'

        errorStrategy 'ignore'

        //publishDir "${params.results}/alignment", mode: 'copy'

        input:
            set val(name), file(reads) from trimmed_reads_genome3
            file(index) from bt_index_genome3.collect()
        output:
            set val(name), file("*.sorted.bam") into alignment_genome3, filter_bam3
        script:
            index_name = index.toString().tokenize(' ')[0].tokenize('.')[0]
            outfile = name+"_"+params.name3+".sorted.bam"
            """
            bowtie2 -x $index_name -U $reads $bowtie_setting --threads ${task.cpus} | samtools view -S -b -F 4 - | samtools sort -o $outfile
            """
    }
} else if (params.name3 !='' && params.collapse == false){
    process AlignNoCollapseToGenome3 {
        tag "$name"

        conda 'bioconda::bowtie2 bioconda::samtools'

        label 'intenso'

        errorStrategy 'ignore'

        //publishDir "${params.results}/alignment", mode: 'copy'

        input:
            set val(name), file(reads) from trimmed_reads_genome3
            file(index) from bt_index_genome3.collect()
        output:
            set val(name), file("*.sorted.bam") into alignment_genome3, filter_bam3
        script:
            index_name = index.toString().tokenize(' ')[0].tokenize('.')[0]
            outfile = name+"_"+params.name3+".sorted.bam"
            """
            bowtie2 -x $index_name -1 ${reads[0]} -2 ${reads[1]} $bowtie_setting --threads ${task.cpus} | samtools view -S -b -F 4 - | samtools sort -o $outfile
            """
    }
}

// 3:     Checking for read PMD with PMDtools

if (params.adna){
    process pmdtoolsgenome1 {
    tag "$name"

    conda 'bioconda::pmdtools'

    label 'ristretto'

    input:
        set val(name), file(bam1) from alignment_genome1
    output:
        set val(name), file("*.pmd_filtered.bam") into pmd_aligned1
    script:
        outfile = name+"_"+params.name1+".pmd_filtered.bam"
        """
        samtools view -h -F 4 $bam1 | pmdtools -t ${params.pmdscore} --header $library | samtools view -Sb - > $outfile
        """
    }

    process pmdtoolsgenome2 {
        tag "$name"

        conda 'bioconda::pmdtools'

        label 'ristretto'

        input:
            set val(name), file(bam2) from alignment_genome2
        output:
            set val(name), file("*.pmd_filtered.bam") into pmd_aligned2
        script:
            outfile = name+"_"+params.name2+".pmd_filtered.bam"
            """
            samtools view -h -F 4 $bam2 | pmdtools -t ${params.pmdscore} --header $library | samtools view -Sb - > $outfile
            """
    }

    if (params.name3 != ''){
        process pmdtoolsgenome3 {
        tag "$name"

        conda 'bioconda::pmdtools'

        label 'ristretto'

        input:
            set val(name), file(bam3) from alignment_genome3
        output:
            set val(name), file("*.pmd_filtered.bam") into pmd_aligned3
        script:
            outfile = name+"_"+params.name3+".pmd_filtered.bam"
            """
            samtools view -h -F 4 $bam3 | pmdtools -t ${params.pmdscore} --header $library | samtools view -Sb - > $outfile
            """
        }
    }   
}

process kraken2 {
    tag "$name"

    conda 'bioconda::kraken2'

    label 'intenso'

    errorStrategy 'ignore'

    input:
        set val(name), file(reads) from unmapped_humans_reads

    output:
        set val(name), file('*.kraken.out') into kraken_out
        set val(name), file('*.kreport') into kraken_report

    script:
        out = name+".kraken.out"
        kreport = name+".kreport"
        if (params.pairedEnd && params.collapse == false){
            """
            kraken2 --db ${params.krakendb} --threads ${task.cpus} --output $out --report $kreport --paired ${reads[0]} ${reads[1]}
            """    
        } else {
            """
            kraken2 --db ${params.krakendb} --threads ${task.cpus} --output $out --report $kreport ${reads[0]}
            """
        }
        
}

process kraken_parse {
    tag "$name"

    conda 'python=3.6'

    label 'ristretto'

    errorStrategy 'ignore'

    input:
        set val(name), file(kraken_r) from kraken_report

    output:
        set val(name), file('*.kraken_parsed.csv') into kraken_parsed

    script:
        out = name+".kraken_parsed.csv"
        """
        kraken_parse.py -c ${params.minKraken} $kraken_r
        """    
}

process kraken_merge {

    conda 'python=3.6 pandas numpy'

    label 'ristretto'

    publishDir "${params.results}/merged", mode: 'copy'

    input:
        file(csv_count) from kraken_parsed.collect()

    output:
        file('kraken_merged_*.csv') into kraken_merged

    script:
        out = "kraken_merged.csv"
        """
        merge_kraken_res.py -o $out
        """    
}

process sourcepredict {

    conda 'maxibor::sourcepredict=0.2'

    label 'expresso'

    echo true

    input:
        set val(name), file(otu_table) from kraken_merged
    output:
        set val(name), file('*.sourcepredict.csv') into sourcepredict_out
        set val(name), file('*.umap.csv') into sourcepredict_umap_out

    script:
        outfile = name+".sourcepredict.csv"
        umap_out = name+".umap.csv"
        """
        sourcepredict -l $sp_labels -s $sp_sources -t ${task.cpus} -o $outfile -u $umap_out $otu_table 
        """
}

// 4:   Count aligned bp on each genome and compute ratio

if (params.name3 == ''){
    process countBp2genomes{
    tag "$name"

    conda 'python=3.6 bioconda::pysam'

    label 'expresso'

    input:

        set val(name), file(bam1), file(bam2) from ( params.adna ? pmd_aligned1.join(pmd_aligned2) : alignment_genome1.join(alignment_genome2))
        // set val(name), file(bam1), file(bam2) from pmd_aligned1.join(pmd_aligned2)
        file(genome1) from genome1Size.first()
        file(genome2) from genome2Size.first()
    output:
        set val(name), file("*.sp.csv") into bp_count
        set val(name), file("*"+params.name1+".filtered.bam") into filtered_bam1
        set val(name), file("*"+params.name2+".filtered.bam") into filtered_bam2
    script:
        outfile = name+".sp.csv"
        organame1 = params.name1
        organame2 = params.name2
        obam1 = name+"_"+organame1+".filtered.bam"
        obam2 = name+"_"+organame2+".filtered.bam"
        """
        samtools index $bam1
        samtools index $bam2
        normalizedReadCount -n $name -b1 $bam1 -b2 $bam2 -g1 $genome1 -g2 $genome2 -r1 $organame1 -r2 $organame2 -i ${params.identity} -o $outfile -ob1 $obam1 -ob2 $obam2 -p ${task.cpus}
        """
    }
} else {
    process countBp3genomes{
    tag "$name"

    conda 'python=3.6 bioconda::pysam'

    label 'expresso'

    echo true

    input:

        set val(name), file(bam1), file(bam2), file(bam3) from ( params.adna ? pmd_aligned1.join(pmd_aligned2).join(pmd_aligned3) : alignment_genome1.join(alignment_genome2).join(alignment_genome3))
        // set val(name), file(bam1), file(bam2) from pmd_aligned1.join(pmd_aligned2)
        file(genome1) from genome1Size.first()
        file(genome2) from genome2Size.first()
        file(genome3) from genome3Size.first()
    output:
        set val(name), file("*.sp.csv") into bp_count
        set val(name), file("*"+params.name1+".filtered.bam") into filtered_bam1
        set val(name), file("*"+params.name2+".filtered.bam") into filtered_bam2
        set val(name), file("*"+params.name3+".filtered.bam") into filtered_bam3
    script:
        outfile = name+".sp.csv"
        organame1 = params.name1
        organame2 = params.name2
        organame3 = params.name3
        obam1 = name+"_"+organame1+".filtered.bam"
        obam2 = name+"_"+organame2+".filtered.bam"
        obam3 = name+"_"+organame3+".filtered.bam"
        """
        samtools index $bam1
        samtools index $bam2
        samtools index $bam3
        normalizedReadCount -n $name -b1 $bam1 -b2 $bam2 -b3 $bam3 -g1 $genome1 -g2 $genome2 -g3 $genome3 -r1 $organame1 -r2 $organame2 -r3 $organame3 -i ${params.identity} -o $outfile -ob1 $obam1 -ob2 $obam2 -ob3 $obam3 -p ${task.cpus}
        """
    }
}


// 5:     MapDamage

if (params.adna){
    process mapdamageGenome1 {
    tag "$name"

    conda 'bioconda::mapdamage2 conda-forge::imagemagick'

    label 'ristretto'

    errorStrategy 'ignore'

    publishDir "${params.results}/mapdamage_${orgaName}", mode: 'copy'

    input:
        set val(name), file(align) from filtered_bam1
        file(fasta) from genome1mapdamage.first()
    output:
        set val(name), file("$name/*.pdf") into mapdamagePDF_result_genome1
        file("*.fragmisincorporation_plot.png") into mapdamage_result_genome1
    script:
        orgaName = params.name1
        plot_title = name+"_"+orgaName
        fname = name+"."+orgaName+".fragmisincorporation_plot.png"
        pdfloc = name+"/Fragmisincorporation_plot.pdf"
        """
        mapDamage -i $align -r $fasta -d $name -t $plot_title
        gs -sDEVICE=png16m -dTextAlphaBits=4 -r300 -o $fname $pdfloc
        """
    }

    process mapdamageGenome2 {
        tag "$name"

        conda 'bioconda::mapdamage2 conda-forge::imagemagick'

        label 'ristretto'

        errorStrategy 'ignore'

        publishDir "${params.results}/mapdamage_${orgaName}", mode: 'copy'

        input:
            set val(name), file(align) from filtered_bam2
            file(fasta) from genome2mapdamage.first()
        output:
            set val(name), file("$name/*.pdf") into mapdamagePDF_result_genome2
            file("*.fragmisincorporation_plot.png") into mapdamage_result_genome2
        script:
            orgaName = params.name2
            plot_title = name+"_"+orgaName
            fname = name+"."+orgaName+".fragmisincorporation_plot.png"
            pdfloc = name+"/Fragmisincorporation_plot.pdf"
            """
            mapDamage -i $align -r $fasta -d $name -t $plot_title
            gs -sDEVICE=png16m -dTextAlphaBits=4 -r300 -o $fname $pdfloc
            """
    }

    if (params.name3 != ""){
        process mapdamageGenome3 {
        tag "$name"

        conda 'bioconda::mapdamage2 conda-forge::imagemagick'

        label 'ristretto'

        errorStrategy 'ignore'

        publishDir "${params.results}/mapdamage_${orgaName}", mode: 'copy'

        input:
            set val(name), file(align) from filtered_bam3
            file(fasta) from genome3mapdamage.first()
        output:
            set val(name), file("$name/*.pdf") into mapdamagePDF_result_genome3
            file("*.fragmisincorporation_plot.png") into mapdamage_result_genome3
        script:
            orgaName = params.name3
            plot_title = name+"_"+orgaName
            fname = name+"."+orgaName+".fragmisincorporation_plot.png"
            pdfloc = name+"/Fragmisincorporation_plot.pdf"
            """
            mapDamage -i $align -r $fasta -d $name -t $plot_title
            gs -sDEVICE=png16m -dTextAlphaBits=4 -r300 -o $fname $pdfloc
            """
        }
    }
}


// 6: concatenate read ratios

process concatenateRatios {
    conda "python=3.6"

    label 'ristretto'

    publishDir "${params.results}", mode: 'copy', pattern: 'coproID_result.csv'

    input:
        file(count) from bp_count.collect()
        file(sp) from sourcepredict_out
    output:
        file("coproID_result.csv") into coproid_res
    script:
        outfile = "coproID_result.csv"
        """
        cat *.sp.csv > coproid_bp.csv
        merge_bp_sp.py -c coproid_bp.csv -s $sp -o $outfile
        """
}

// Make report
if (params.adna) {
    if (params.name3) {
        process generate_report {
            conda "anaconda::nbconvert bokeh::bokeh jupyter pandas matplotlib"

            label 'ristretto'

            publishDir "${params.results}", mode: 'copy', pattern: '*.html'

            input:
                file(copro_csv) from coproid_res
                file(mdplot1) from mapdamage_result_genome1.collect().ifEmpty([])
                file(mdplot1) from mapdamage_result_genome2.collect().ifEmpty([])
                file(mdplot3) from mapdamage_result_genome3.collect().ifEmpty([])
            output:
                file("*.html") into coproid_report
        }
    } else {
        process generate_report {
            conda "anaconda::nbconvert bokeh::bokeh jupyter pandas matplotlib"

            label 'ristretto'

            publishDir "${params.results}", mode: 'copy', pattern: '*.html'

            input:
                file(copro_csv) from coproid_res
                file(mdplot1) from mapdamage_result_genome1.collect().ifEmpty([])
                file(mdplot1) from mapdamage_result_genome2.collect().ifEmpty([])
                file(mdplot3) from mapdamage_result_genome3.collect().ifEmpty([])

            output:
                file("*.html") into coproid_report
        }
    }
} else {
    process generate_report {
        conda "anaconda::nbconvert bokeh::bokeh jupyter pandas"

        label 'ristretto'

        publishDir "${params.results}", mode: 'copy', pattern: '*.html'

        input:
            file(copro_csv) from coproid_res
        output:
            file("*.html") into coproid_report
    }
} 


// // 7:     Write Markdown report
// process proportionAndReport {

//     conda 'python=3.6 matplotlib pandas'

//     label 'ristretto'

//     publishDir "${params.results}", mode: 'copy', pattern: '*.csv'

//     input:
//         file(count) from coproid_count
//     output:
//         file("*.md") into coproidmd
//         file("*.png") into plot
//         file("*.csv") into csv_out
//     script:
//         outfile = "coproID_result.md"
//         csvout = "coproid_result.csv"
//         """
//         plotAndReport2 -c $count -i ${params.identity} -v $version -csv $csvout -o $outfile -adna ${params.adna}
//         """
// }

// // 8:     Convert Markdown report to HTML
// if (params.adna){
//     if (params.name3 == ""){
//         process md2html_adna_2genome {

//         conda 'conda-forge::pandoc'

//         label 'ristretto'

//         errorStrategy 'ignore'

//         publishDir "${params.results}", mode: 'copy'

//         input:
//             file(mdplot1) from mapdamage_result_genome1.collect().ifEmpty([])
//             file(mdplot1) from mapdamage_result_genome2.collect().ifEmpty([])
//             file(report) from coproidmd
//             file(fig) from plot
//         output:
//             file("*.html") into htmlReport
//         script:
//             outfile = "coproID_result.html"
//             """
//             pandoc --self-contained --css $css --webtex -s $report -o $outfile
//             """
//         }
//     }
//     else {
//         process md2html_adna_3genome {

//         conda 'conda-forge::pandoc'

//         label 'ristretto'

//         errorStrategy 'ignore'

//         publishDir "${params.results}", mode: 'copy'

//         input:
//             file(mdplot1) from mapdamage_result_genome1.collect().ifEmpty([])
//             file(mdplot1) from mapdamage_result_genome2.collect().ifEmpty([])
//             file(mdplot3) from mapdamage_result_genome3.collect().ifEmpty([])
//             file(report) from coproidmd
//             file(fig) from plot
//         output:
//             file("*.html") into htmlReport
//         script:
//             outfile = "coproID_result.html"
//             """
//             pandoc --self-contained --css $css --webtex -s $report -o $outfile
//             """
//         }
//     }
// } else {
//     process md2html_modern {

//     conda 'conda-forge::pandoc'

//     label 'ristretto'

//     errorStrategy 'ignore'

//     publishDir "${params.results}", mode: 'copy'

//     input:
//         file(report) from coproidmd
//         file(fig) from plot
//     output:
//         file("*.html") into htmlReport
//     script:
//         outfile = "coproID_result.html"
//         """
//         pandoc --self-contained --css $css --webtex -s $report -o $outfile
//         """
//     }
// }




// 9:     MultiQC
process multiqc {

    conda 'conda-forge::networkx bioconda::multiqc=1.5'

    label 'ristretto'

    errorStrategy 'ignore'

    publishDir "${params.results}", mode: 'copy'

    input:
        file (ar:'adapter_removal/*') from adapter_removal_results.collect()
        file ('fastqc/*') from fastqc_results.collect()
    output:
        file 'multiqc_report.html' into multiqc_report

    script:
        """
        multiqc -f -d adapter_removal fastqc -c $multiqc_conf
        """
}