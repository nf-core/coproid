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
      --name1                       Name of candidate 1. Example: "Homo sapiens"
      --name2                       Name of candidate 2. Example: "Canis familiaris"
      --genome1                     Path to candidate 1 Coprolite maker's genome fasta file (must be surrounded with quotes)
      --genome2                     Path to candidate 2 Coprolite maker's genome fasta file (must be surrounded with quotes)

    Options:
      --phred                       Specifies the fastq quality encoding (33 | 64). Defaults to ${params.phred}
      --index1                      Path to Bowtie2 index genome andidate 1 Coprolite maker's genome, in the form of /path/to/*.bt2 - Required if genome1 is not set
      --index2                      Path to Bowtie2 index genome andidate 2 Coprolite maker's genome, in the form of /path/to/*.bt2 - Required if genome2 is not set
      --collapse                    Specifies if AdapterRemoval should merge the paired-end sequences or not (yes | no). Default = ${params.collapse}
      --identity                    Identity threshold to retain read alignment. Default = ${params.identity}
      --pmdscore                    Minimum PMDscore to retain read alignment. Default = ${params.pmdscore}
      --library                     DNA preparation library type ( classic | UDGhalf). Default = ${params.library}
      --bowtie                      Bowtie settings for sensivity (very-fast | very-sensitive). Default = ${params.bowtie}
    Other options:
      --results                     Name of result directory. Defaults to ${params.results}
      --help  --h                   Shows this help page

    """.stripIndent()
}


version = "0.6"
version_date = "October 11th, 2018"

params.phred = 33

params.results = "./results"
params.reads = ''
params.genome1 = ''
params.genome2 = ''
params.index1 = ''
params.index2 = ''
params.name1 = ''
params.name2 = ''
params.collapse = 'yes'
params.identity = 0.95
params.pmdscore = 3
params.library = 'classic'
params.bowtie = 'very-sensitive'
css = baseDir+'/res/pandoc.css'

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
    throw GroovyException('Problem with --bowtie. Make sure to choose between "very-fast" or "very-sensitive"')
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
    throw GroovyException('Your version of Nextflow is too old, please update to Nextflow >= 0.30')
    exit 0
}

// Creating reads channel
Channel
    .fromFilePairs( params.reads, size: 2 )
    .ifEmpty { exit 1, "Cannot find any reads matching: ${params.reads}\n" }
	.into { reads_to_trim; reads_fastqc }

// Creating genome1 channels
Channel
    .fromPath(params.genome1)
    .ifEmpty {exit 1, "Cannot find any file for Genome1 matching: ${params.genome1}\n" }
    .set {genome1rename}

if(params.index1 != '') {
    Channel
        .fromPath(params.index1)
        .ifEmpty {exit 1, "Cannot find any index matching : ${params.index1}\n"}
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
summary['bowtie setting'] = params.bowtie
summary['Genome1'] = params.genome1
if (params.index1 != '') {
    summary["Genome1 BT2 index"] = params.index1
}
summary['Genome2'] = params.genome2
if (params.index2 != '') {
    summary["Genome2 BT2 index"] = params.index2
}
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


// 1.1:   AdapterRemoval: Adapter trimming, quality filtering, and read merging
if (params.collapse == 'yes'){
    process AdapterRemovalCollapse {
        tag "$name"

        conda 'bioconda::adapterremoval'

        label 'expresso'

        input:
            set val(name), file(reads) from reads_to_trim

        output:
            set val(name), file('*.collapsed.fastq') into trimmed_reads_genome1, trimmed_reads_genome2
            file("*.settings") into adapter_removal_results

        script:
            out1 = name+".pair1.discarded.fastq"
            out2 = name+".pair2.discarded.fastq"
            col_out = name+".collapsed.fastq"
            settings = name+".settings"
            """
            AdapterRemoval --basename $name --file1 ${reads[0]} --file2 ${reads[1]} --trimns --trimqualities --collapse --minquality 20 --minlength 30 --output1 $out1 --output2 $out2 --outputcollapsed $col_out --threads ${task.cpus} --qualitybase ${params.phred} --settings $settings
            """
    }
} else if (params.collapse == "no") {
    process AdapterRemovalNoCollapse {
        tag "$name"

        conda 'bioconda::adapterremoval'

        label 'expresso'

        input:
            set val(name), file(reads) from reads_to_trim

        output:
            set val(name), file('*.truncated.fastq') into trimmed_reads_genome1, trimmed_reads_genome2
            file("*.settings") into adapter_removal_results

        script:
            out1 = name+".pair1.truncated.fastq"
            out2 = name+".pair2.truncated.fastq"
            settings = name+".settings"
            """
            AdapterRemoval --basename $name --file1 ${reads[0]} --file2 ${reads[1]} --trimns --trimqualities --minquality 20 --minlength 30 --output1 $out1 --output2 $out2 --threads ${task.cpus} --qualitybase ${params.phred} --settings $settings
            """
    }
} else {
    throw GroovyException('Problem with --collapse. Make sure you choose between "yes" or "no"')
}


if (params.index1 == ''){
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


// 2.1:   Reads alignment on Genome1
if (params.collapse == "yes") {
    process AlignCollapseToGenome1 {
        tag "$name"

        conda 'bioconda::bowtie2 bioconda::samtools'

        label 'intenso'

        errorStrategy 'ignore'

        input:
            set val(name), file(reads) from trimmed_reads_genome1
            file(index) from bt_index_genome1.collect()
        output:
            set val(name), file("*.sorted.bam") into alignment_genome1, filter_bam1
        script:
            index_name = index.toString().tokenize(' ')[0].tokenize('.')[0]
            outfile = name+"_"+params.name1+".sorted.bam"
            """
            bowtie2 -x $index_name -U $reads $bowtie_setting --threads ${task.cpus} | samtools view -S -b -F 4 - | samtools sort -o $outfile
            """
    }
} else if (params.collapse == "no") {
    process AlignNoCollapseToGenome1 {
        tag "$name"

        conda 'bioconda::bowtie2 bioconda::samtools'

        label 'intenso'

        errorStrategy 'ignore'


        input:
            set val(name), file(reads) from trimmed_reads_genome1
            file(index) from bt_index_genome1.collect()
        output:
            set val(name), file("*.sorted.bam") into alignment_genome1, filter_bam1
        script:
            index_name = index.toString().tokenize(' ')[0].tokenize('.')[0]
            outfile = name+"_"+params.name1+".sorted.bam"
            """
            bowtie2 -x $index_name -1 ${reads[0]} -2 ${reads[1]} $bowtie_setting --threads ${task.cpus} | samtools view -S -b -F 4 - | samtools sort -o $outfile
            """
    }
}


// 2.2:   Reads alignment on Genome2
if (params.collapse == "yes"){
    process AlignCollapseToGenome2 {
        tag "$name"

        conda 'bioconda::bowtie2 bioconda::samtools'

        label 'intenso'

        errorStrategy 'ignore'

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
} else if (params.collapse == "no"){
    process AlignNoCollapseToGenome2 {
        tag "$name"

        conda 'bioconda::bowtie2 bioconda::samtools'

        label 'intenso'

        errorStrategy 'ignore'

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
            bowtie2 -x $index_name -1 ${reads[0]} -2 ${reads[1]} $bowtie_setting --threads ${task.cpus} | samtools view -S -b -F 4 - | samtools sort -o $outfile
            """
    }
}

