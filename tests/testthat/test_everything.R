context("Testing Frequency Tables")

#bigN <- sample(primes::generate_primes(min = 2^24, max=2^25), 1)
bigN <- 17312941
pTableSize <- 70
smallN <- 12
dat <- ck_create_testdata()
dat$age <- as.integer(cut(dat$age, 6))

dim.sex <- data.table(levels=c("@","@@","@@"), codes=c("Total", 1, 2))
dim.age <- data.table(levels=c("@",rep("@@", 6)), codes=c("Total", 1:6))
dimList <- list(sex=dim.sex, age=dim.age)

maxV <- 10*nrow(dat)
dat$rec_key <- ck_generate_rkeys(dat=dat, max_val=maxV)

test_that("checking dimension and structure of generated testdata", {
  expect_equal(nrow(dat), 4580)
  expect_equal(ncol(dat), 16)
  expect_true(is.data.table(dat))
})

# perturbation input for continuous variables
mTable <- c(0.6,0.4,0.2)
smallC <- 12

pert_params <- ck_create_pert_params(
  bigN=bigN,
  smallN=smallN,
  pTable=ck_create_pTable(pTableSize=pTableSize),
  sTable=ck_generate_sTable(smallC=smallC),
  mTable=mTable)

inp <- ck_create_input(dat=dat, def_rkey="rec_key", pert_params=pert_params)
test_that("checking output of createInput() with already existing rec-keys", {
  expect_s4_class(inp, "pert_inputdat")
  expect_s4_class(inp@pert_params, "pert_params")
  expect_equal(slot(inp@pert_params, "bigN"), 17312941)
})

dat$rec_key <- NULL
inp2 <- ck_create_input(dat=dat, def_rkey=23984936, pert_params=pert_params)
test_that("checking output of createInput() with non-existing record keys", {
  expect_s4_class(inp2, "pert_inputdat")
  expect_s4_class(inp2@pert_params, "pert_params")
  expect_equal(slot(inp2@pert_params, "bigN"), 17312941)
})

# ## Frequency Tables
# # weighted
tab_freq <- perturbTable(inp, dimList=dimList, weightVar="sampling_weight", numVars=NULL)
res_weighted <- slot(tab_freq, "tab")

test_that("checking weighted version of perturbedFreqTable", {
  expect_equal(head(res_weighted$UWC,1), 4580)
  #expect_equal(tail(res_weighted$WC,1), 275590)
})

tab_freq_noweights <- perturbTable(inp=inp, dimList=dimList, weightVar=NULL, numVars=NULL)
res_unweighted <- slot(tab_freq_noweights, "tab")
test_that("checking unweighted version of perturbedFreqTable", {
  expect_equal(head(res_unweighted$UWC,1), 4580)
  expect_equal(head(res_unweighted$WC,1), 4580)
})

context("Testing Magnitude Tables")
tab_cont <- perturbTable(inp=inp, dimList=dimList, weightVar=NULL, numVars=c("savings"))

test_that("checking unweighted version of perturbedContTable", {
  expect_s4_class(tab_cont, "pert_table")
  expect_equal(nrow(tab_cont@tab), 21)
  expect_equal(ncol(tab_cont@tab), 8)
})
context("Testing consistent record-key generation")
# for the same input-dataset and the same setting of def_rkey, the
# same record keys must be generated
inp1 <- ck_create_input(dat=dat, def_rkey=1e5, pert_params=pert_params)
inp2 <- ck_create_input(dat=dat, def_rkey=1e5, pert_params=pert_params)
test_that("check that identical record keys have been generated", {
  expect_s4_class(inp1, "pert_inputdat")
  expect_s4_class(inp2, "pert_inputdat")
  expect_identical(slot(inp1, "rkeys"), slot(inp2, "rkeys"))
})
