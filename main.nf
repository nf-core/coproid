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
 - 1.1:   AdapterRemoval: Adapter trimming, quality filtering, and read merging
 - 1.2:   Bowtie Indexing of Genome1
 - 1.3:   Bowtie Indexing of Genome2
 - 2.1:   Reads alignment on Genome1
 - 2.2:   Reads alignment on Genome2
 - 3.1:   Count aligned reads on Genome1 and divide by normalize by Genome1 size -> Nnr1
 - 3.2:   Count aligned reads on Genome2 and divide by normalize by Genome2 size -> Nnr2
 - 4:     Compute read proportion Nnr1/Nnr2 and write Markdown report
 - 5:     Convert Markdown report to HTML

 ----------------------------------------------------------------------------------------
*/

def helpMessage() {
    log.info"""
    =========================================
     coproID: Coprolite Identification
     Homepage / Documentation: https://github.com/maxibor/coproid
     Author: Maxime Borry <borry@shh.mpg.de>
     Version ${version}
     Last updated on ${version_date}
    =========================================
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run maxibor/coproid --genome1 'genome1.fa' --genome2 'genome2.fa' --name1 'Homo_sapiens' --name2 'Canis_familiaris' --reads '*_R{1,2}.fastq.gz'
    Mandatory arguments:
      --reads                       Path to input data (must be surrounded with quotes)
      --name1                       Name of candidate 1. Example: "Homo sapiens"
      --name2                       Name of candidate 2. Example: "Canis familiaris"

    Options:
      --phred                       Specifies the fastq quality encoding (33 | 64). Defaults to ${params.phred}
      --genome1                     Path to candidate 1 Coprolite maker's genome fasta file (must be surrounded with quotes) - If index1 is not set
      --index1                      Path to Bowtie2 index genome andidate 1 Coprolite maker's genome, in the form of /path/to/*.bt2 - If genome1 is not set
      --genome1Size                 Size of candidate 1 Coprolite maker's genome in bp - If genome1 is not set
      --genome2                     Path to candidate 2 Coprolite maker's genome fasta file (must be surrounded with quotes)- If index2 is not set
      --index2                      Path to Bowtie2 index genome andidate 2 Coprolite maker's genome, in the form of /path/to/*.bt2 - If genome2 is not set
      --genome2Size                 Size of candidate 2 Coprolite maker's genome in bp - If genome2 is not set

    Other options:
      --results                     Name of result directory. Defaults to ${params.results}
      --help  --h                   Shows this help page

    """.stripIndent()
}


version = "0.2"
version_date = "September 23rd, 2018"

params.phred = 33

params.results = "./results"
params.reads = ''
params.genome1 = ''
params.genome2 = ''
params.genome1Size = ''
params.genome2Size = 0
params.index1 = ''
params.index2 = ''
params.name1 = ''
params.name2 = ''

// Show help message
params.help = false
params.h = false
if (params.help || params.h){
    helpMessage()
    exit 0
}

if( ! nextflow.version.matches(">= 0.30") ){
    throw GroovyException('Your version of Nextflow is too old, please update to Nextflow >= 0.30')
    exit 0
}

// Creating reads channel
Channel
    .fromFilePairs( params.reads, size: 2 )
    .ifEmpty { exit 1, "Cannot find any reads matching: ${params.reads}\n" }
	.set { reads_to_trim }

// Creating name channels
Channel
    .value(params.name1)
    .into {name1_index; name1_countReads; name1_countReadsIndex; name1_log}
Channel
    .value(params.name2)
    .into {name2_index; name2_countReads; name2_countReadsIndex; name2_log}


// Creating genome1 channels
if (params.genome1 != ''){
    Channel
        .fromPath(params.genome1)
        .ifEmpty {exit 1, "Cannot find any file for Genome1 matching: ${params.genome1}\n" }
        .into {genome1Fasta; genome1Size; genome1Log}
} else {
    Channel
        .fromPath(params.index1)
        .ifEmpty {exit 1, "Cannot find any index matching : ${params.index1}\n"}
        .into {bt_index_genome1; genome1Log}

    Channel
        .value(params.genome1Size)
        .set{genome1Size}
}


