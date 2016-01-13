# author: Steve Harris
# date: 2014-10-14
# subject: Consequences of occupancy on patient level effects

# Readme
# ======
# Should examine effects of occupancy at each of decision points
# - rxlimits
# - recommend
# - accept
# And then summarise 
# - subgrp proportions 
#     - for all - those no limits
#     - for no limits - those reco
#     - for reco - those accepted
#     - for accept - those early
#     - those ever accepted
# - severity (baseline and delta)
# - mortality
#     + 7d, 90d
#     - those dying without critical care

#  ==========
#  = Note!! =
#  ==========
# Repeated here for the 'recommended group'


# Todo
# ====


# Notes
#

# Log
# ===
# 2014-10-20
# - duplicated using tb_table1_accept_compare.R as the source
# 2015-08-03
# - duplicated from tb_tale1_occupancuy_effects.R
# - now focus just within those recommended
# 2015-11-12
# - redone for reco no limits grp
# - readme guidance added
# 2016-01-13
# - copied from paper-spotearly
# - adapted to run under doit not waf

#  =====================
#  = Load dependencies =
#  =====================
# Install latest version
# install.packages('data.table', type='source') (use source version to get latest)
# update.packages(type='source')
rm(list=ls(all=TRUE))

# Define file name
table1.file <- "../write/tables/table1_all.xlsx"

library(assertthat)
library(data.table)
library(reshape2)
library(XLConnect)
library(plyr)
library(gmodels)
library(Hmisc)
library(assertthat)

load("../data/paper-spotepi.RData")
wdt.original <- wdt
wdt$sample_N <- 1
wdt <- wdt[icu_recommend==1 & rxlimits==0]
dim(wdt)
assert_that(all.equal(dim(wdt),c(4976,340))==TRUE)
describe(wdt$room_cmp2)

# define subgrps
wdt[, recommend := ifelse(icu_recommend==1,1,0)]
wdt[, ward := ifelse(icu_accept==0 & rxlimits==0,1,0)]
wdt[, accept := ifelse(icu_accept,1,0)]
wdt[, via_theatre := ifelse(is.na(elgthtr) | elgthtr==0,0,1)]
with(wdt[recommend==1], CrossTable(via_theatre))


wdt$sample_N <- 1
wdt$aall <- 1

# Define file name
table.name <- 'tb_occupancy_effects_all_reco'
table.file <- paste0("write/tables", "/", table.name, ".xlsx")
table.file

# Define variables to report (tighter definitions that marry with flow)
describe(wdt$accept)
wdt[, early4.ok := ifelse(accept==1 & early4==1, 1, 0)]
describe(wdt$early4)
describe(wdt$early4.ok)
describe(wdt$icucmp)

wdt[,alive7noICU := ifelse(dead7==0 & icucmp==0,1,0)]
describe(wdt$alive7noICU)
with(wdt, CrossTable(alive7noICU, room_cmp2))
wdt[,dead7noICU := ifelse(dead7==1 & icucmp==0,1,0)]
with(wdt, CrossTable(dead7noICU, room_cmp2))

describe(wdt$ims1)
with(wdt, tapply(ims1, room_cmp2, summary))
describe(wdt$ims2)
with(wdt, tapply(ims2, room_cmp2, summary))
describe(wdt$ims_delta)
with(wdt, tapply(ims_delta, room_cmp2, summary))

# Define strata
vars.strata <-  'room_cmp2' # i.e. inspect all patients

# Define any new variables that will be needed
# --------------------------------------------

vars <- c(
    'icu_accept',
    'early4.ok',
    'icucmp',
    'time2icu',
    'ims1', 'ims_delta',
    'alive7noICU',
    'dead7noICU',
    'dead7',
    'dead90')

vars <- c('sample_N', vars) # prepend all obs for total counts

# If no strata defined then use sample_N dummy variable
if (is.na(vars.strata)) {
    vars.strata <- 'sample_N'
}

# Define the characteristics of the variables
vars.factor <- c(
    'icu_accept',
    'early4.ok',
    'icucmp',
    'alive7noICU',
    'dead7noICU',
    'dead7',
    'dead90')

# vars.norm   <- c('ims1', 'ims_delta')
vars.norm   <- c()

# Begin table preparation
# -----------------------

