//
// Clustering etc.
//
process ST_CLUSTERING {

    // TODO: Add a better description
    // TODO: Add proper Conda/container directive
    // TODO: Export versions

    label "process_low"

    container "cavenel/spatialtranscriptomics"

    input:
    path(report)
    tuple val(sample_id), path(st_adata_norm, stageAs: "adata_norm.h5ad")

    output:
    tuple val(sample_id), path("*/st_adata_processed.h5ad"), emit: st_adata_processed
    tuple val(sample_id), path("*/st_clustering.html")     , emit: html
    tuple val(sample_id), path("*/st_clustering_files/*")  , emit: html_files
    tuple val(sample_id), path("*/st_adata_processed_TissUUmaps.html") , emit: TissUUmaps_html
    // path("versions.yml")                                , emit: versions

    script:
    """
    quarto render "${report}" \
        --output "st_clustering.html" \
        -P fileNameST:${st_adata_norm} \
        -P resolution:${params.st_cluster_resolution} \
        -P saveFileST:st_adata_processed.h5ad \
        -P nameTissUUmapsPage:st_adata_processed_TissUUmaps.html

    mkdir "${sample_id}" -p
    mv st_adata_processed.h5ad "${sample_id}/st_adata_processed.h5ad"
    mv st_clustering.html "${sample_id}/st_clustering.html"
    mv st_clustering_files/ "${sample_id}/st_clustering_files/"
    mv st_adata_processed_TissUUmaps.html "${sample_id}/st_adata_processed_TissUUmaps.html"
    """
}
