process PYDAMAGE_MERGE {
    // tag "kraken_merge"
    label 'process_single'

    conda "conda-forge::pandas=1.4.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pandas:1.4.3' :
        'quay.io/biocontainers/pandas:1.4.3' }"

    input:
    path pydamage_reports 

    output:
    path("*.csv"), emit: pydamage_merged_report

    script:
    def args = task.ext.args   ?: ''
    prefix   = task.ext.prefix
    """
    pydamage_merge.py ${prefix}.pydamage_merged_report.csv $pydamage_reports

    """

}
