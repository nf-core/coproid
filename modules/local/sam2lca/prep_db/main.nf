process SAM2LCA_PREPDB {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/sam2lca:1.1.4--pyhdfd78af_0' :
        'quay.io/biocontainers/sam2lca:1.1.4--pyhdfd78af_0'            }"

    input:
    path(acc2tax)

    output:
    path("*.md5")      , emit: acc2tax_md5
    path("*.json")     , emit: acc2tax_json
    path("*.gz")       , emit: acc2tax_gz
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ""

    """
    gzip $acc2tax
    md5sum ${acc2tax}.gz > ${acc2tax}.gz.md5
    sam2lca_json.py ${acc2tax}.gz ${acc2tax}.gz.md5

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gzip: \$(gzip --version | head -n1 | awk '{print \$NF}')
        md5sum: \$(md5sum --version | head -n1 | awk '{print \$NF}')
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    touch acc2tax.gz
    touch acc2tax.gz.md5
    touch acc2tax.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gzip: \$(gzip --version | head -n1 | awk '{print \$NF}')
        md5sum: \$(md5sum --version | head -n1 | awk '{print \$NF}')
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
