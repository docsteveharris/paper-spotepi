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
# setwd('/Users/steve/aor/academic/paper-spotepi/src/')

# Load the necessary data
# -----------------------
load("data/paper-spotepi.RData")

# Define output format
figure.fmt <- "pdf" # note SVG requires X quartz on Mac OS X

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

doplot.severity <- function(v.out, v.severity, l.severity, r.severity) {
    # v.severity = severity variable
    # l.severity = severity label
    # r.severity = severity x range
    tdt  <- data.table(v.out,v.severity)
    v.bin <- 1
    tdt[,bin:=v.severity%/%v.bin]
    head(tdt)
    tdt.gg <- tdt[,.(n=.N,v.out=mean(v.out,na.rm=TRUE),p=.N/nrow(tdt)),by=bin][order(bin)]
    # Scale p to max 1
    v.alpha.weight <- 1
    tdt.gg[,p.scale := ((p/max(p)/v.alpha.weight) + (1 - (1/v.alpha.weight)))]
    str(tdt.gg)
    # describe(tdt.gg$p.scale)
    # NOTE: 2014-10-16 - [ ] collapse values above 90th and below 10th centile
    # This should improve the appearance
    describe(tdt.gg$v.out)
    tdt.gg[,v.out.limit := ifelse(v.out>0.75, 75, 100*v.out)]
    tdt.gg[,v.out.pct := 100*v.out]

    # Alternative approach b/c you aren't allowed multiple axes in ggplot2
    # --------------------------------------------------------------------
    gg.2 <- ggplot(tdt.gg[n>10], aes(x=bin, y=v.out.pct, size=n ), asp=1) +
        geom_point(show_guide=TRUE) +
        labs(x=l.severity, y="Bedside recommendation for critical care (%)") +
        guides(size=guide_legend(title="Sample size")) +
        # NOTE: 2015-11-04 - [ ] drop title; will become caption in final fig
        # ggtitle("Physiological severity at assessment\n and 7-day mortality") +
        # ggtitle("") +
        coord_cartesian(x=r.severity, y=c(0,100)) +
        scale_size_area(
            breaks=c(200,400,800,1600,3200),
            labels=c("200","400","800","1600", "3200")) + # NB: default in ggplot is scale radius which is misleading
        theme_minimal()
    gg.2
    return(gg.2)

}

# ICNARC score
# ------------
require(ggplot2)
gg.icnarc <- doplot.severity(v.out=wdt$icu_recommend, v.severity=wdt$icnarc0,
    r.severity=c(0,50),
    l.severity="ICNARC physiology score")
print(gg.icnarc)

# SOFA score
# ----------
gg.sofa <- doplot.severity(v.out=wdt$icu_recommend, v.severity=wdt$sofa_score,
    r.severity=c(0,15),
    l.severity="SOFA score")
print(gg.sofa)


# NEWS score
# ----------
# describe(wdt$news_score)
gg.news <- doplot.severity(v.out=wdt$icu_recommend, v.severity=wdt$news_score,
    r.severity=c(0,20),
    l.severity="NEWS score")
print(gg.news)

# Make a summary file within R
# but note that the final publication file is done by hand within Graphic

# Open file for PDF printing
pdf(file = paste0("write/figures", "/fg_recommend_aps.", "pdf"), width=16, height=8)
grid.newpage()
pushViewport(viewport(layout=grid.layout(1,3)))
print(gg.icnarc, vp=viewport(layout.pos.row=1, layout.pos.col=1))
print(gg.sofa, vp=viewport(layout.pos.row=1, layout.pos.col=2))
print(gg.news, vp=viewport(layout.pos.row=1, layout.pos.col=3))
dev.off()

ggsave(filename=paste0("write/figures", "/fg_recommend_imscore.", figure.fmt), plot=gg.icnarc,
width=5, height=4, scale=1.3
)
ggsave(filename=paste0("write/figures", "/fg_recommend_sofa.", figure.fmt), plot=gg.sofa,
width=5, height=4, scale=1.3
)
ggsave(filename=paste0("write/figures", "/fg_recommend_news.", figure.fmt), plot=gg.news,
width=5, height=4, scale=1.3
)
