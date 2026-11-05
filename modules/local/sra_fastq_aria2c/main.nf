process SRA_FASTQ_ARIA2C {
    tag "${meta.id}"
    label 'process_low'
    label 'error_retry'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/aria2:1.34.0--h2021cec_3'
        : 'biocontainers/aria2:1.34.0--h2021cec_3'}"

    input:
    tuple val(meta), val(fastq)
    val connections

    output:
    tuple val(meta), path("*fastq.gz"), emit: fastq
    tuple val(meta), path("*md5"), emit: md5
    tuple val("${task.process}"), val('aria2'), eval('aria2c --version | head -n 1 | sed "s/^aria2 version //"'), emit: versions_aria2, topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: meta.id
    def n_connections = connections ?: 16
    def url_1 = fastq[0].contains('://') ? fastq[0] : "https://${fastq[0]}"
    if (meta.single_end) {
        """
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
            --dir . \\
            --out ${prefix}.fastq.gz \\
            "${url_1}"

        echo "${meta.md5_1}  ${prefix}.fastq.gz" > ${prefix}.fastq.gz.md5
        md5sum -c ${prefix}.fastq.gz.md5
        """
    }
    else {
        def url_2 = fastq[1].contains('://') ? fastq[1] : "https://${fastq[1]}"
        """
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
            --dir . \\
            --out ${prefix}_1.fastq.gz \\
            "${url_1}"

        echo "${meta.md5_1}  ${prefix}_1.fastq.gz" > ${prefix}_1.fastq.gz.md5
        md5sum -c ${prefix}_1.fastq.gz.md5

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
            --dir . \\
            --out ${prefix}_2.fastq.gz \\
            "${url_2}"

        echo "${meta.md5_2}  ${prefix}_2.fastq.gz" > ${prefix}_2.fastq.gz.md5
        md5sum -c ${prefix}_2.fastq.gz.md5
        """
    }

    stub:
    def prefix = task.ext.prefix ?: meta.id
    if (meta.single_end) {
        """
        echo | gzip > ${prefix}.fastq.gz
        touch ${prefix}.fastq.gz.md5
        """
    }
    else {
        """
        echo | gzip > ${prefix}_1.fastq.gz
        echo | gzip > ${prefix}_2.fastq.gz
        touch ${prefix}_1.fastq.gz.md5
        touch ${prefix}_2.fastq.gz.md5
        """
    }
}
