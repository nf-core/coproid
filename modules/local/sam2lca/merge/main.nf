process SAM2LCA_MERGE {
    // tag "kraken_merge"
    label 'process_short'

    conda "conda-forge::pandas=1.4.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.4.3' :
        'biocontainers/pandas:1.4.3' }"

    input:
    path sam2lca_reports

    output:
    path("*.csv"), emit: sam2lca_merged_report
    path "versions.yml" , emit: versions

    script:
    def args = task.ext.args   ?: ''
    prefix   = task.ext.prefix
    """
    sam2lca_merge.py ${prefix}.sam2lca_merged_report.csv $sam2lca_reports

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS

    """

}
