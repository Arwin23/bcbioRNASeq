#' Methods for coercing an object to a class
#'
#' Force an object to belong to a class.
#'
#' @name coerce
#' @author Michael Steinbaugh
#' @importFrom methods coerce
#' @exportMethod coerce
#' @note Updated 2020-01-20.
#'
#' @section bcbioRNASeq to DESeqDataSet:
#'
#' 1. Coerce to `RangedSummarizedExperiment`.
#' 2. Round raw counts to `integer matrix`.
#' 3. Subset [`colData()`][SummarizedExperiment::colData] to include only clean
#'    factor columns. See [`sampleData()`][basejump::sampleData] for details.
#' 4. Simplify [`metadata()`][S4Vectors::metadata] to include only relevant
#'    information and updates `sessionInfo`.
#'
#' Note that gene-level counts are required. Alternatively,
#' [`summarizeToGene()`][tximport::summarizeToGene] can be called to convert
#' transcript-level counts to gene-level. By default, we're using length-scaled
#' TPM, so a corresponding average transcript length matrix isn't necessary. The
#' average transcript length matrix is only necessary when raw counts matrix
#' isn't scaled during tximport call (see `countsFromAbundance` in
#' [`tximport()`][tximport::tximport] documentation).
#'
#' @section bcbioRNASeq to DESeqTransform:
#'
#' 1. Coerce to `DESeqDataSet`.
#' 2. Call [DESeq2::DESeq()].
#' 3. Call [DESeq2::varianceStabilizingTransformation()].
#'
#' @section bcbioRNASeq to DGEList:
#'
#' When `countsFromAbundance = "lengthScaledTPM"` (default):
#'
#' 1. Call [edgeR::DGEList()].
#'
#' When `countsFromAbundance = "no"`:
#'
#' 1. Call [edgeR::DGEList()].
#' 2. Obtain per-observation scaling factors for length, adjusted to avoid
#'    changing the magnitude of the counts.
#' 3. Computing effective library sizes from scaled counts, to account for
#'    composition biases between samples.
#' 4. Combine effective library sizes with the length factors, and calculate
#'    offsets for a log-link GLM.
#' 5. Apply offset matrix using [edgeR::scaleOffset()].
#'
#' @inheritParams acidroxygen::params
#'
#' @seealso
#' - [tximport::tximport()].
#' - [DESeq2::DESeqDataSetFromTximport()].
#' - [edgeR::DGEList()].
#'
#' @return Modified object, of desired coercion type.
#'
#' @examples
#' data(bcb)
#'
#' ## bcbioRNASeq to DESeqDataSet ====
#' x <- as(bcb, "DESeqDataSet")
#' names(S4Vectors::mcols(x))
#' class(x)
#' show(x)
#'
#' ## bcbioRNASeq to RangedSummarizedExperiment ====
#' x <- as(bcb, "RangedSummarizedExperiment")
#' slotNames(x)
#' show(x)
#'
#' ## bcbioRNASeq to SummarizedExperiment ====
#' ## Coerce to RangedSummarizedExperiment first.
#' x <- as(bcb, "RangedSummarizedExperiment")
#' x <- as(x, "SummarizedExperiment")
#' class(x)
#' slotNames(x)
#' show(x)
NULL



## Refer to Downstream DGE in Bioconductor in tximport vignette for details.
## https://bioconductor.org/packages/release/bioc/vignettes/tximport/inst/doc/
##     tximport.html#downstream_dge_in_bioconductor
##
## Note: there are two suggested ways of importing estimates for use with
## differential gene expression (DGE) methods. The first method, which we show
## below for edgeR and for DESeq2, is to use the gene-level estimated counts
## from the quantification tools, and additionally to use the transcript-level
## abundance estimates to calculate a gene-level offset that corrects for
## changes to the average transcript length across samples. The code examples
## below accomplish these steps for you, keeping track of appropriate matrices
## and calculating these offsets. For edgeR you need to assign a matrix to
## y$offset, but the function DESeqDataSetFromTximport takes care of creation of
## the offset for you. Let’s call this method "original counts and offset".
##
## The second method is to use the tximport argument
## countsFromAbundance="lengthScaledTPM" or "scaledTPM", and then to use the
## gene-level count matrix txi$counts directly as you would a regular count
## matrix with these software. Let’s call this method "bias corrected counts
## without an offset".
##
## Note: Do not manually pass the original gene-level counts to downstream
## methods without an offset. The only case where this would make sense is if
## there is no length bias to the counts, as happens in 3’ tagged RNA-seq data
## (see section below). The original gene-level counts are in txi$counts when
## tximport was run with countsFromAbundance="no". This is simply passing the
## summed estimated transcript counts, and does not correct for potential
## differential isoform usage (the offset), which is the point of the tximport
## methods (Soneson, Love, and Robinson 2015) for gene-level analysis. Passing
## uncorrected gene-level counts without an offset is not recommended by the
## tximport package authors. The two methods we provide here are: "original
## counts and offset" or "bias corrected counts without an offset". Passing txi
## to DESeqDataSetFromTximport as outlined below is correct: the function
## creates the appropriate offset for you to perform gene-level differential
## expression.



