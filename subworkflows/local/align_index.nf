include { BOWTIE2_ALIGN} from '../../modules/nf-core/bowtie2/align/main'
include { SAMTOOLS_INDEX } from '../../modules/nf-core/samtools/index/main'

workflow ALIGN_INDEX {
    take:
        reads_genomes

    main:
        ch_versions = Channel.empty()
        BOWTIE2_ALIGN(
            reads_genomes,
            false,
            true
            )
        SAMTOOLS_INDEX(BOWTIE2_ALIGN.out.bam)
        ch_versions = ch_versions.mix(BOWTIE2_ALIGN.out.versions.first())
        ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions.first())

    emit:
        bam =  BOWTIE2_ALIGN.out.bam
        bai = SAMTOOLS_INDEX.out.bai
        versions = ch_versions
}
