# author: Steve Harris
# date: 2014-10-15
# subject: Plot severity distribution and mortality

# Readme
# ======


# Todo
# ====


# Log
# ===
# 2014-10-15
# - file created
# 2014-11-06
# - working copy of plot
# 2014-11-27
# - switch to 7 day mortality since this ties in better with paper
# - scale circles by area not radius
# 2015-07-31
# - put under waf control
# 2015-11-04
# - transform the code into a function that then works with different
#   severity scores

rm(list=ls(all=TRUE))
# setwd('/Users/steve/aor/academic/paper-spotearly/src/analysis')

# Load the necessary data
# -----------------------
load("../data/paper-spotepi.RData")

# Load dependencies
# -----------------
library(data.table)
library(reshape2)
library(ggplot2)
library(Hmisc)
library(assertthat)

# Check this is the correct data
nrow(wdt)
assert_that(nrow(wdt)==15158)

doplot.severity <- function(v.dead, v.severity, l.severity, r.severity) {
    # v.severity = severity variable
    # l.severity = severity label
    # r.severity = severity x range
    tdt  <- data.table(v.dead,v.severity)
    v.bin <- 1
    tdt[,bin:=v.severity%/%v.bin]
    head(tdt)
    tdt.gg <- tdt[,.(n=.N,v.dead=mean(v.dead,na.rm=TRUE),p=.N/nrow(tdt)),by=bin][order(bin)]
    # Scale p to max 1
    v.alpha.weight <- 1
    tdt.gg[,p.scale := ((p/max(p)/v.alpha.weight) + (1 - (1/v.alpha.weight)))]
    str(tdt.gg)
    # describe(tdt.gg$p.scale)
    # NOTE: 2014-10-16 - [ ] collapse values above 90th and below 10th centile
    # This should improve the appearance
    describe(tdt.gg$v.dead)
    tdt.gg[,v.dead.limit := ifelse(v.dead>0.75, 75, 100*v.dead)]
    tdt.gg[,v.dead.pct := 100*v.dead]

    # Alternative approach b/c you aren't allowed multiple axes in ggplot2
    # --------------------------------------------------------------------
    gg.2 <- ggplot(tdt.gg[n>10], aes(x=bin, y=v.dead.pct, size=n ), asp=1) +
        geom_point(show_guide=TRUE) +
        labs(x=l.severity, y="7-day mortality (%)") +
        guides(size=guide_legend(title="Sample size")) +
        # NOTE: 2015-11-04 - [ ] drop title; will become caption in final fig
        # ggtitle("Physiological severity at assessment\n and 7-day mortality") +
        # ggtitle("") +
        coord_cartesian(x=r.severity, y=c(0,50)) +
        scale_size_area() + # NB: default in ggplot is scale radius which is misleading
        theme_minimal()
    gg.2
    return(gg.2)

}

# ICNARC score
# ------------
gg.2 <- doplot.severity(v.dead=wdt$dead7, v.severity=wdt$icnarc0,
    r.severity=c(0,50),
    l.severity="ICNARC physiology score")

# ggsave(filename=paste0("write/figures", "/fg_dead7_imscore.png"), plot=gg.2,
# width=5, height=4, scale=1.3, dpi=600
# )
ggsave(filename=paste0("write/figures", "/fg_dead7_imscore.jpg"), plot=gg.2,
width=5, height=4, scale=1.3
)

# SOFA score
# ----------
gg.2 <- doplot.severity(v.dead=wdt$dead7, v.severity=wdt$sofa_score,
    r.severity=c(0,15),
    l.severity="SOFA score")

ggsave(filename=paste0("write/figures", "/fg_dead7_sofa.jpg"), plot=gg.2,
width=5, height=4, scale=1.3
)

# NEWS score
# ----------
describe(wdt$news_score)
gg.2 <- doplot.severity(v.dead=wdt$dead7, v.severity=wdt$news_score,
    r.severity=c(0,20),
    l.severity="NEWS score")

ggsave(filename=paste0("write/figures", "/fg_dead7_news.jpg"), plot=gg.2,
width=5, height=4, scale=1.3
)


