#' perturbTable
#'
#' compute perturbed tables containing counts and continous variables.
#'
#' @param inp an object of class \code{\link{pert_inputdat-class}} generated with \code{\link{ck_create_input}}
#' @param dimList a list containing slots for each variable that should be tabulated. Each slot consists of a \code{data.frame} or \code{data.table}
#' with columns \code{levels} and \code{codes} specifiying the hierarchies of the variables.
#' @param numVars (character) vector of numerical variables that should be tabulated or \code{NULL}
#' @param weightVar (character) vector of variable holding sampling weights or \code{NULL}
#' @return an object of class \code{\link{pert_table-class}}.
#' @seealso \url{https://www.unece.org/fileadmin/DAM/stats/documents/ece/ces/ge.46/2013/Topic_1_ABS.pdf}
#' @export
#'
#' @examples
#' dat <- ck_create_testdata()
#' dat$age <- as.integer(cut(dat$age, 6))
#' maxV <- 15*nrow(dat)
#' dat$rkeys <- ck_generate_rkeys(dat=dat, max_val=maxV)
#' pert_params <- ck_create_pert_params(
#'   bigN=17312941, smallN=12,
#'   pTable=ck_create_pTable(pTableSize=70),
#'   sTable=ck_generate_sTable(smallC=12),
#'   mTable=c(0.6,0.4,0.2))
#'
## create suitable input data
#' inp <- ck_create_input(dat=dat, def_rkey="rkeys", pert_params=pert_params)
#'
#' dim.sex <- data.table(levels=c("@","@@@@","@@@@"), codes=c("Total", 1, 2))
#' dim.age <- data.table(levels=c("@",rep("@@@@", 6)), codes=c("Total", 1:6))
#' dimList <- list(sex=dim.sex, age=dim.age)
#' res <- perturbTable(inp=inp, dimList=dimList,
#'   weightVar="sampling_weight",
#'   numVars=c("savings", "income"))
#' results(res, meanBeforeSum=TRUE)
#'
#' ## information on modifications for count variables
#' mod_counts(res)
#'
#' ## information on modifications for numerical variables
#' mod_numvars(res)
perturbTable <- function(inp, dimList, numVars=NULL, weightVar=NULL) {
  . <- CKey <- N <- WCavg <- col_indices <- neg_counts <- pUWC <- pWC <-  NULL
  row_indices <- sdcStatus <- strID <- sumRec <- sumW <- tmpfreqvarfortabulation <- NULL
  tmprkeysfortabulation <- tmpweightvarfortabulation <- tmpidforsorting <- pert <- NULL

  stopifnot(isS4(inp))
  stopifnot(class(inp)=="pert_inputdat")

  pert_params <- slot(inp, "pert_params")

  dat  <- inp@microdat
  dat[,tmprkeysfortabulation:=slot(inp, "rkeys")]
  dat[,tmpidforsorting:=.I]

  dV <- match(names(dimList), names(dat))
  if (any(is.na(dV))) {
    stop("check dimList!\n")
  }

  dat[,tmpfreqvarfortabulation:=1]
  dat[,tmpweightvarfortabulation:=1]

  if (!is.null(weightVar)) {
    stopifnot(weightVar %in% names(dat))
    dat[,tmpweightvarfortabulation:=get(weightVar)]
  }

  fV <- match("tmpfreqvarfortabulation", names(dat))
  nV <- c("tmprkeysfortabulation","tmpweightvarfortabulation")
  pert_info_cont <- list()
  if (!is.null(numVars)) {
    nV2 <- match(names(numVars), names(dat))
    if (any(is.na(nV2))) {
      stop("check numVars!\n")
    }
    nV <- c(nV, numVars)
    length(pert_info_cont) <- length(numVars)
    names(pert_info_cont) <- numVars
    for (i in 1:length(numVars)) {
      v <- numVars[i]
      rr <- identify_topK_cells(dat=dat, rkeys=slot(inp, "rkeys"),
        dimList=dimList, pert_params=pert_params, v=v)
      dat[rr[,tmpidforsorting],c(v):= rr[,get(paste0(v,".mod"))]]
      setnames(rr, "tmpidforsorting", "id")
      setnames(rr, v, paste0(v,".orig"))
      pert_info_cont[[i]] <- rr
    }
  }
  nV <- match(nV, names(dat))
  prob <- makeProblem(
    data=dat, dimList=dimList, dimVarInd=dV, freqVarInd=fV, numVarInd=nV, weightInd=NULL,
    sampWeightInd=NULL)
  tab <- sdcProb2df(prob, addDups=TRUE, addNumVars=TRUE, dimCodes="original")
  tab[,strID:=NULL]
  tab[,sdcStatus:=NULL]

  # compute average weight
  setnames(tab, "tmpweightvarfortabulation", "sumW")
  setnames(tab, "freq", "N")
  setnames(tab, "tmprkeysfortabulation", "sumRec")

  tab <- tab[,WCavg:=sumW/N]
  tab[,CKey:=sumRec %% pert_params@bigN]
  # lookup
  set(tab, j="row_indices", value=sapply(tab[,CKey], get_rowIndex))
  set(tab, j="col_indices", value=sapply(tab[,N], function(z) {
    get_colIndex(z, pert_params@pTableSize, pert_params@smallN)
  }))

  df <- tab[,.(row_indices, col_indices)]

  pert_vals <- lapply(1:nrow(df), function(z) {
    pert_params@pTable[df[z, row_indices], df[z, col_indices], with=F]
  })
  ii <- which(sapply(pert_vals, function(x) nrow(x)!=1))
  if (length(ii)>0) {
    pert_vals[ii] <- NA
  }
  pert_vals <- unlist(pert_vals)

  # negative counts are not allowed
  # FIXME: should this be implemented in lookup table?
  tab[,pert:=pert_vals]
  tab[,neg_counts:=FALSE]
  tab[pert+N<0, neg_counts:=TRUE]
  if (sum(tab[,neg_counts]) >0 ) {
    warning("after perturbations we got negative counts! -> using absolute values!\n")
    tab[neg_counts==TRUE, pert:=-1*pert]
  }
  tab[,neg_counts:=NULL]

  # compute unweighted counts
  tab[,pUWC:=N+pert]
  tab[is.na(pUWC),pUWC:=0]

  # compute weighted counts
  tab[,pWC:=round(pUWC*WCavg)]
  tab[is.na(pWC), pWC:=0]

  # compute measures for each numerical variable
  if (!is.null(numVars)) {
    if (!is.null(weightVar)) {
      res <- tab[,lapply(.SD, function(x) {
        x*WCavg}), .SDcols=numVars]
      tab[,c(numVars):=res]
    }
  }

  # prepare output object
  ck <- tab[,CKey]

  t1 <- tab[,names(dimList), with=F]
  count_modifications <- data.table(
    row_indices=as.integer(tab[,row_indices]),
    col_indices=as.integer(tab[,col_indices]),
    applied_perturbation=tab[,pert])
  count_modifications <- cbind(t1, count_modifications)
  is_weighted <- ifelse(is.null(weightVar), FALSE, TRUE)


  tab <- tab[,c("CKey","row_indices","col_indices","pert", "sumRec"):=NULL]
  setnames(tab, "N", "UWC")
  setnames(tab, "sumW", "WC")

  vv <- c(names(dimList), "UWC", "pUWC", "WC", "pWC", "WCavg")
  if (length(numVars)>0) {
    for (i in 1:length(numVars)) {
      nV <- numVars[i]
      setnames(tab, nV, paste0(nV,".pert"))
      vv <- c(vv, paste0(nV, ".pert"))
    }
  } else {
    numVars <- character()
  }

  tab <- tab[,vv, with=F]
  res <- new("pert_table",
    tab=tab,
    count_modifications=count_modifications,
    numvars_modifications=pert_info_cont,
    cellKeys=as.integer(ck),
    numVars=numVars,
    is_weighted=is_weighted)
  res
}