# NOTE: 2014-10-12 - you need to have the strata var in the data.table
if (!vars.strata %in% vars) {
    vars <- c(vars, vars.strata)
    vars.factor <- c(vars.factor, vars.strata)
}
vars.factor <- c('sample_N', vars.factor) # prepend all obs for total counts
vars.cont   <- vars[!vars %in% vars.factor]


# Now update columns to be factors if not already
vars.factor
wdt[, (vars.factor) :=lapply(.SD, as.factor), .SDcols=vars.factor]

# Remove the stratifying variable from the factor vars
vars.factor <- vars.factor[!vars.factor %in% vars.strata]

# Now produce the summaries for the continuous vars
# TODO: 2014-10-10 - add n, p.miss skew kurt, q5 q95
# NOTE: 2014-10-11 - lapply to sapply since then returns vectors not lists

t1.contvars <- function(var, strata, this_dt) {
    this_dt[,
        list(
                varname  = var,
                N        = .N,
                # NOTE: 2014-10-11 - add these later else strata means you get missing by strata not var
                miss.n   = sapply(.SD, function(x) sum(is.na(x))),
                # miss.p     = sapply(.SD, function(x) round(sum(is.na(x)) / length(x) * 100, 1)),
                mean     = sapply(.SD, function(x) mean(x, na.rm=TRUE)),
                sd       = sapply(.SD, function(x) sd(x, na.rm=TRUE)),
                min      = sapply(.SD, function(x) min(x, na.rm=TRUE)),
                q05      = sapply(.SD, function(x) quantile(x, 0.05, na.rm=TRUE)),
                q25      = sapply(.SD, function(x) quantile(x, 0.25, na.rm=TRUE)),
                q50      = sapply(.SD, function(x) quantile(x, 0.50, na.rm=TRUE)),
                q75      = sapply(.SD, function(x) quantile(x, 0.75, na.rm=TRUE)),
                q95      = sapply(.SD, function(x) quantile(x, 0.95, na.rm=TRUE)),
                max      = sapply(.SD, function(x) max(x, na.rm=TRUE))
                ),
            by=strata,
            .SDcols = var
    ]
}
# t1.contvars(c('lactate', 'bpsys'), c('room_cmp', 'sex'), wdt)
# t1.contvars('lactate', vars.strata, wdt)

# Now do this for all the continuous vars
t1.contvars.results <- t1.contvars(vars.cont, vars.strata, wdt)
t1.contvars.results


# Now total the missing by variable
t1.contvars.results[,miss.n := sum(miss.n), by=varname]
t1.contvars.results[, miss.p := lapply(.SD, function(x) round(max(miss.n)/sum(N) *100, 1)), by=varname ]

# Now convert this list of data.tables into a single data.table
t1.contvars.results$vartype <- 'continuous'
t1.contvars.results

# Categorical vars

t1.catvars <- function(var_as_string, strata_as_string, this_dt) {

    strata      <- this_dt[[strata_as_string]]
    var         <- this_dt[[var_as_string]]

    var <- with(this_dt, get(var_as_string))
    t2 <- this_dt[,.(strata.rows=.N),by=strata]

    t1 <- this_dt[, .N ,by=list(var, strata)]
    setkey(t1, strata)
    setkey(t2, strata)
    t1 <- t1[t2]

    t1[,`:=` (
        pct     = round(N/strata.rows*100, 1),
        varname = var_as_string,
        vartype = 'categorical',
        strata.rows = NULL
        )]
    setnames(t1, 'var', 'level')
    setnames(t1, 'strata', strata_as_string)
    return(t1)
}
# t1.catvars('dead28','early4', wdt)

t1.catvars.results <- lapply(vars.factor, function(var) t1.catvars(var, vars.strata, wdt))
t1.catvars.results <- do.call(rbind, t1.catvars.results)
t1.catvars.results


# TODO: 2014-10-11 - tidy up calculation of missing
t1.catvars.results[, miss.n:=NULL, ]
t1.catvars.results[, miss.n:=NA, ]
t1.catvars.results[is.na(level), miss.n := lapply(.SD, function(x) sum(N)), by=varname]
t1.catvars.results[, miss.n := ifelse(is.na(miss.n), 0, miss.n) ]
t1.catvars.results[, max(miss.n), by=varname ]
t1.catvars.results[, miss.n := lapply(.SD, function(x) max(miss.n)), by=varname ]
t1.catvars.results[, miss.p := lapply(.SD, function(x) round(max(miss.n)/sum(N) *100, 1)), by=varname ]

