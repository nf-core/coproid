include { KRAKEN2_KRAKEN2 } from '../../modules/nf-core/kraken2/kraken2/main'
include { KRAKEN_PARSE    } from '../../modules/local/kraken_parse'
include { KRAKEN_MERGE    } from '../../modules/local/kraken_merge'
include { SOURCEPREDICT   } from '../../modules/nf-core/sourcepredict/main'

if (params.sp_sources  )              { ch_sp_sources = file(params.sp_sources) } else { error("SourcePredict sources file not specified!") }
if (params.sp_labels   )              { ch_sp_labels  = file(params.sp_labels) } else { error("SourcePredict labels file not specified!") }
if (params.taxa_sqlite )              { ch_taxa_sqlite = file(params.taxa_sqlite) } else { error("Ete3 taxa.sqlite file not specified!") }
if (params.taxa_sqlite_traverse_pkl ) { ch_sqlite_traverse = file(params.taxa_sqlite_traverse_pkl) } else { error("Ete3 taxa.sqlite.traverse file not specified!") }

workflow KRAKEN2_CLASSIFICATION {
    take:
        reads
        kraken2_db
    main:
        ch_versions = Channel.empty()
        KRAKEN2_KRAKEN2(
            reads,
            kraken2_db,
            false,
            false
        )
        ch_versions = ch_versions.mix(KRAKEN2_KRAKEN2.out.versions.first())
        KRAKEN_PARSE(KRAKEN2_KRAKEN2.out.report)
        KRAKEN_PARSE.out.kraken_read_count.map {
            it -> it[1]
        }.collect()
        .set { kraken_read_count }

        KRAKEN_MERGE(kraken_read_count)

        // ch_versions = ch_versions.mix(KRAKEN_MERGE.out.versions.first())

    KRAKEN_MERGE.out.kraken_merged_report.dump(tag: 'kraken_parse')
        .map { 
        kraken_merged_report ->
            [
                [
                'id' : 'samples_combined'
                ],
            kraken_merged_report
            ]
        }.dump(tag: 'kraken_tuple')
        .set { ch_kraken_merged }

    //
    // MODULE: Run sourcepredict
    //
    SOURCEPREDICT (
        ch_kraken_merged,
        ch_sp_sources,
        ch_sp_labels,
        ch_taxa_sqlite,
        ch_sqlite_traverse,
        true
    )
    ch_versions = ch_versions.mix(SOURCEPREDICT.out.versions.first())

    emit:
        sp_report = SOURCEPREDICT.out.report
        sp_embedding = SOURCEPREDICT.out.embedding
        kraken_merged_report = KRAKEN_MERGE.out.kraken_merged_report
        kraken_report = KRAKEN2_KRAKEN2.out.report
        versions = ch_versions
}