#' An S4 class to represent perturbation parameters for continous tables
#' @slot bigN (integer) large prime number used to derive cell keys from record keys
#' @slot smallN (integer) parameter for smallN
#' @slot pTable (data.table) perturbation table with 256 rows
#' @slot pTableSize (integer) number of columns of \code{pTable}
#' @slot mTable numeric vector specifying parameter mTable for continous perturbation
#' @slot smallC (integer) specifying parameter smallC for continous perturbation
#' the row in the lookup-table that was used to get the perturbation value
#' @slot sTable numeric vector specifying parameter sTable for continous perturbation
#' @slot topK (integer) specifiying the number of units in each cell whose values
#' will be perturbed differently
#' @name pert_params-class
#' @rdname pert_params-class
#' @export
setClass("pert_params",
representation=list(
  bigN="integer",
  smallN="integer",
  pTable="data.table",
  pTableSize="integer",
  sTable="data.table",
  mTable="numeric",
  smallC="integer",
  topK="integer"
),
prototype=list(
  bigN=integer(),
  smallN=integer(),
  pTable=data.table(),
  pTableSize=integer(),
  mTable=c(),
  smallC=integer(),
  sTable=data.table(),
  topK=integer()
),
validity=function(object) {
  stopifnot(is_scalar_integerish(object@smallC))
  stopifnot(all(object@mTable>0))

  if(!is_prime(object@bigN)) {
    stop("bigN must be a prime number!\n")
  }
  return(TRUE)
})
NULL

#' An S4-class to represent input data for applying the cell-key method
#'
#' @slot microdat data.table containing microdata
#' @slot rkeys (integer) vector specifying record keys
#' @slot pert_params pert_params information about perturbation parameters
#' @name pert_inputdat-class
#' @rdname pert_inputdat-class
#' @export
setClass("pert_inputdat",
representation=list(
  microdat="data.table",
  rkeys="integer",
  pert_params="pert_params"
),
prototype=list(
  microdat=data.table(),
  rkeys=integer(),
  pert_params=NULL
),
validity=function(object) {
  if (!is.null(object@rkeys)) {
    stopifnot(length(object@rkeys)==nrow(object@microdat))
    stopifnot(all(object@rkeys > 0))
  }
  return(TRUE)
})
NULL

#' An S4 class to represent a perturbed table
#'
#' @slot tab a \code{data.table} containing original and pertubed values. The following variables are always present:
#' \itemize{
#' \item \strong{UWC: } unweighted counts
#' \item \strong{pUWC: } perturbed unweighted counts
#' \item \strong{WC: } weighted counts
#' \item \strong{pWC: } perturbed weighted counts
#' \item \strong{WCavg: } average weight for each cell
#' }
#' Additionally, for each numerical variable the perturbed variable named {vName.pert} is included in this table.
#' @slot count_modifications a \code{data.table} with 3 columns (\code{row_indices}, \code{col_indices}
#' and \code{applied_perturbation}) that contains information for each cell, where the applied perturbation
#' was extracted from the perturbation table (useful for debugging)
#' @slot numvars_modifications (list) containing for each numerical variable
#' that was tabulated a list element with a \code{data.table} showing which
#' values have been modified prior to tabulation.
#' @slot numVars (character) variable names of numeric variables that have been tabulated
#' @slot cellKeys (integer) vector containing the cell keys
#' @slot is_weighted (logical) TRUE if sampling weights have been used
#' @name pert_table-class
#' @rdname pert_table-class
#' @export
setClass("pert_table",
representation=list(
  tab="data.table",
  count_modifications="data.table",
  numvars_modifications="list",
  cellKeys="integer",
  numVars="character",
  is_weighted="logical"
),
prototype=list(
  tab=data.table(),
  count_modifications=data.table(),
  numvars_modifications=list(),
  cellKeys=integer(),
  numVars=character(),
  is_weighted=c()),
validity=function(object) {
  return(TRUE)
})
NULL
