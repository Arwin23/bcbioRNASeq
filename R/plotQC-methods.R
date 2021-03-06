#' @name plotQC
#' @author Michael Steinbaugh
#' @inherit acidgenerics::plotQC
#' @note Updated 2019-08-07.
#'
#' @inheritParams acidroxygen::params
#' @param ... Additional arguments.
#'
#' @examples
#' data(bcb)
#' plotQC(bcb)
NULL



#' @rdname plotQC
#' @name plotQC
#' @importFrom acidgenerics plotQC
#' @usage plotQC(object, ...)
#' @export
NULL



## Updated 2019-07-23.
`plotQC,bcbioRNASeq` <-  # nolint
    function(object) {
        validObject(object)
        plot_grid(
            plotlist = list(
                plotTotalReads(object),
                plotMappingRate(object),
                plotExonicMappingRate(object),
                plotIntronicMappingRate(object),
                plotRRNAMappingRate(object),
                plot5Prime3PrimeBias(object),
                plotFeaturesDetected(object),
                plotCountsPerFeature(object),
                plotPCA(object)
            ),
            nrow = 3L,
            ncol = 3L
        )
    }



#' @rdname plotQC
#' @export
setMethod(
    f = "plotQC",
    signature = signature("bcbioRNASeq"),
    definition = `plotQC,bcbioRNASeq`
)
