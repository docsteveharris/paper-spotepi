# author: Steve Harris
# date: 2014-12-01
# subject: Prepare (SPOT)light data for paper-spotepi

# Readme
# ======

# You should then be able to knit the rmarkdown version of the paper.
# Syntax guide for naming objects
# - prefix w: working
# - prefix r: raw
# - suffix: df = data.frame, dt = data.table
# - append suffix '.label' where you need further specification

# try and follow the google R style guide
# http://google-styleguide.googlecode.com/svn/trunk/Rguide.xml


# Todo
# ====


# Log
# ===
# 2014-10-07
# - file created
# 2014-12-01
# - file cloned from results-spotearly.R

rm(list=ls(all=TRUE))
# Load variables / set options
working.stata.data <- "/Volumes/phd/data-spot_ward/working_postflight.dta"
sites.stata.data <- "/Volumes/phd/data-spot_ward/sites.dta"
units.stata.data <- "/Volumes/phd/data-spot_ward/unitsfinal.dta"
occupancy.stata.data <- "/Volumes/phd/data-spot_ward/working_occupancy.dta"

# Load libraries
library(assertthat)
library(Hmisc)
library(foreign)
library(data.table)

# Run data preparation and cleaning if needed

clean.run <- TRUE
# ----------------
if (clean.run) {
    #  ======================================
    #  = Load stata working_postflight_plus =
    #  ======================================
    # convert.factors as false because some are too literally specified
    # Units
    # rdf.units <- read.dta(units.stata.data,
    #     convert.dates = TRUE,
    #     convert.underscore = FALSE,
    #     convert.factors = FALSE
    #     )
    # # Sites
    # rdf.sites <- read.dta(sites.stata.data,
    #     convert.dates = TRUE,
    #     convert.underscore = FALSE,
    #     convert.factors = FALSE
    #     )
    # # Occupancy
    # wdt.occ <- data.table(read.dta(occupancy.stata.data,
    #     convert.dates = TRUE,
    #     convert.underscore = FALSE,
    #     convert.factors = FALSE
    #     ))
    # Working postflight data
    rdf <- read.dta(working.stata.data,
        convert.dates = TRUE,
        convert.underscore = FALSE,
        convert.factors = FALSE
        )



    wdf <- rdf
    row.names(wdf) <- wdf$id
    var.names <- data.frame(names(wdf))
    wdt <- data.table(wdf)
    setkey(wdt, icode)

    #  ===================================
    #  = Prepare other views of the data =
    #  ===================================
    # Hospital and site characteristics for participating sites
    # NOTE: 2014-10-07 - count_patients is the standardised patients per month
    wdt.sites <- wdt[, list(
        patients = length(id),
        teaching = teaching_hosp[1],
        studymonths_n = length(unique(studymonth)),
        pts_by_hes_a = count_patients[1] * 12 / hes_admissions[1],
        pts_by_hes_n = count_patients[1] * 12 / hes_overnight[1] ,
        pts_by_hes_e = count_patients[1] * 12 / hes_emergx[1],
        ccot = ccot_shift_pattern[1]
        )
        , by = "icode" ]
    # rdt.sites <- data.table(rdf.sites)
    # rdt.sites <- rdt.sites[,.(
    #     icode,
    #     cmp_beds_persite,
    #     units_incmp,
    #     cmp_patients_permonth,
    #     tails_core_percent,
    #     tails_all_percent,
    #     hes_admissions 
    #     )]
    # setkey(wdt.sites, icode)
    # setkey(rdt.sites, icode)
    # wdt.sites <- rdt.sites[wdt.sites,nomatch=NA]
    # wdt.sites[head(icode)]

    #  =================
    #  = Save data ... =
    #  =================
    # rm(rdf, rdf.sites, rdf.units,
    #     working.stata.data, sites.stata.data, units.stata.data,
    #     occupancy.stata.data, clean.run)
    # save(list = ls(all = TRUE)) should be equivalent to save.image
    save(list = ls(all = TRUE),
        file = "../data/paper-spotepi.RData",
        precheck = FALSE)
}

#  =============
#  = Load data =
#  =============
# Load the necessary data
rm(list=ls(all=TRUE))
load("../data/paper-spotepi.RData")



