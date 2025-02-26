include { BOWTIE2_BUILD } from '../../../modules/nf-core/bowtie2/build/main'

workflow PREPARE_GENOMES {
    take:
        ch_genomesheet

    main:

    ch_versions = Channel.empty()

    ch_genomesheet
        .map { create_genome_channel(it) }
        .set { genomes }

    genomes
        .branch {
            index_avail: it.size() > 2
            no_index_avail: it.size() == 2
        }
        .set { genomes_fork }

    BOWTIE2_BUILD (
        genomes_fork.no_index_avail
    )

    genomes_fork.no_index_avail.join(
        BOWTIE2_BUILD.out.index
    ).mix(
        genomes_fork.index_avail
    ).set {
        ch_genomes
    }

    ch_versions = ch_versions.mix(BOWTIE2_BUILD.out.versions.first())

    emit:
    genomes = ch_genomes
    versions = ch_versions
}

def create_genome_channel(LinkedHashMap row) {
    def meta = [:]
    meta.genome_name = row.genome_name
    meta.taxid = row.taxid
    meta.genome_size = row.genome_size
    def genome_meta = []
    if (row.igenome) {
        genome_meta = [meta, file(params.genomes[ igenome ][ fasta ]), path(params.genomes[ igenome ][ bowtie2 ])]
    } else if (row.fasta && row.index) {
        genome_meta = [meta, file(row.fasta), file(row.index)]
    } else if (row.fasta && ! row.index){
        genome_meta = [meta, file(row.fasta)]
    } else {
        exit 1, "Genome ${row.genome_name} is not available. Please provide either a iGenome or a fasta reference file"
    }

    return genome_meta
}
