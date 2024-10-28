process KRAKEN_PARSE {
    tag "${meta.id}"
    label 'process_single'

    conda "conda-forge::pandas=1.4.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.4.3' :
        'quay.io/biocontainers/pandas:1.4.3' }"

    input:
    tuple val(meta), path(kraken2_report)

    output:
    tuple val(meta), path("*.read_kraken_parsed.csv"), emit: kraken_read_count
    tuple val(meta), path("*.kmer_kraken_parsed.csv"), emit: kraken_kmer_count

    script:
    def args = task.ext.args   ?: ''
    prefix   = task.ext.prefix ?: "${meta.id}"
    """
    kraken_parse.py $kraken2_report
    """

}
