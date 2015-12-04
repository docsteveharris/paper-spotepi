# author: Steve Harris
# date: 2014-11-27
# subject: Draw a streamgraph to show where patients die

# Readme
# ======


# Todo
# ====


# Log
# ===
# 2014-11-27
# - file created
# 2014-11-27
# - now change the order (fr inside to out: icu-icu.dead.ward.dead)
# - only makes the beds_none vs beds 2+ comparison (as per paper)
# 2014-12-17
# - tidied and prepared for inclusion in paper
# 2014-12-17
# - Draw a survival curve
# - dropped streamgraph idea and switched to location and facets
# 2015-12-02
# - coped in from paper-spotearly
# - updated b/c no longer need reshape2 (now built into data.table)
# - switched fr examining occupancy to comparing pathwayss

# Load dependencies
# -----------------
library(foreign)
library(GGally)
library(survival)
library(data.table)
library(Hmisc)
# packageDescription('data.table')
# library(reshape2) # don't need reshape2 if using data.table >=1.9.6

rm(list=ls(all=TRUE))

# Waf control
source("project_paths.r")

# Load the necessary data
# -----------------------
working.data <- paste0(PATH_DATA, '/working_survival_single.dta')
rdt <- data.table(read.dta(working.data,
    convert.dates = FALSE,
    convert.underscore = FALSE,
    convert.factors = FALSE
    ))
# head(rdf[c('dt1', 'dt2', 'dt3', 'dt4')])

# Check this is the correct data
dim(rdt)
assert_that(all.equal(dim(rdt),c(15158,345)))
# str(rdt)

# dt1-4 should be days
days <- data.table(time = c(0:89))
setkey(days)

# Define new vars
rdt[, pathway := 
        ifelse(rxlimits==1,1,
        ifelse(icu_recommend==0,2,3))]
describe(rdt$pathway)
rdt[, room_cmp2 := cut2(open_beds_cmp, c(1,3), minmax=T )]
describe(rdt$room_cmp2)

# Just work with dates for now (refine with times later)
patients <- rdt[,.(id, dead, dt1, dt2, dt3, dt4, pathway, room_cmp2)]
setkey(patients,id)

days.patients <- days[,as.list(patients),by=time]
days.patients[,`:=`(
    # indicator for patient being alive
    i.alive    = ifelse(dead == 1 & time > dt4, 0, 1),
    # indicator for patient being dead
    i.dead     = ifelse(dead == 1 & time > dt4, 1, 0),
    # indicator for patient being in ICU
    i.icu.now  = ifelse(is.na(dt2) | is.na(dt3), 0, ifelse(time > dt2 & time < dt3, 1, 0)),
    # indicator that had had ICU
    i.icu.prev = ifelse(is.na(dt3), 0, ifelse(time > dt3, 1, 0))
    )]
str(days.patients)

days.patients[,`:=`(
    # indicator that alive without having been in ICU
    i.alive.noicu   = ifelse(i.dead == 0 & i.icu.prev == 0 & i.icu.now == 0, 1, 0),
    # indicator that alive post-icu discharge
    i.alive.posticu = ifelse(i.dead == 0 & i.icu.prev == 1, 1, 0),
    # indicator for patient being dead having been through ICU
    i.dead.posticu  = ifelse(i.dead == 1 & i.icu.prev == 1, 1, 0 ),
    # indicator for patient beind dead without having been in ICU
    i.dead.noicu    = ifelse(i.dead == 1 & i.icu.prev == 0, 1, 0 )
    )]
days.patients
setorder(days.patients, id, time)
str(days.patients)
# INSPECT TO CHECK
# describe(days.patients)
# days.patients[id==2222]
# days.patients[id==3334]
# days.patients[id==4334]

# Total status by day
days.sum <- days.patients[
    ,
    .(
    sum.dead = sum(i.dead),
    sum.alive = sum(i.alive),
    sum.dead.noicu = sum(i.dead.noicu),
    sum.alive.noicu = sum(i.alive.noicu),
    sum.dead.posticu = sum(i.dead.posticu),
    sum.alive.posticu = sum(i.alive.posticu),
    sum.icu.now = sum(i.icu.now))
    ,
    by=.(time, pathway)]

# Now scale
tt <- days.sum
tt <- melt(tt, id=c("time", "pathway"))
tt <- tt[!is.na(value)]
sb <- patients[,.N,by=pathway]
setkey(sb, pathway)
setkey(tt, pathway)
tt <- sb[tt]
tt[, value := value/N*100]
# - [ ] NOTE(2015-12-02): don't need to dcast
# tt
# head(dcast(tt, time + pathway ~ variable))
# tt <- dcast(tt, time + pathway + variable ~ .)
tt[, pathway:=factor(pathway, label=c("Rxlimits", "Ward", "Critical care"))]
str(tt)

head(tt[variable=="sum.icu.now",.(time, pathway, value)])

gg <- ggplot(data=tt, aes(x=time, group=variable, y=value, colour=variable))
p.base <- gg +
 geom_line(data=tt[variable=="sum.icu.now"]) +
 geom_line(data=tt[variable=="sum.alive"]) +
 geom_line(data=tt[variable=="sum.dead"]) +
 geom_hline(yintercept=0) +
 facet_grid(.~pathway) +
 coord_cartesian(ylim=c(0,100), xlim=c(0,90)) +
 scale_x_continuous(breaks=seq(0,90,30)) +
 theme_minimal()
p.base
stop()

p.fmt <- p.base +
# Increase horizontal spacing between facets
 theme(panel.margin.x=unit(1, "lines")) +
 xlab("Days following bedside assessment") +
 ylab("Proportion of patients assessed (%)") +
 ggtitle("Available critical care beds when assessed") +
    scale_colour_discrete(name="Status",
    breaks=c("sum.dead", "sum.dead.noicu", "sum.icu.now"),
    labels=c("Died (total)", "Died without critical care", "Receiving critical care"))

p.fmt

# Now output
ggsave(file="../outputs/figures/status_by_occupancy.png", width=8, height=4, dpi=300)
ggsave(file="../outputs/figures/status_by_occupancy.pdf", width=8, height=4)
ggsave(file="../outputs/figures/status_by_occupancy.svg", width=8, height=4)
