process DAMAGEPROFILER_MERGE {
    label 'process_short'

    conda "conda-forge::pandas=1.4.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.4.3' :
        'biocontainers/pandas:1.4.3' }"

    input:
    path damageprofiler_reports

    output:
    path("*.csv")      , emit: damageprofiler_merged_report
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args   ?: ''
    prefix   = task.ext.prefix
    """
    for file in *-*/*_freq.txt; do
        echo "\${file}" >> file_paths.txt
    done

    damageprofiler_merge.py ${prefix}.damageprofiler_merged_report.csv file_paths.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    prefix   = task.ext.prefix
    """
    touch ${prefix}.damageprofiler_merged_report.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
