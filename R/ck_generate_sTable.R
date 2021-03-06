#' ck_generate_sTable
#'
#' a perturbation table (for large and small cells) for testing purposes
#'
#' @param smallC number of columns for the perturbation table for large cells
#' @param ...  additional parameters, not yet used
#'
#' @return a \code{data.table} with 256 rows and 32+\code{smallC} columns
#' @export
#'
#' @examples
#' ck_generate_sTable(smallC=10)
ck_generate_sTable <- function(smallC=12, ...) {
  nr <- 256
  nc1 <- 32
  nc2 <- smallC

  # for "large" cells
  dt1 <- as.data.table(matrix(sample(seq(0.3, 1.7, by=0.01), nr*nc1, replace=TRUE), nrow=nr, ncol=nc1))

  # for "small" cells
  dt2 <- as.data.table(matrix(sample(seq(0.7, 1.3, by=0.01), nr*nc2, replace=TRUE), nrow=nr, ncol=nc2))

  dt <- cbind(dt1, dt2)
  setnames(dt, paste0("V",1:ncol(dt)))
  dt[]
}
