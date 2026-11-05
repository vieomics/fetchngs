process SRA_FASTQ_ARIA2C_S3 {
    tag "${meta.id}"
    label 'process_low'
    label 'error_retry'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/aria2:1.34.0--h2021cec_3'
        : 'biocontainers/aria2:1.34.0--h2021cec_3'}"

    input:
    tuple val(meta), val(run_accession)
    val connections

    output:
    tuple val(meta), path("${run_accession}", type: 'dir'), emit: sra
    tuple val("${task.process}"), val('aria2'), eval('aria2c --version | head -n 1 | sed "s/^aria2 version //"'), emit: versions_aria2, topic: versions

    script:
    def args = task.ext.args ?: ''
    def n_connections = connections ?: 16
    """
    mkdir -p ${run_accession}
    aria2c \\
        --max-connection-per-server=${n_connections} \\
        --split=${n_connections} \\
        --min-split-size=1M \\
        --file-allocation=none \\
        --allow-overwrite=true \\
        --auto-file-renaming=false \\
        --max-tries=5 \\
        --retry-wait=5 \\
        --console-log-level=warn \\
        --summary-interval=0 \\
        ${args} \\
        --dir ${run_accession} \\
        --out ${run_accession}.sra \\
        "https://sra-pub-run-odp.s3.amazonaws.com/sra/${run_accession}/${run_accession}"
    """

    stub:
    """
    mkdir -p ${run_accession}
    touch ${run_accession}/${run_accession}.sra
    """
}
