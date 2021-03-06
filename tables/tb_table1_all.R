# author: Steve Harris
# date: 2014-10-09
# subject: Produce Table 1 given a dataframe and a list of variables

# Readme
# ======


# Todo
# ====

# *- [X] TODO: add by strata functionality
# *- [X] TODO: calculate percentages for categories
# *- [X] TODO: add total missing by category
# *- [X] TODO: total missing over strata for continuous
# *- [X] TODO: reshape strata if they exist to wide
# *- [X] TODO: needs to export

# Notes
# http://asymptoticallyunbiased.blogspot.co.uk/2013/04/r-table-1-done-in-one.html
#

# Log
# ===
# 2014-10-09
# - file created
# 2014-10-10
# - works, produces a single data table with all the vars
# 2014-10-11
# - switch to using development version of data.table
# 2014-10-11
# - seems to be working
# - handles strata
# - exports complete and formatted data to excel
# 2014-10-12
# - rewrite of t1.catvars function which was completely wrong!
# - fixed table ordering
# 2015-11-11
# - cloned from labbook_table1.R and adapted to just produce overall summary 
# - variables selected and defined
# 2015-11-27
# - cloned from spotearly


#  =====================
#  = Load dependencies =
#  =====================
# Install latest version
# install.packages('data.table', type='source') (use source version to get latest)
# update.packages(type='source')
library(data.table)
library(reshape2)
library(XLConnect)
library(Hmisc)

rm(list=ls(all=TRUE))

# Load the necessary data
# -----------------------
load("../data/paper-spotepi.RData")
wdt.original <- wdt
wdt$sample_N <- 1
dim(wdt)

# Define file name
table1.file <- "../write/tables/table1_all.xlsx"

# Define strata
# NOTE: 2014-10-11 - just work with 2 way comparison for now
# icu_accept == 0 vs icu_accept == 1 vs early4 == 1 will need a different approach
# NOTE: 2015-11-11 - [ ] checking this works with single strata
# vars.strata <-  'room_cmp'
vars.strata <-  NA

# Define the vars
source("../share/derive.R")
describe(wdt$sofa_score)
wdt[, sofa2.r := gen.sofa.r(pf, fio2_std)]
wdt[, odys := ifelse(
    (sofa_score>1 & sofa_r <= 1) |
    (!is.na(sofa2.r) & sofa2.r > 1),1,0)]
wdt[, osupp := ifelse( rxrrt==1 | rx_resp==2 | rxcvs == 2,1,0)]
describe(wdt$osupp)

wdt[, `:=`(
	odys.r = ifelse(sofa2.r > 1,1,0),
	odys.k = ifelse(sofa_k > 1,1,0),
	odys.h = ifelse(sofa_h > 1,1,0),
	odys.p = ifelse(sofa_p > 1,1,0),
	odys.n = ifelse(sofa_n > 1,1,0),
	odys.c = ifelse(sofa_c > 1,1,0)
	)]

wdt[, recommend := ifelse(icu_recommend==1 & rxlimits==0,1,0)]
wdt[, accept := ifelse(icu_recommend==1 & rxlimits==0 & icu_accept,1,0)]
describe(wdt$recommend)
describe(wdt$accept)

describe(wdt$odys.r)
vars <- c('age', 'sex', 'sepsis', 'sepsis_dx', 'v_ccmds',
	'odys',
	"odys.r", "odys.k", "odys.h", "odys.p", "odys.n", "odys.c", 
	'osupp',
	'sofa_score', 'news_score', 'icnarc_score',
	'rxlimits', 'recommend', 'accept', 'early4', 'icucmp',
	'dead7', 'dead28', 'dead90')

vars <- c('sample_N', vars) # prepend all obs for total counts

# If no strata defined then use sample_N dummy variable
if (is.na(vars.strata)) {
	vars.strata <- 'sample_N'
}

# Define the characteristics of the variables
vars.factor <- c('sex', 'sepsis', 'sepsis_dx', 'v_ccmds',
	'odys',
	"odys.r", "odys.k", "odys.h", "odys.p", "odys.n", "odys.c", 
	'osupp',
	'rxlimits', 'recommend', 'accept', 'early4', 'icucmp',
	'dead7', 'dead28', 'dead90')

# NOTE: 2014-10-12 - you need to have the strata var in the data.table
if (!vars.strata %in% vars) {
	vars <- c(vars, vars.strata)
	vars.factor <- c(vars.factor, vars.strata)
}
vars.factor <- c('sample_N', vars.factor) # prepend all obs for total counts
vars.norm 	<- c('age')
vars.cont 	<- vars[!vars %in% vars.factor]


