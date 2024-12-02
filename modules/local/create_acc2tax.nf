process CREATE_ACC2TAX {
    tag "${meta.genome_name}"
    label 'process_single'

    conda (params.enable_conda ? "bioconda::sam2lca=1.1.4" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/sam2lca:1.1.4--pyhdfd78af_0' :
        'quay.io/biocontainers/sam2lca:1.1.4--pyhdfd78af_0'            }"

    input:
    tuple val(meta), path(fasta)

    output:
    path("*.accession2taxid"), emit: acc2tax

    script:
    def args = task.ext.args ?: ""

    """
    create_acc2tax.py $fasta -t ${meta.taxid}
    """
}
