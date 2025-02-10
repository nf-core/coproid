include { SAMTOOLS_MERGE } from  '../../modules/nf-core/samtools/merge/main'
include { SAMTOOLS_SORT  } from  '../../modules/nf-core/samtools/sort/main'
include { SAMTOOLS_INDEX } from  '../../modules/nf-core/samtools/index/main'

workflow MERGE_SORT_INDEX_SAMTOOLS {
    take:
        ch_bam // [val(meta), [bams]]
    main:

    ch_versions = Channel.empty()

    SAMTOOLS_MERGE(
        ch_bam,
        [[],[]],
        [[],[]]
    )

    SAMTOOLS_SORT ( SAMTOOLS_MERGE.out.bam,
        [[],[]]
    )
    SAMTOOLS_INDEX ( SAMTOOLS_SORT.out.bam )

    ch_versions = ch_versions.mix(SAMTOOLS_MERGE.out.versions.first())
    ch_versions = ch_versions.mix(SAMTOOLS_SORT.out.versions.first())
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions.first())

    emit:
    bam = SAMTOOLS_SORT.out.bam
    bai = SAMTOOLS_INDEX.out.bai
    versions = ch_versions
}
