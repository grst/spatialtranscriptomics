/*
================================================================================
    VALIDATE INPUTS
================================================================================
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowSpatialtranscriptomics.initialise(params, log)

// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check input path parameters to see if they exist
log.info """\
         Project directory:  ${projectDir}
         """
         .stripIndent()


def checkPathParamList = [ params.input, params.multiqc_config ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

/*
================================================================================
    CONFIG FILES
================================================================================
*/

ch_multiqc_config        = file("$projectDir/assets/multiqc_config.yaml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config) : Channel.empty()

/*
================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
================================================================================
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//

include { ST_LOAD_PREPROCESS_DATA  } from '../subworkflows/local/stLoadPreprocessData'
include { ST_MISCELLANEOUS_TOOLS   } from '../subworkflows/local/stMiscellaneousTools'
include { ST_POSTPROCESSING        } from '../subworkflows/local/stPostprocessing'

/*
================================================================================
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
================================================================================
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/modules/custom/dumpsoftwareversions/main'

/*
================================================================================
    RUN MAIN WORKFLOW
================================================================================
*/

// Info required for completion email and summary
def multiqc_report = []

// TODO: add check/schema for samplesheet
//
// Channel for input spatial transcriptomics data
//
ch_spatial_data = Channel
    .fromPath ( params.input, checkIfExists: true)
    .splitCsv ( header: true )
    .map      { row -> tuple(
                row.sample,
                row.tissue_positions_list,
                row.tissue_hires_image,
                row.scale_factors,
                row.barcodes,
                row.features,
                row.matrix
                )
    }

//
// Spatial transcriptomics workflow
//
workflow ST {

    //
    // Loading and pre-processing of ST and SC data
    //
    ST_LOAD_PREPROCESS_DATA( ch_spatial_data )

    //
    // Deconvolution with SC data (optional; do not run by default)
    //
    if (params.run_deconvolution) {
        ST_MISCELLANEOUS_TOOLS( ST_LOAD_PREPROCESS_DATA.out,  outdir )
    }

    // ST_POSTPROCESSING( ST_MISCELLANEOUS_TOOLS.out, outdir )
}

/*
================================================================================
    COMPLETION EMAIL AND SUMMARY
================================================================================
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
}

/*
================================================================================
    THE END
================================================================================
*/