// Creating genome2 channels
if (params.genome2 != ''){
    Channel
        .fromPath(params.genome2)
        .ifEmpty {exit 1, "Cannot find any file for Genome2 matching: ${params.genome2}\n" }
        .into {genome2Fasta; genome2Size; genome2Log}
} else {
    Channel
        .fromPath(params.index2)
        .ifEmpty {exit 1, "Cannot find any index matching : ${params.index2}\n"}
        .into {bt_index_genome2; genome2Log}

    Channel
        .value(params.genome2Size)
        .set{genome2Size}
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
if (params.genome1 != ""){
    summary['Genome1'] = params.genome1
} else {
    summary["Genome1 BT2 index"] = params.index1
    summary["Genome 1 size (bp)"] = params.genome1Size
}
if (params.genome2 != ""){
    summary['Genome2'] = params.genome2
} else {
    summary["Genome2 BT2 index"] = params.index2
    summary["Genome 2 size (bp)"] = params.genome2Size
}
summary["Result directory"] = params.results
log.info summary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "========================================="


// 1.1:   AdapterRemoval: Adapter trimming, quality filtering, and read merging
process AdapterRemoval {
    tag "$name"

    conda 'bioconda::adapterremoval'

    label 'expresso'

    input:
        set val(name), file(reads) from reads_to_trim

    output:
        set val(name), file('*.collapsed.fastq') into trimmed_reads_genome1, trimmed_reads_genome2
        //set val(name), file("*.settings") into adapter_removal_results

    script:
        out1 = name+".pair1.discarded.fastq"
        out2 = name+".pair2.discarded.fastq"
        col_out = name+".collapsed.fastq"
        """
        AdapterRemoval --basename $name --file1 ${reads[0]} --file2 ${reads[1]} --trimns --trimqualities --collapse --output1 $out1 --output2 $out2 --outputcollapsed $col_out --threads ${task.cpus} --qualitybase ${params.phred}
        """
}

if (params.genome1 != ''){
    // 1.2:   Bowtie Indexing of Genome1
    process BowtieIndexGenome1 {
        tag "$name"

        conda 'bioconda::bowtie2'

        label 'intenso'

        when:
            params.genome1 != ""

        input:
            file(fasta) from genome1Fasta
            val(name) from name1_index
        output:
            file("*.bt2") into bt_index_genome1
        script:
            """
            bowtie2-build --threads ${task.cpus} $fasta $name
            """
    }
}

if (params.genome2 != ''){
    // 1.3:   Bowtie Indexing of Genome2
    process BowtieIndexGenome2 {
        tag "$name"

        conda 'bioconda::bowtie2'

        label 'intenso'

        when:
            params.genome2 != ""

        input:
            file(fasta) from genome2Fasta
            val(name) from name2_index
        output:
            file("*.bt2") into bt_index_genome2
        script:
            """
            bowtie2-build --threads ${task.cpus} $fasta $name
            """
    }
}


// 2.1:   Reads alignment on Genome1
process AlignToGenome1 {
    tag "$name"

    conda 'bioconda::bowtie2 bioconda::samtools'

    label 'intenso'

    errorStrategy 'ignore'

    //publishDir "${params.results}/alignment", mode: 'copy'

    input:
        set val(name), file(reads) from trimmed_reads_genome1
        file(index) from bt_index_genome1.collect()
    output:
        set val(name), file("*.sorted.bam") into alignment_genome1
    script:
        index_name = index.toString().tokenize(' ')[0].tokenize('.')[0]
        outfile = index_name+"_"+name+".sorted.bam"
        """
        bowtie2 -x $index_name -U $reads --very-fast --threads ${task.cpus} | samtools view -S -b -F 4 - | samtools sort -o $outfile
        """
}

// 2.2:   Reads alignment on Genome2
process AlignToGenome2 {
    tag "$name"

    conda 'bioconda::bowtie2 bioconda::samtools'

    label 'intenso'

    errorStrategy 'ignore'

    //publishDir "${params.results}/alignment", mode: 'copy'

    input:
        set val(name), file(reads) from trimmed_reads_genome2
        file(index) from bt_index_genome2.collect()
    output:
        set val(name), file("*.sorted.bam") into alignment_genome2
    script:
        index_name = index.toString().tokenize(' ')[0].tokenize('.')[0]
        outfile = index_name+"_"+name+".sorted.bam"
        """
        bowtie2 -x $index_name -U $reads --very-fast --threads ${task.cpus} | samtools view -S -b -F 4 - | samtools sort -o $outfile
        """
}



// 3.1a:   Count aligned reads on Genome1 and divide by normalize by Genome1 size -> Nnr1 - If no genome index provided
if (params.genome1 != ""){
    process countReads1{
        tag "$name"

        conda 'python=3.6 bioconda::pysam'

        label 'expresso'

        input:
            set val(name), file(bam) from alignment_genome1
            file(fasta) from genome1Size
            val(orgaName) from name1_countReads
        output:
            set val(name), file("*.out") into read_count_genome1
        script:
            outfile = name+"_"+orgaName+".out"
            """
            samtools index $bam
            normalizedReadCount -b $bam -g $fasta -n $orgaName -o $outfile -p ${task.cpus}
            """
    }
} else {
    process countReads1WithIndex{
        tag "$name"

        conda 'python=3.6 bioconda::pysam'

        label 'expresso'

        input:
            set val(name), file(bam) from alignment_genome1
            val(genomeSize) from genome1Size
            val(orgaName) from name1_countReadsIndex
        output:
            set val(name), file("*.out") into read_count_genome1
        script:
            outfile = name+"_"+orgaName+".out"
            """
            samtools index $bam
            normalizedReadCount -b $bam -s $genomeSize -n $orgaName -o $outfile -p ${task.cpus}
            """
    }
}


// 3.2:   Count aligned reads on Genome2 and divide by normalize by Genome2 size -> Nnr2
if (params.genome2 != ""){
    process countReads2{
        tag "$name"

        conda 'python=3.6 bioconda::pysam'

        label 'expresso'

        input:
            set val(name), file(bam) from alignment_genome2
            file(fasta) from genome2Size
            val(orgaName) from name2_countReads
        output:
            set val(name), file("*.out") into read_count_genome2
        script:
            outfile = name+"_"+orgaName+".out"
            """
            samtools index $bam
            normalizedReadCount -b $bam -g $fasta -n $orgaName -o $outfile -p ${task.cpus}
            """
    }
} else {
    process countReads2WithIndex{
        tag "$name"

        conda 'python=3.6 bioconda::pysam'

        label 'expresso'

        input:
            set val(name), file(bam) from alignment_genome2
            val(genomeSize) from genome2Size
            val(orgaName) from name2_countReadsIndex
        output:
            set val(name), file("*.out") into read_count_genome2
        script:
            outfile = name+"_"+orgaName+".out"
            """
            samtools index $bam
            normalizedReadCount -b $bam -s $genomeSize -n $orgaName -o $outfile -p ${task.cpus}
            """
    }
}


// 4:     Compute read proportion Nnr1/Nnr2 and write PDF report
process proportionAndReport {
    tag "$name1"

    conda 'python=3.6 matplotlib'

    label 'ristretto'

    input:
        set val(name1), file(readCount1) from read_count_genome1
        set val(name2), file(readCount2) from read_count_genome2
        val(orgaName1) from name1_log
        val(orgaName2) from name2_log
    output:
        set val(name1), file("*.md") into coproIDResult
        file("*.png") into plot
    script:
        outfile = name1+".coproID_result.md"
        """
        computeRatio -c1 $readCount1 -c2 $readCount2 -s $name1 -g1 $orgaName1 -g2 $orgaName2 -o $outfile
        """
}

// 5:     Convert Markdown report to HTML

process md2html {
    tag "$name"

    conda 'conda-forge::pandoc'

    label 'ristretto'

    errorStrategy 'ignore'

    publishDir "${params.results}", mode: 'copy'

    input:
        set val(name), file(report) from coproIDResult
        file(fig) from plot
    output:
        set val(name), file("*.html") into pdfReport
    script:
        outfile = name+".html"
        """
        pandoc --self-contained --webtex -s $report -o $outfile
        """
}
