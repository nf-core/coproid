process CREATE_ACC2TAX {
    tag "${meta.genome_name}"
    label 'process_short'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/sam2lca:1.1.4--pyhdfd78af_0' :
        'biocontainers/sam2lca:1.1.4--pyhdfd78af_0'            }"

    input:
    tuple val(meta), path(fasta)

    output:
    path("*.accession2taxid"), emit: acc2tax
    path "versions.yml"      , emit: versions

    script:
    def args = task.ext.args ?: ""

    """
    create_acc2tax.py $fasta -t ${meta.taxid}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.taxid}.accession2taxid

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
