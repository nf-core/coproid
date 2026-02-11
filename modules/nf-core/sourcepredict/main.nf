process SOURCEPREDICT {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/sourcepredict:0.5.1--pyhdfd78af_0'
        : 'biocontainers/sourcepredict:0.5.1--pyhdfd78af_0'}"

    input:
    tuple val(meta), path(kraken_parse)
    path sources
    path labels
    path taxa_sqlite, stageAs: '.etetoolkit/taxa.sqlit'
    path taxa_sqlite_traverse_pkl, stageAs: '.etetoolkit/*'
    val save_embedding

    output:
    tuple val(meta), path("*.report.sourcepredict.csv"), emit: report
    tuple val(meta), path("*.embedding.sourcepredict.csv"), optional: true, emit: embedding
    tuple val("${task.process}"), val('sourcepredict'), eval('python -c "import sourcepredict; print(sourcepredict.__version__)"'), topic: versions, emit: versions_sourcepredict
    tuple val("${task.process}"), val('python'), eval('python -V | sed "s/Python //g"'), topic: versions, emit: versions_python
    tuple val("${task.process}"), val('sklearn'), eval('python -c "import sklearn; print(sklearn.__version__)"'), topic: versions, emit: versions_sklearn

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def save_embedding_cmd = save_embedding ? "-e ${prefix}.embedding.sourcepredict.csv" : ""
    """
    export NUMBA_CACHE_DIR='./tmp'
    export HOME='./'

    sourcepredict \\
        -s ${sources} \\
        -l ${labels} \\
        ${args} \\
        ${save_embedding_cmd} \\
        -t ${task.cpus} \\
        -o ${prefix}.report.sourcepredict.csv \\
        ${kraken_parse}
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.sourcepredict.csv
    """
}
