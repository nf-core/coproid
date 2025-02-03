/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQC                 } from '../modules/nf-core/fastqc/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { FASTP                  } from '../modules/nf-core/fastp/main'
include { SAM2LCA_ANALYZE        } from '../modules/nf-core/sam2lca/analyze/main'
include { DAMAGEPROFILER         } from '../modules/nf-core/damageprofiler/main'
include { PYDAMAGE_ANALYZE       } from '../modules/nf-core/pydamage/analyze/main'
include { SAM2LCA_MERGE          } from '../modules/local/sam2lca/merge/main' 
include { PYDAMAGE_MERGE         } from '../modules/local/pydamage/merge/main' 
include { DAMAGEPROFILER_MERGE   } from '../modules/local/damageprofiler/merge/main' 
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_coproid_pipeline' 

//
// SUBWORKFLOWS: Consisting of a mix of local and nf-core/modules
//
include { PREPARE_GENOMES           } from '../subworkflows/local/prepare_genome_indices/main'
include { SAM2LCA_DB                } from '../subworkflows/local/sam2lca_db/main'
include { ALIGN_INDEX               } from '../subworkflows/local/align_index/main'
include { MERGE_SORT_INDEX_SAMTOOLS } from '../subworkflows/local/merge_sort_index_samtools/main'
include { KRAKEN2_CLASSIFICATION    } from '../subworkflows/local/kraken2_classification/main'
include { QUARTO_REPORTING          } from '../subworkflows/local/quarto_reporting/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CREATE CHANNELS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

if (params.kraken2_db  )              { ch_kraken2_db = file(params.kraken2_db) } else { error("Kraken2 database path not specified!") }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow COPROID {

    take:
    ch_samplesheet // channel: samplesheet FASTQ read in from --input
    ch_genomesheet // channel: genomesheet genomes from --genome_sheet

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    //
    // SUBWORKFLOW: Prepare genomes from genome sheet
    //

    PREPARE_GENOMES (
        ch_genomesheet
    )
    ch_versions = ch_versions.mix(PREPARE_GENOMES.out.versions.first())

    //
    // MODULE: Run FastQC
    //
    FASTQC (
        ch_samplesheet
    )
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]})
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    //
    // MODULE: Preprocessing with fastp
    //
    FASTP (
        ch_samplesheet,
        [],
        false,
        false,
        true
    )
    ch_trimmed = FASTP.out.reads
    ch_multiqc_files = ch_multiqc_files.mix(FASTP.out.json.collect{it[1]})
    ch_versions = ch_versions.mix(FASTP.out.versions.first())

    //
    // SUBWORKFLOW: Align reads to all genomes and index alignments
    //

    FASTP.out.reads // [meta[ID, single_end], merged_reads]
        .combine(PREPARE_GENOMES.out.genomes) //[meta[genome_name], fasta, index]
        .map {
            meta_reads, reads, meta_genome, genome_fasta, genome_index ->
            [
                [
                    'id': meta_reads.id + '-' + meta_genome.genome_name,
                    'genome_name': meta_genome.genome_name,
                    'genome_taxid': meta_genome.taxid,
                    'genome_size': meta_genome.genome_size,
                    'sample_name': meta_reads.id,
                    'single_end': meta_reads.single_end,
                    'merge': meta_reads.merge
                ],
                reads,
                genome_index,
                genome_fasta
            ]
        } 
        .set { ch_reads_genomes_index }

    ALIGN_INDEX (
        ch_reads_genomes_index
    )
    ch_versions = ch_versions.mix(ALIGN_INDEX.out.versions.first())
    ch_multiqc_files = ch_multiqc_files.mix(ALIGN_INDEX.out.multiqc_files.collect{it[1]})

    DAMAGEPROFILER(
        ALIGN_INDEX.out.bam,
        [],
        [],
        []
    )
    ch_versions = ch_versions.mix(DAMAGEPROFILER.out.versions.first())
    ch_multiqc_files = ch_multiqc_files.mix(DAMAGEPROFILER.out.results.collect{it[1]})

    DAMAGEPROFILER.out.results.collect({it[1]})
    .set { damageprofiler_reports }

    DAMAGEPROFILER_MERGE(
        damageprofiler_reports
    )

    ALIGN_INDEX.out.bam.join(
        ALIGN_INDEX.out.bai
    ).map {
        meta, bam, bai -> [['id':meta.sample_name, 'genome_name':meta.genome_name], bam, bai] // meta.id, bam
    }
    .set { aligned_index }

    PYDAMAGE_ANALYZE (
        aligned_index
    )
    ch_versions = ch_versions.mix(PYDAMAGE_ANALYZE.out.versions.first())

    PYDAMAGE_ANALYZE.out.csv.collect({it[1]})
    .set { pydamage_reports }

    PYDAMAGE_MERGE (
        pydamage_reports
    )

    // join bam with indices
    ALIGN_INDEX.out.bam.join(
        ALIGN_INDEX.out.bai
    ).map {
        meta, bam, bai -> [['id':meta.sample_name], bam] // meta.id, bam
    }.groupTuple()
    .set { bams_synced }

    // SUBWORKFLOW: sort indices
    MERGE_SORT_INDEX_SAMTOOLS (
        bams_synced
    )
    ch_versions = ch_versions.mix(MERGE_SORT_INDEX_SAMTOOLS.out.versions.first())

    // Prepare SAM2LCA database channel
    if (!params.sam2lca_db ) { 
        SAM2LCA_DB(
            PREPARE_GENOMES.out.genomes.map {
                meta, fasta, index -> [meta, fasta]
                },
                "ncbi",
                [],
                [],
                []
            )
        ch_sam2lca_db = SAM2LCA_DB.out.sam2lca_db.first()
    } else {
        ch_sam2lca_db = Channel.fromPath(params.sam2lca_db).first() 
    }

    //
    // MODULE: Run sam2lca
    //
    SAM2LCA_ANALYZE (
        MERGE_SORT_INDEX_SAMTOOLS.out.bam.join(
            MERGE_SORT_INDEX_SAMTOOLS.out.bai
        ),
       ch_sam2lca_db
    )
    ch_sam2lca = SAM2LCA_ANALYZE.out.csv
    ch_versions = ch_versions.mix(SAM2LCA_ANALYZE.out.versions.first())

    SAM2LCA_ANALYZE.out.csv.collect({it[1]})
    .set { sam2lca_reports }

    SAM2LCA_MERGE (
        sam2lca_reports
    )

    //
    // SUBWORKFLOW: kraken classification and parse reports
    //
    KRAKEN2_CLASSIFICATION (
        FASTP.out.reads,
        ch_kraken2_db
    )
    ch_multiqc_files = ch_multiqc_files.mix(KRAKEN2_CLASSIFICATION.out.kraken_report.collect{it[1]})
    ch_versions = ch_versions.mix(KRAKEN2_CLASSIFICATION.out.versions.first())

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_pipeline_software_mqc_versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    // Collect all files for quarto
    ch_quarto = SAM2LCA_MERGE.out.sam2lca_merged_report.mix(
            KRAKEN2_CLASSIFICATION.out.sp_report.collectFile{it[1]},
            KRAKEN2_CLASSIFICATION.out.sp_embedding.collectFile{it[1]},
            PYDAMAGE_MERGE.out.pydamage_merged_report,
            DAMAGEPROFILER_MERGE.out.damageprofiler_merged_report,
            Channel.fromPath(params.genome_sheet),
            ch_collated_versions
        ).toList()

    //
    // SUBWORKFLOW: quarto reporting
    //
    QUARTO_REPORTING (
        ch_quarto
    )

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))

    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
