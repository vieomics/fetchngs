include { CUSTOM_SRATOOLSNCBISETTINGS } from '../../../modules/nf-core/custom/sratoolsncbisettings/main'
include { SRA_FASTQ_ARIA2C_S3 } from '../../../modules/local/sra_fastq_aria2c_s3/main'
include { SRATOOLS_FASTERQDUMP } from '../../../modules/nf-core/sratools/fasterqdump/main'

//
// Download SRA archives from the NCBI Open Data Program and convert them to FASTQ.
//
workflow FASTQ_DOWNLOAD_ARIA2C_S3_FASTERQDUMP {
    take:
    ch_sra_ids // channel: [ val(meta), val(run_accession) ]
    ch_dbgap_key // channel: [ path(dbgap_key) ]
    connections // val: number of aria2c connections per file

    main:

    //
    // Detect existing NCBI user settings or create new ones.
    //
    CUSTOM_SRATOOLSNCBISETTINGS(ch_sra_ids.collect())
    ch_ncbi_settings = CUSTOM_SRATOOLSNCBISETTINGS.out.ncbi_settings

    //
    // Download SRA archives from the Open Data Program S3 bucket.
    //
    SRA_FASTQ_ARIA2C_S3(ch_sra_ids, connections)

    //
    // Convert the SRA format into one or more compressed FASTQ files.
    //
    SRATOOLS_FASTERQDUMP(SRA_FASTQ_ARIA2C_S3.out.sra, ch_ncbi_settings, ch_dbgap_key)

    emit:
    SRATOOLS_FASTERQDUMP.out.reads
}
