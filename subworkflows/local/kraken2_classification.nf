include { KRAKEN2_KRAKEN2 } from '../../modules/nf-core/kraken2/kraken2/main'
include { KRAKEN_PARSE    } from '../../modules/local/kraken_parse'
include { KRAKEN_MERGE    } from '../../modules/local/kraken_merge'

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

    emit:
        kraken_merged_report = KRAKEN_MERGE.out.kraken_merged_report
        kraken_report = KRAKEN2_KRAKEN2.out.report
        versions = ch_versions
}