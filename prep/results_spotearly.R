# author: Steve Harris
# date: 2014-10-07
# subject: Prepare (SPOT)light data for paper-spotearly

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
# TODO: 2015-07-21 - [ ] convert to run under waf


# Log
# ===
# 2014-10-07
# - file created
# 2015-07-21
# - converting to run under waf


# Waf set-up
rm(list=ls(all=TRUE))
# setwd('/Users/steve/aor/academic/paper-spotepi/vc-paper-spotepi/prep')
source("project_paths.r")

# Load variables / set options
# TODO: 2015-07-21 - [ ] but working_post_flight_plus does not exist, go with postflight
# working.stata.data <- "/Volumes/phd/data-spot_early/working_postflight_plus.dta"
working.stata.data <- paste0(PATH_DATA, '/working_postflight.dta')

# TODO: 2015-07-21 - [ ] does not exist
# sensitivity.stata.data <- paste0(PATH_DATA, "/working_sensitivity.dta")
sites.stata.data <- paste0(PATH_DATA, "/sites.dta")
units.stata.data <- paste0(PATH_DATA, "/unitsfinal.dta")
occupancy.stata.data <- paste0(PATH_DATA, "/working_occupancy.dta")
clean.run <- TRUE

# Load libraries
require(assertthat)
require(Hmisc)
library(foreign)
require(data.table)
# library(tolerance)

# Run data preparation and cleaning if needed

if (clean.run) {
    #  ======================================
    #  = Load stata working_postflight_plus =
    #  ======================================
    # convert.factors as false because some are too literally specified
    # Units
    rdf.units <- read.dta(units.stata.data,
        convert.dates = TRUE,
        convert.underscore = FALSE,
        convert.factors = FALSE
        )
    # Sites
    rdf.sites <- read.dta(sites.stata.data,
        convert.dates = TRUE,
        convert.underscore = FALSE,
        convert.factors = FALSE
        )
    # Occupancy
    wdt.occ <- data.table(read.dta(occupancy.stata.data,
        convert.dates = TRUE,
        convert.underscore = FALSE,
        convert.factors = FALSE
        ))
    # Working postflight data
    rdf <- read.dta(working.stata.data,
        convert.dates = TRUE,
        convert.underscore = FALSE,
        convert.factors = FALSE
        )
    # Working sensitivity data
    # wdt.sens <- data.table(read.dta(sensitivity.stata.data,
    #     convert.dates = TRUE,
    #     convert.underscore = FALSE,
    #     convert.factors = FALSE
    #     ))

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
    rdt.sites <- data.table(rdf.sites)
    rdt.sites <- rdt.sites[,.(
        icode,
        cmp_beds_persite,
        units_incmp,
        cmp_patients_permonth,
        tails_core_percent,
        tails_all_percent,
        hes_admissions
        )]
    setkey(wdt.sites, icode)
    setkey(rdt.sites, icode)
    wdt.sites <- rdt.sites[wdt.sites,nomatch=NA]
    wdt.sites[head(icode)]
    dim(wdt.sites)

    #  =================
    #  = Save data ... =
    #  =================
    rm(rdf, rdf.sites, rdf.units,
        working.stata.data, sites.stata.data, units.stata.data,
        occupancy.stata.data, clean.run
        # , sensitivity.stata.data
        )
    # save(list = ls(all = TRUE)) should be equivalent to save.image
    save(list = ls(all = TRUE),
        file = paste0(PATH_DATA, "/paper-spotepi.RData"),
        precheck = FALSE)
}

#  =============
#  = Load data =
#  =============
# Load the necessary data
# rm(list=ls(all=TRUE))
# load("../data/paper-spotearly.RData")