t1.contvars.results.orig <- t1.contvars.results
t1.contvars.results <- lapply(t1.contvars.results, function(x) if (is.list(x)) as.numeric(x) else x)
t1.contvars.results <- as.data.table(t1.contvars.results)

# Now merge these data.frames together
cols_shared <- c(c('varname', 'vartype', 'N', 'miss.n', 'miss.p'), vars.strata)
t1.results <- merge(t1.contvars.results, t1.catvars.results,
    by=cols_shared, all=TRUE)
setcolorder(t1.results, c(vars.strata, 'varname', 'level', 'N', 'pct', 'mean', 'sd', 'min', 'q05', 'q25', 'q50', 'q75', 'q95', 'max', 'miss.n', 'miss.p', 'vartype'))

# Provide the table order
t1.results[,table.order := NULL]
t1.results[, table.order := which(vars == varname), by=varname]

# Define the variables distribution
t1.results[, dist := ifelse(varname %in% vars.norm, 'normal', '')]

# setorder(t1.results, table.order, vars.strata)
cols_all_order <- c(vars.strata, c('varname', 'miss.p', 'level', 'N', 'pct', 'mean', 'sd'))
# t1.results[, .SD, .SDcols=cols_all_order]

# Drop the NA levels since these are captured in the miss.n and miss.p fields
t1.results <- t1.results[!(vartype=='categorical' & is.na(level))]
# Convert level from factor to numeric to enable sorting
t1.results[, level := as.numeric(levels(level))[level]]

# Extract variable level results
t1.results.byvarname <- t1.results[, list(
    miss.n = max(miss.n),
    miss.p = max(miss.p) )
    , by=varname ]

#  ====================
#  = Raw data to wide =
#  ====================
t1.melt <- melt(t1.results, id=c(vars.strata, c('varname', 'level')))
setnames(t1.melt, vars.strata, 'strata')

# Drop empty strata from the table
t1.wide.raw <- dcast.data.table(t1.melt, varname + level ~ strata + variable,
    subset = .(!is.na(strata)))

t1.wide.raw[, table.order := which(vars == varname), by=varname]
setorder(t1.wide.raw, table.order)
t1.wide.raw[is.na(level), level := '']

#  ==========================
#  = Formatted data to wide =
#  ==========================
# Pick your results for the final formatted table
# NOTE: 2014-10-11 - ifelse returns NA if you ask NA == 1 rather than the else clause
# str(t1.results)
t1.results.formatted <- t1.results[, list(
    strata  = get(vars.strata),
    varname = varname,
    level   = level,
    v.mid   = ifelse(vartype == 'categorical', N, ifelse(dist== 'normal', mean, q50)),
    v.left  = ifelse(vartype == 'categorical', pct, ifelse(dist == 'normal', sd, q25)),
    v.right = ifelse(vartype == 'categorical' | dist == 'normal', NA, q75),
    miss.n  = miss.n,
    miss.p  = miss.p,
    N       = N,
    vartype = vartype,
    dist    = dist
    )]
t1.results.formatted


# Now provide the formatting
t1.results.formatted <- t1.results.formatted[,
    `:=` (
    v.fmt1  = ifelse(vartype == 'categorical', sprintf("%.0f", v.mid), sprintf("%.1f", v.mid)),
    v.fmt2  = ifelse(vartype == 'categorical', paste('(', sprintf("%.1f", v.left), '%)', sep=''),
                ifelse(vartype == 'continuous' & dist == 'normal',
                    paste('(', sprintf("%.1f", v.left), ')', sep=''),
                    paste('(', sprintf("%.1f", v.left), '--', sprintf("%.1f", v.right), ')', sep='')))
        ) ]

# Now reshape to wide
t1.melt <- melt(
    t1.results.formatted[, list(strata, varname, level, v.fmt1, v.fmt2, N, miss.n, miss.p)],
    id=c('strata', 'varname', 'level'))

# Drop empty strata from the table
t1.wide.summ <- dcast.data.table(t1.melt[(variable == 'v.fmt1' | variable == 'v.fmt2')], varname + level ~ strata + variable,
    subset = .(!is.na(strata)))
t1.wide.summ[, table.order := which(vars == varname), by=varname]

t1.wide.summ[is.na(level), level := '']

setkey(t1.wide.summ, varname)
setkey(t1.results.byvarname, varname)
t1.wide.summ <- t1.wide.summ[t1.results.byvarname]
setorder(t1.wide.summ, +table.order, -level)

