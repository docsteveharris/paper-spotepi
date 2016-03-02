# author: Steve Harris
# date: 2016-03-02
# subject: Rework time2icu plots in R

# Readme
# ======


# Todo
# ====


# Log
# ===
# 2014-11-07
# - file created
# 2014-12-18
# - updated, to be combined in a single layout with 'by_beds'
# - current plot size is wxh 3x7 ish
# 2016-03-01
# - moved in from paper-spotearly
# 2016-03-02
# - duplicated from fg_time2icu_by_decision

rm(list=ls(all=TRUE))

library(data.table)
library(reshape2)
library(ggplot2)
library(Hmisc)
library(plyr)

# Load the necessary data
# -----------------------
# setwd('/Users/steve/aor/academic/paper-spotepi/src/')
load("data/paper-spotepi.RData")

tdt <- wdt[!is.na(time2icu) & !is.na(room_cmp2),.(
    time2icu,
    room_cmp2=factor(room_cmp2, labels=c("0 beds", "1-2 beds", "3+ beds")),
    dead90)]
describe(tdt$room_cmp2)

gg.all <- ggplot(data=tdt)
str(gg.all)
gg.limit <- ggplot(tdt[time2icu<=96])
str(gg.limit)

# Boxplot
# -------
# NOTE: 2014-11-07 - [ ] http://stackoverflow.com/questions/3010403/jitter-if-multiple-outliers-in-ggplot2-boxplot
find_outliers <- function(y, coef = 1.5) {
   qs <- c(0, 0.25, 0.5, 0.75, 1)
   stats <- as.numeric(quantile(y, qs))
   iqr <- diff(stats[c(2, 4)])

   outliers <- y < (stats[2] - coef * iqr) | y > (stats[4] + coef * iqr)

   return(y[outliers])
}
outlier_data <- data.table(
  ddply(tdt, .(room_cmp2), summarise, time2icu = find_outliers(time2icu)))
str(outlier_data)

# Can't do coord_cartesian and coord_flip together so manually truncate in graphic
time2icu.boxplot <- ggplot(data=tdt,
        aes(y=time2icu, x=room_cmp2)) +
    geom_boxplot(notch=FALSE, outlier.colour=NA, varwidth=FALSE, width=0.25) +
    geom_jitter(data=outlier_data, alpha=1/4, size=1,
        position=position_jitter(width=0.1, height=0.3)) +
    scale_y_continuous(
      # labels=c("0", "4h", "12h", "1d", "2d", "3d", "4d", "5d", "6d", "7d" ),
      # breaks=c(0,4,12,24,48,72,96,120,144,168)
      breaks=c(0,4,12,24,48,72,96)
      ) +
    theme_minimal() +
    coord_flip()
    # coord_cartesian(y=c(0,96))

time2icu.boxplot

time2icu.boxplot.fmt <- time2icu.boxplot +
    labs(y="Time to critical care admission", x="Occupancy at assessment") +
    # ggtitle("Delay to admission to critical care") +
    theme(text = element_text(vjust=0.5, size=10),
        plot.title = element_text(size=10))

time2icu.boxplot.fmt

# ggsave(filename="../outputs/figures/fg_time2icu_by_decision.png", plot=time2icu.boxplot.fmt )
ggsave(filename="../write/figures/fg_time2icu_by_occupancy.pdf",
  width=16, height=4,
  plot=time2icu.boxplot.fmt)

