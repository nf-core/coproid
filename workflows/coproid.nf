/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQC                 } from '../modules/nf-core/fastqc/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { FASTP                  } from '../modules/nf-core/fastp/main'
include { BOWTIE2_BUILD          } from '../modules/nf-core/bowtie2/build/main'
include { BOWTIE2_ALIGN          } from '../modules/nf-core/bowtie2/align/main'
include { SAMTOOLS_INDEX         } from '../modules/nf-core/samtools/index/main'
include { SAM2LCA_ANALYZE        } from '../modules/nf-core/sam2lca/analyze/main'
include { DAMAGEPROFILER         } from '../modules/nf-core/damageprofiler/main'
include { BBMAP_BBDUK            } from '../modules/nf-core/bbmap/bbduk/main'
include { KRAKEN2_KRAKEN2        } from '../modules/nf-core/kraken2/kraken2/main'
include { KRAKEN_PARSE           } from '../modules/local/kraken_parse'
include { KRAKEN_MERGE           } from '../modules/local/kraken_merge' // needed?
include { SOURCEPREDICT          } from '../modules/nf-core/sourcepredict/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_coproid_pipeline'

//
// SUBWORKFLOWS: Consisting of a mix of local and nf-core/modules
//
include { PREPARE_GENOMES           } from '../subworkflows/local/prepare_genome_indices'
include { ALIGN_INDEX               } from '../subworkflows/local/align_index'
include { MERGE_SORT_INDEX_SAMTOOLS } from '../subworkflows/local/merge_sort_index_samtools'
include { KRAKEN2_CLASSIFICATION    } from '../subworkflows/local/kraken2_classification'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CREATE CHANNELS 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

if (params.genome_sheet)              { ch_genomes    = Channel.fromPath(params.genome_sheet) } else { error("Genomes sheet not specified!") }
if (params.sam2lca_db  )              { ch_sam2lca_db = file(params.sam2lca_db) } else { error("SAM2LCA database path not specified!") }
if (params.kraken2_db  )              { ch_kraken2_db = file(params.kraken2_db) } else { error("Kraken2 database path not specified!") }
if (params.sp_sources  )              { ch_sp_sources = file(params.sp_sources) } else { error("SourcePredict sources file not specified!") }
if (params.sp_labels   )              { ch_sp_labels  = file(params.sp_labels) } else { error("SourcePredict labels file not specified!") }
if (params.taxa_sqlite )              { ch_taxa_sqlite = file(params.taxa_sqlite) } else { error("Ete3 taxa.sqlite file not specified!") }
if (params.taxa_sqlite_traverse_pkl ) { ch_sqlite_traverse = file(params.taxa_sqlite_traverse_pkl) } else { error("Ete3 taxa.sqlite.traverse file not specified!") }

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
                    'id': meta_reads.id + '_' + meta_genome.genome_name,
                    'genome_name': meta_genome.genome_name,
                    'genome_taxid': meta_genome.taxid,
                    'genome_size': meta_genome.genome_size,
                    'sample_name': meta_reads.id,
                    'single_end': meta_reads.single_end,
                    'merge': meta_reads.merge
                ],
                reads,
                genome_index,
                fasta
            ]
        }.dump(tag: 'reads_genomes')
        .set { ch_reads_genomes_index }
    
    ALIGN_INDEX (
        ch_reads_genomes_index
    ) 
    ch_versions = ch_versions.mix(ALIGN_INDEX.out.versions.first())

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

    //
    // SUBWORKFLOW: kraken classification and parse reports
    //
    KRAKEN2_CLASSIFICATION (
        ALIGN_INDEX.out.fastq,
        ch_kraken2_db
    )

    //
    // MODULE: Run sourcepredict
    //
    SOURCEPREDICT (
        KRAKEN2_CLASSIFICATION.out.kraken_merged_report,
        ch_sp_sources,
        ch_sp_labels,
        ch_taxa_sqlite,
        ch_sqlite_traverse
    )

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