# Add in test for trend
# =====================
ls()
t1.wide.summ
vars.trend <- vars.factor[!vars.factor == "sample_N"]
# MWE for icu_accept
# Assumes that all variables are binary 1/0
vars.trend
v <- vars.trend[2]
describe(wdt$ward_death)
table(wdt[!is.na(get(vars.trend[5])), vars.strata, with=FALSE])
v

t1.trend <- function(v=var, strata, data=wdt, var.cont=FALSE) {
	'
	Report if there is a trend across categories (strata)
	Assumes that var is categorical (then Cochran-Armitage) unless var.cont=TRUE
	'
	if (var.cont) {
		m <- lm(get(v)~ as.numeric(get(strata)), data=data)
		return(summary(m)$coefficients[2,4])
	} else {
		t.n <- table(data[!is.na(get(v)), strata, with=FALSE])
		t.0 <- table(data[!is.na(get(v)) & get(v) == 0, vars.strata, with = FALSE])
		t.1 <- table(data[!is.na(get(v)) & get(v) == 1, vars.strata, with = FALSE])
		# lapply(list(v, t.n, t.0, t.1), function(x) print(x)) # PRINT FOR DEBUGGING
		# Check the variable is binary
		assert_that(sum(as.vector(t.0) + as.vector(t.1) - as.vector(t.n))==0)
		return(prop.trend.test(t.1,t.n)$p.value)
	}
}
# t1.trend("ims1","room_cmp", data=wdt, var.cont=TRUE)

# Format OR etc
t1.formatter <- function(tdt, col.ref, col.dp=3) {
    # TODO: 2014-12-15 - [ ] fix: should work on copy of tdt but modifies original

    require(assertthat)
    # Either need to match the vector of dp, it will need to be the same
    assert_that(length(col.ref)==length(col.dp) | length(col.dp)==1)

    i <- 1
    while (i <= length(col.ref)) {
        dp <- ifelse(length(col.dp>1), col.dp[i], col.dp)
        fmt <- paste("%.", dp, "f", sep="")
        tdt[,col.ref[i] :=
            sapply(tdt[,col.ref[i],with=FALSE], function(x) sprintf(fmt, x)),
            with=FALSE]
        i <- i+1
    }

    return(tdt)
}

# Format p-values
t1.pformatter <- function(tdt, col.ref, col.dp=4) {
    tdt.formatted <- tdt
    col <- tdt[,col.ref,with=FALSE]
    # print(col)
    col.formatted <- sapply(col, function(x) gsub("(0\\.0+)0$", "<\\11", x, perl=TRUE))
    # print(col.formatted)
    return(col.formatted)
}

trends.cat <- sapply(vars.trend, function(x) t1.trend(x, vars.strata, data=wdt))
trends.cont <- sapply(vars.cont, function(x) t1.trend(x, vars.strata, data=wdt, var.cont=TRUE))
trends <- data.table(t(rbind(
	varname=c(vars.trend, vars.cont),
	trend.p=c(trends.cat, trends.cont))))
trends[, trend.p := as.numeric(trend.p)]
trends$trend.pvalue <- t1.formatter(trends, col.ref=2, col.dp=4)
trends$trend.pvalue <- t1.pformatter(trends, col.ref=2, col.dp=4)
trends

# Now merge
t1.wide.summ
setkey(t1.wide.summ, varname, level)
trends$level <- 1 # Trick to force the join onto just one level
# need to se level to 1 for vars.cont else no join
t1.wide.summ[, level:=ifelse(is.na(level),1,level)]
trends$trend.p <- NULL
setkey(trends, varname, level)
t1.wide.summ <- trends[t1.wide.summ]
# Re-order columns
x <- names(t1.wide.summ)
setcolorder(t1.wide.summ, c(x[!x=="trend.pvalue"], "trend.pvalue"))
setorder(t1.wide.summ, +table.order, -level)
t1.wide.summ


#  =======================
#  = Now export to excel =
#  =======================
wb <- loadWorkbook(table.file, create = TRUE)

sheet1 <- paste('varsBy_', vars.strata, sep='')
removeSheet(wb, sheet1)
createSheet(wb, name = sheet1)
writeWorksheet(wb, t1.wide.summ, sheet1)

sheet2 <- paste('varsBy_', vars.strata, '_detail', sep='')
removeSheet(wb, sheet2)
createSheet(wb, name = sheet2)
writeWorksheet(wb, t1.wide.raw, sheet2)

saveWorkbook(wb)