# Now update columns to be factors if not already
wdt[, (vars.factor) :=lapply(.SD, as.factor), .SDcols=vars.factor]

# Remove the stratifying variable from the factor vars
vars.factor <- vars.factor[!vars.factor %in% vars.strata]

# Now produce the summaries for the continuous vars
# TODO: 2014-10-10 - add n, p.miss skew kurt, q5 q95
# NOTE: 2014-10-11 - lapply to sapply since then returns vectors not lists

t1.contvars <- function(var, strata, this_dt) {
	this_dt[,
		list(
				varname	 = var,
				N 		 = .N,
				# NOTE: 2014-10-11 - add these later else strata means you get missing by strata not var
				miss.n	 = sapply(.SD, function(x) sum(is.na(x))),
				# miss.p	 = sapply(.SD, function(x) round(sum(is.na(x)) / length(x) * 100, 1)),
				mean	 = sapply(.SD, function(x) mean(x, na.rm=TRUE)),
			 	sd		 = sapply(.SD, function(x) sd(x, na.rm=TRUE)),
			 	min		 = sapply(.SD, function(x) min(x, na.rm=TRUE)),
			 	q05		 = sapply(.SD, function(x) quantile(x, 0.05, na.rm=TRUE)),
			 	q25		 = sapply(.SD, function(x) quantile(x, 0.25, na.rm=TRUE)),
			 	q50		 = sapply(.SD, function(x) quantile(x, 0.50, na.rm=TRUE)),
			 	q75		 = sapply(.SD, function(x) quantile(x, 0.75, na.rm=TRUE)),
			 	q95		 = sapply(.SD, function(x) quantile(x, 0.95, na.rm=TRUE)),
			 	max		 = sapply(.SD, function(x) max(x, na.rm=TRUE))
			 	),
			by=strata,
			.SDcols = var
	]
}
# t1.contvars(c('lactate', 'bpsys'), c('room_cmp', 'sex'), wdt)
# t1.contvars('lactate', vars.strata, wdt)

# Now do this for all the continuous vars
t1.contvars.results <- t1.contvars(vars.cont, vars.strata, wdt)

# Now total the missing by variable
t1.contvars.results[,miss.n := sum(miss.n), by=varname]
t1.contvars.results[, miss.p := lapply(.SD, function(x) round(max(miss.n)/sum(N) *100, 1)), by=varname ]

# Now convert this list of data.tables into a single data.table
t1.contvars.results$vartype <- 'continuous'
t1.contvars.results

# Categorical vars

t1.catvars <- function(var_as_string, strata_as_string, this_dt) {

	strata 		<- this_dt[[strata_as_string]]
	var 		<- this_dt[[var_as_string]]

	var <- with(this_dt, get(var_as_string))
	t2 <- this_dt[,.(strata.rows=.N),by=strata]

	t1 <- this_dt[, .N ,by=list(var, strata)]
	setkey(t1, strata)
	setkey(t2, strata)
	t1 <- t1[t2]

	t1[,`:=` (
		pct 	= round(N/strata.rows*100, 1),
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
	strata 	= get(vars.strata),
	varname = varname,
	level 	= level,
	v.mid	= ifelse(vartype == 'categorical', N, ifelse(dist== 'normal', mean, q50)),
	v.left	= ifelse(vartype == 'categorical', pct, ifelse(dist == 'normal', sd, q25)),
	v.right	= ifelse(vartype == 'categorical' | dist == 'normal', NA, q75),
	miss.n	= miss.n,
	miss.p	= miss.p,
	N 		= N,
	vartype = vartype,
	dist 	= dist
	)]


# Now provide the formatting
t1.results.formatted <- t1.results.formatted[,
	`:=` (
	v.fmt1 	= ifelse(vartype == 'categorical', sprintf("%.0f", v.mid), sprintf("%.1f", v.mid)),
	v.fmt2 	= ifelse(vartype == 'categorical', paste('(', sprintf("%.1f", v.left), '%)', sep=''),
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

#  =======================
#  = Now export to excel =
#  =======================
wb <- loadWorkbook(table1.file, create = TRUE)

sheet1 <- paste('varsBy_', vars.strata, sep='')
removeSheet(wb, sheet1)
createSheet(wb, name = sheet1)
writeWorksheet(wb, t1.wide.summ, sheet1)

sheet2 <- paste('varsBy_', vars.strata, '_detail', sep='')
removeSheet(wb, sheet2)
createSheet(wb, name = sheet2)
writeWorksheet(wb, t1.wide.raw, sheet2)

saveWorkbook(wb)

