process KRAKEN_MERGE {
    // tag "kraken_merge"
    label 'process_single'

    conda "conda-forge::pandas=1.4.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.4.3' :
        'biocontainers/pandas:1.4.3' }"

    input:
    path kraken2_reports

    output:
    path("*.csv")      , emit: kraken_merged_report
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args   ?: ''
    prefix   = task.ext.prefix
    """
    kraken_merge.py \\
        -or ${prefix}.kraken2_merged_report.csv \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