// 3:     Checking for read PMD with PMDtools

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

// 4:   Count aligned bp on each genome and compute ratio

process countBp{
    tag "$name"

    conda 'python=3.6 bioconda::pysam'

    label 'expresso'

    input:
        set val(name), file(bam1), file(bam2) from pmd_aligned1.join(pmd_aligned2)
        file(genome1) from genome1Size.first()
        file(genome2) from genome2Size.first()
    output:
        set val(name), file("*.out") into bp_count
        set val(name), file("*"+params.name1+".filtered.bam") into filtered_bam1
        set val(name), file("*"+params.name2+".filtered.bam") into filtered_bam2
    script:
        outfile = name+".out"
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

// 5:     MapDamage

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

// 6: concatenate read ratios

process concatenateRatios {
    conda "python=3.6"

    label 'ristretto'

    input:
        file(count) from bp_count.collect()
    output:
        file("coproid_result.out") into coproid_count
    script:
        """
        cat *.out > coproid_result.out
        """
}

// 7:     Write Markdown report
process proportionAndReport {

    conda 'python=3.6 matplotlib'

    label 'ristretto'

    publishDir "${params.results}", mode: 'copy', pattern: '*.csv'

    input:
        file(count) from coproid_count
    output:
        file("*.md") into coproidmd
        file("*.png") into plot
        file("*.csv") into csv_out
    script:
        outfile = "coproID_result.md"
        csvout = "coproid_result.csv"
        """
        plotAndReport -c $count -i ${params.identity} -v $version -csv $csvout -o $outfile
        """
}

// 8:     Convert Markdown report to HTML

process md2html {

    conda 'conda-forge::pandoc'

    label 'ristretto'

    errorStrategy 'ignore'

    publishDir "${params.results}", mode: 'copy'

    input:
        file(mdplot1) from mapdamage_result_genome1.collect()
        file(mdplot1) from mapdamage_result_genome2.collect()
        file(report) from coproidmd
        file(fig) from plot
    output:
        file("*.html") into htmlReport
    script:
        outfile = "coproID_result.html"
        """
        pandoc --self-contained --css $css --webtex -s $report -o $outfile
        """
}



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
