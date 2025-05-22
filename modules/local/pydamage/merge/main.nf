process PYDAMAGE_MERGE {
    label 'process_short'

    conda "conda-forge::pandas=1.4.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.4.3' :
        'biocontainers/pandas:1.4.3' }"

    input:
    path pydamage_reports

    output:
    path("*.csv")      , emit: pydamage_merged_report
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args   ?: ''
    prefix   = task.ext.prefix
    """
    pydamage_merge.py ${prefix}.pydamage_merged_report.csv $pydamage_reports

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    prefix   = task.ext.prefix
    """
    touch ${prefix}.pydamage_merged_report.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