## Updated 2020-01-17.
`as.DESeqDataSet,bcbioRNASeq` <-  # nolint
    function(x, quiet = FALSE) {
        assert(isFlag(quiet))
        validObject(x)
        .assertHasValidCFA(x)
        se <- as(x, "RangedSummarizedExperiment")
        to <- `new,DESeqDataSet`(se = se, quiet = quiet)
        if (!isTRUE(quiet)) {
            cli_alert_info(paste(
                "Set the design formula with {.fun design} ",
                "and run {.fun DESeq}."
            ))
        }
        to
    }



#' @rdname coerce
#' @export
setMethod(
    f = "as.DESeqDataSet",
    signature = signature("bcbioRNASeq"),
    definition = `as.DESeqDataSet,bcbioRNASeq`
)



## Updated 2020-01-17.
`coerce,bcbioRNASeq,DESeqDataSet` <-  # nolint
    function(from) {
        as.DESeqDataSet(from, quiet = TRUE)
    }



#' @rdname coerce
#' @name coerce,bcbioRNASeq,DESeqDataSet-method
setAs(
    from = "bcbioRNASeq",
    to = "DESeqDataSet",
    def = `coerce,bcbioRNASeq,DESeqDataSet`
)



## Updated 2020-01-17.
`as.DESeqTransform,bcbioRNASeq` <-  # nolint
    function(x, quiet = FALSE) {
        assert(isFlag(quiet))
        validObject(x)
        dds <- as.DESeqDataSet(x, quiet = quiet)
        dds <- DESeq(dds, quiet = quiet)
        if (!isTRUE(quiet)) {
            cli_alert("{.fun varianceStabilizingTransformation}")
        }
        dt <- varianceStabilizingTransformation(dds)
        validObject(dt)
        dt
    }



#' @rdname coerce
#' @export
setMethod(
    f = "as.DESeqTransform",
    signature = signature("bcbioRNASeq"),
    definition = `as.DESeqTransform,bcbioRNASeq`
)



## Updated 2020-01-17.
`coerce,bcbioRNASeq,DESeqTransform` <-  # nolint
    function(from) {
        as.DESeqTransform(from, quiet = TRUE)
    }



#' @rdname coerce
#' @name coerce,bcbioRNASeq,DESeqTransform-method
setAs(
    from = "bcbioRNASeq",
    to = "DESeqTransform",
    def = `coerce,bcbioRNASeq,DESeqTransform`
)



## Updated 2020-01-12.
`as.DGEList,bcbioRNASeq` <-  # nolint
    function(x, quiet = FALSE) {
        assert(isFlag(quiet))
        validObject(x)
        .assertHasValidCFA(x)
        cfa <- metadata(x)[["countsFromAbundance"]]
        if (!isTRUE(quiet)) {
            cli_text(sprintf(
                "Generating {.var DGEList} with {.pkg edgeR} %s.",
                packageVersion("edgeR")
            ))
            cli_dl(c(countsFromAbundance = cfa))
        }
        counts <- counts(x)
        y <- DGEList(counts = counts)
        if (!isTRUE(quiet)) {
            if (identical(cfa, "no")) {
                mode <- "original counts and offset"
            } else {
                mode <- "bias corrected counts without an offset"
            }
            cli_dl(c(
                mode = paste(mode, "(see {.pkg tximport} vignette).")
            ))
        }
        if (identical(cfa, "no")) {
            ## Average transcript length (i.e. txi$length).
            normMat <- assays(x)[["avgTxLength"]]
            ## Obtain per-observation scaling factors for length, adjusted to
            ## avoid changing the magnitude of the counts.
            normMat <- normMat / exp(rowMeans(log(normMat)))
            normCounts <- counts / normMat
            ## Computing effective library sizes from scaled counts, to account
            ## for composition biases between samples.
            effLib <- calcNormFactors(normCounts) * colSums(normCounts)
            ## Combine effective library sizes with the length factors, and
            ## calculate offsets for a log-link GLM.
            normMat <- sweep(normMat, MARGIN = 2L, STATS = effLib, FUN = "*")
            normMat <- log(normMat)
            ## This will assign `y$offset` matrix. See above for details.
            y <- scaleOffset(y, offset = normMat)
            if (!isTRUE(quiet)) {
                cli_alert_info(paste(
                    "This {.var DGEList} is suitable for use only with",
                    "{.pkg edgeR}. If handing off to {.pkg limma-voom},",
                    "{.arg countsFromAbundance} must be set to",
                    "{.val lengthScaledTPM} instead."
                ))
            }
        } else {
            if (!isTRUE(quiet)) {
                cli_alert_info(paste(
                    "This {.var DGEList} is suitable for use with {.pkg edgeR}",
                    "and/or {.pkg limma-voom}."
                ))
            }
        }
        assert(identical(dimnames(x), dimnames(y)))
        validObject(y)
        if (!isTRUE(quiet)) {
            cli_alert_info(paste(
                "Subset genes with {.fun filterByExpr} ",
                "and run {.fun calcNormFactors}."
            ))
        }
        y
    }



#' @rdname coerce
#' @export
setMethod(
    f = "as.DGEList",
    signature = signature("bcbioRNASeq"),
    definition = `as.DGEList,bcbioRNASeq`
)



## Updated 2020-01-17.
`coerce,bcbioRNASeq,DGEList` <-  # nolint
    function(from) {
        as.DGEList(from)
    }



#' @rdname coerce
#' @name coerce,bcbioRNASeq,DGEList-method
setAs(
    from = "bcbioRNASeq",
    to = "DGEList",
    def = `coerce,bcbioRNASeq,DGEList`
)
