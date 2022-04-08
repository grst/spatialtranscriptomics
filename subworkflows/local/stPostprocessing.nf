nextflow.enable.dsl=2

//
// Include requires tasks
//
include { ST_SPATIAL_DE } from '../../modules/local/tasks'
include { ST_CLUSTERING } from '../../modules/local/tasks'
include { ALL_REPORT    } from '../../modules/local/tasks'

//
// Run postprocessing tools
//
workflow ST_POSTPROCESSING {

    take:
    st_data_norm

    main:
    ST_SPATIAL_DE  ( st_data_norm )
    // ST_CLUSTERING  ( sample_ids,         outdir)
    // ALL_REPORT     ( ST_CLUSTERING.out,  outdir)

    emit:
    spatial_degs    = ST_SPATIAL_DE.out.degs    // channel: [ val(sample), csv ]
    spatial_figures = ST_SPATIAL_DE.out.figures // channel: [ val(sample), png ]
 }
