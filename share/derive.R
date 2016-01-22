# author: Steve Harris
# date: 2015-01-06
# subject: Functions to derive vars

# Readme
# ======
# Function definitions only


# Todo
# ====


# Log
# ===
# 2015-01-06
# - file created
# - SOFA score calcs added
# 2015-01-06
# - added Last one carried forward calc
# 2015-01-16
# - copied from analysis-spotid: you may need to merge in future changes
require(assertthat)

gen.locf <- function(data=wdt, var, var.id="id", var.time="t",
    roll=24, rollends=c(FALSE,TRUE), replace=FALSE) {
    # Update (i.e. replace) variable with LOCF version
    # ----------------------------------------------------
    # Requires
    # - data - a data.table object
    # - id variable - for panel
    # - t variable for time within panel
    # - roll +ve integer will set window, TRUE is equiv to Inf window,
    #   -ve roll back the number is in units of var.time 24 means a 24
    #   hour window
    # - rollends - c(FALSE,TRUE) will roll last not first value
    #   works within window of roll only

    cols.key <- c(var.id, var.time)
    cols.locf <- c(var.id, var.time, var)

    # See http://stackoverflow.com/a/15791747/992999 data.table metaprogramming
    locf <- data[!is.na(get(var)),.SD,.SDcols=cols.locf]
    setkeyv(locf,cols.key)
    setkeyv(data,cols.key)
    jdt <- locf[data,roll=roll,rollends=rollends]
    var.old <- paste("i.", var, sep="")

    # Now delete the old variable or create a matching variable to show
    # when the value if observed
    if (replace) {
        jdt[, var.old := NULL, with=FALSE]
    } else {
        # NOTE: 2015-01-06 - [ ] keep as example of data.table
        # metaprogramming jdt[, var.obs := lapply(.SD, function(x)
        # !is.na(x)), .SDcols=c(var.old)] var.obs <- paste(var, ".obs",
        # sep="") # obs for observed setnames(jdt,"var.obs", var.obs)
        var.orig <- paste(var, ".orig", sep="") # orig for original
        setnames(jdt,var.old, var.orig)
        # jdt[, var.old := NULL, with=FALSE]
    }
    return(jdt)
}



# Test sofa.c
# Generate test data
# chk.dt <- data.table(
#     bpsys      = sample( c(NA, round(250 * runif(30))), 30, replace=TRUE ),
#     bpdia      = sample( c(NA, round(180 * runif(30))), 30, replace=TRUE ),
#     rxcvs_drug = sample( c(NA, "Noradrenaline", "Dopamine",
#             "Vasopressin", "Other"), 30, replace=TRUE ),
#     rxcvs_dose = sample( c(NA, round(2 * runif(30), 2)), 30, replace=TRUE )
#     )
# chk.dt

gen.sofa.c <- function(bpsys, bpdia, rxcvs_drug=NULL, rxcvs_dose=NULL) {

    # Debugging
    # attach(chk.dt)

    rx1 <- c("Adrenaline", "Noradrenaline")
    rx2 <- c("Dopamine")
    rx3 <- c("Vasopressin")
    rx  <- c(rx1, rx2, rx3, "Other")

    # Print these descriptions so you know what you have passed to the function
    bpmap <- round(bpdia + (bpsys - bpdia) / 3)

    # Work out if SOFA score can be calculated
    chk.possible <- ifelse( !is.na(bpsys), TRUE,FALSE)

    # SOFA via blood pressure
    sofa.c <- ifelse(is.na(bpmap) & bpsys >= 90, 0, NA)
    sofa.c <- ifelse(bpmap >= 70 | bpsys >= 90, 0, NA)
    sofa.c <- ifelse(bpsys < 90, 1, sofa.c)
    sofa.c <- ifelse(bpmap < 70, 1, sofa.c)

    # SOFA via drugs
    if (all(!is.null(rxcvs_drug), !is.null(rxcvs_dose))) {

        chk.possible <- ifelse(!is.na(bpsys) | rxcvs_drug %in% rx, TRUE,FALSE)

        rx_ok <- ifelse(!is.na(rxcvs_drug), TRUE, FALSE)
        # Any vasoactive drug score 2
        sofa.c <- ifelse(rx_ok & rxcvs_drug %in% rx, 2, sofa.c)
        # Arbitrary decision to encode vasopressin to SOFA 4
        sofa.c <- ifelse(rx_ok & rxcvs_drug == rx3, 4, sofa.c)

        rx_ok <- ifelse(!is.na(rxcvs_drug) & !is.na(rxcvs_dose), TRUE, FALSE)
        # Drug and dose
        sofa.c <- ifelse(rx_ok & rxcvs_drug == rx2 & rxcvs_dose <= 5, 2, sofa.c)
        sofa.c <- ifelse(rx_ok & rxcvs_drug == rx2 & rxcvs_dose > 5, 3, sofa.c)
        sofa.c <- ifelse(rx_ok & rxcvs_drug %in% rx1 & rxcvs_dose <= 0.1, 3, sofa.c)
        sofa.c <- ifelse(rx_ok & rxcvs_drug %in% rx1 & rxcvs_dose > 0.1, 4, sofa.c)
        sofa.c

    }
    # print(describe(sofa.c))
    # print(sum(chk.possible))
    # print(sum(!is.na(sofa.c)))
    # TODO: 2015-01-10 - [ ] @later test fails? - close though
    # assert_that(sum(chk.possible) ==  sum(!is.na(sofa.c)))
    return(sofa.c)
    # detach(chk.dt)
}
# chk.dt[, sofa.c := gen.sofa.c(bpsys=bpsys, bpdia=bpdia)]
# chk.dt[, sofa.c := gen.sofa.c(bpsys=bpsys, bpdia=bpdia, rxcvs_drug=rxcvs_drug, rxcvs_dose=rxcvs_dose)]
# wdt.long[, sofa.c := gen.sofa.c(bpsys=bpsys, bpdia=bpdia, rxcvs_drug=rxcvs_drug, rxcvs_dose=rxcvs_dose)]


# SOFA Resp
# Generate test data
# rx <- c("Room air", "Wall (variable performance)", "Venturi / High-flow",
#         "Reservoir bag", "CPAP", "NIV", "IPPV", "Other")
# chk.dt <- data.table(
#     pf     = sample( c(rep(NA,15), round(100 * runif(15))), 30, replace=TRUE ),
#     sf     = sample( c(NA, 100 + round(400 * runif(30))), 30, replace=TRUE ),
#     rxfio2 = sample( c(NA, rx), 30, replace=TRUE )
#     )
# chk.dt
# chk.dt[, sofa.r := NULL]
# attach(chk.dt)



gen.sofa.r <- function(pf, rxfio2, sf=NULL) {
    # attach(wdt.long)
    # Print these descriptions so you know what you have passed to the function
    # print(describe(pf))
    # print(describe(sf))
    # print(describe(rxfio2))
    mv <- c("IPPV", "NIV", "CPAP")
    # Generate a vector of responses
    # Handle missing data by updating in 2 stages
    # Stage 1 test for the condition with default NA
    # Stage 2 update if not NA
    sofa.r <- ifelse(is.na(pf), NA, 0) # pf available then zero else NA
    update <- ifelse(pf < 100/7.6 & rxfio2 %in% mv, 4, NA)
    sofa.r <- ifelse(!is.na(update), update, sofa.r)
    update <- ifelse(pf >= 100/7.6 & pf < 200/7.6 & rxfio2 %in% mv, 3, NA)
    sofa.r <- ifelse(!is.na(update), update, sofa.r)
    update <- ifelse(pf >=200/7.6 & pf < 300/7.6, 2, NA)
    sofa.r <- ifelse(!is.na(update), update, sofa.r)
    update <- ifelse(pf >= 300/7.6 & pf < 400/7.6, 1, NA)
    sofa.r <- ifelse(!is.na(update), update, sofa.r)
    # print(describe(sofa.r))

    # Use SF ratio if available for scores
    # PF takes priority and update only if not available
    if (!is.null(sf)) {
        update <- ifelse(is.na(pf) & sf < 115 & rxfio2 %in% mv, 4, NA)
        sofa.r <- ifelse(!is.na(update), update, sofa.r)
        update <- ifelse(is.na(pf) & sf >= 115 & sf < 240 & rxfio2 %in% mv, 3, NA)
        sofa.r <- ifelse(!is.na(update), update, sofa.r)

        # SF < 240 and not IPPV/NIV then assign two points
        update <- ifelse(is.na(pf) & sf < 240 & (!(rxfio2 %in% mv) | is.na(rxfio2)), 2, NA)
        sofa.r <- ifelse(!is.na(update), update, sofa.r)
        update <- ifelse(is.na(pf) & sf >= 240 & sf < 370, 2, NA)
        sofa.r <- ifelse(!is.na(update), update, sofa.r)
        update <- ifelse(is.na(pf) & sf >= 370 & sf < 440, 1, NA)
        sofa.r <- ifelse(!is.na(update), update, sofa.r)
        # Do not assign zero if ventilated
        update <- ifelse(is.na(pf) & sf >= 440 & !(rxfio2 %in% mv), 0, NA)
        sofa.r <- ifelse(!is.na(update), update, sofa.r)
        # print(describe(sofa.r))
    }
    # Test if PF != NA then sofa.r exists
    assert_that(sum(is.na(sofa.r)) <= sum(is.na(pf)))
    return(sofa.r)
    # detach(wdt.long)
}
# chk.dt[, sofa.r := gen.sofa.r(pf, sf, rxfio2)]
# chk.dt
# str(wdt.long)
# wdt.long[, fio2.pct := gen.fio2pct(fio2, fio2u)]
# wdt.long[, pf := gen.pf(pao2, fio2.pct)]
# wdt.long[, sf := gen.pf(spo2, fio2.pct)]
# wdt.long[, sofa.r := gen.sofa.r(pf, sf, rxfio2)]

gen.fio2pct <- function(value, unit) {
    # Convert FiO2 to percent
    # Uses ICNARC CMPD recommended conversion
    fio2.pct <- ifelse(unit == "percent", value,
        ifelse(unit == "litres per min" & value >= 8 & value <= 30 , 50,
        ifelse(unit == "litres per min" & value >= 7 & value < 8 , 45,
        ifelse(unit == "litres per min" & value >= 6 & value < 7 , 40,
        ifelse(unit == "litres per min" & value >= 5 & value < 6 , 35,
        ifelse(unit == "litres per min" & value >= 4 & value < 5 , 30,
        ifelse(unit == "litres per min" & value >= 3 & value < 4 , 27,
        ifelse(unit == "litres per min" & value >= 2 & value < 3 , 25, 21
            ))))))))
    return(fio2.pct)
}


gen.pf <- function(pao2, fio2.pct) {
    assert_that(is.na(fio2.pct) || fio2.pct >= 21)
    assert_that(is.na(fio2.pct) || fio2.pct <= 100)
    assert_that(is.na(pao2) || pao2 <= 101)
    pf <- NA
    pf <- pao2 / fio2.pct * 100
    return(pf)
}

gen.sf <- function(spo2, fio2.pct) {
    assert_that(is.na(fio2.pct) || fio2.pct >= 21)
    assert_that(is.na(fio2.pct) || fio2.pct <= 100)
    assert_that(is.na(spo2) || spo2 <= 100)
    sf <- NA
    sf <- spo2 / fio2.pct * 100
    return(sf)
}

gen.sofa.p <- function(platelets, rxplat=NULL) {
    '
    Defines SOFA coagulation score based on platelet count
    In addition, if platelets have been administered then
    automatically assumes SOFA >= 2
    '
    # attach(wdt.long)
    # print(describe(platelets))
    # print(describe(rxplat))
    assert_that(identical(names(table(wdt.long$rxplat)),c("FALSE","TRUE")))
    # NB cut ranges are (a,b] i.e. a<x<=y
    sofa.p <- cut(
        platelets,
        c(-Inf,19,49,99,149,+Inf),
        labels= c(4,3,2,1,0))
    # Cut returns a factor unless labels = FALSE
    sofa.p <- as.numeric(levels(sofa.p))[sofa.p]
    if (!is.null(rxplat)) {
        update <- ifelse(
            rxplat %in% c("TRUE", "True", TRUE) &
            platelets >= 150 , 2, NA)
        sofa.p <- ifelse(!is.na(update), update, sofa.p)
    }
    # print(describe(sofa.p))
    # detach(wdt.long)
    return(sofa.p)
}
# wdt.long[, sofa.p := gen.sofa.p(platelets)]
# wdt.long[, sofa.p := gen.sofa.p(platelets, rxplat)]

gen.sofa.h <- function(bili) {
    '
    Defines SOFA liver score based on bilirubin
    '
    attach(wdt.long)
    # print(describe(bili))
    # NB cut ranges are (a,b] i.e. a<x<=y
    sofa.h <- cut(
        bili,
        c(-Inf,19,32,101,204,+Inf),
        labels=c(0,1,2,3,4))
    # Cut returns a factor unless labels = FALSE
    sofa.h <- as.numeric(levels(sofa.h))[sofa.h]
    # print(describe(sofa.h))
    # detach(wdt.long)
    return(sofa.h)
}
# wdt.long[, sofa.h := gen.sofa.h(bili)]

gen.sofa.n <- function(gcst, avpu=NULL, rxsed=NULL) {
    attach(wdt.long)
    # Print these descriptions so you know what you have passed to the function
    # print(describe(gcst))
    sofa.n <- cut(
        gcst,
        c(2,6,9,12,14,15),
        labels=c(4,3,2,1,0))
    sofa.n <- as.numeric(levels(sofa.n))[sofa.n]

    # Now set to NA if patient sedated
    if (!is.null(rxsed)) {
        # print(describe(rxsed))
        update <- ifelse(rxsed %in% c("True", "TRUE", TRUE), NA, sofa.n)
        describe(update)
        sofa.n <- ifelse(is.na(update), NA, update)
        # print(describe(sofa.n))
    }

    # Now use AVPU if provided
    if (!is.null(avpu)) {
        # print(describe(avpu))
        update <- ifelse(avpu %in% c("Alert - not confused"), 0, NA)
        sofa.n <- ifelse(!is.na(update), update, sofa.n)

        update <- ifelse(avpu %in% c("Alert - new confusion"), 1, NA)
        sofa.n <- ifelse(!is.na(update), update, sofa.n)

        update <- ifelse(avpu %in% c("Verbal response"), 2, NA)
        sofa.n <- ifelse(!is.na(update), update, sofa.n)

        update <- ifelse(avpu %in% c("Response to pain"), 3, NA)
        sofa.n <- ifelse(!is.na(update), update, sofa.n)

        update <- ifelse(avpu %in% c("Unresponsive"), 4, NA)
        sofa.n <- ifelse(!is.na(update), update, sofa.n)
    }

    # print(describe(sofa.n))
    # detach(wdt.long)
    return(sofa.n)
}
# wdt.long[, sofa.n := gen.sofa.n(gcst)]
# wdt.long[, sofa.n := gen.sofa.n(gcst, avpu=avpu)]
# wdt.long[, sofa.n := gen.sofa.n(gcst, avpu=avpu, rxsed=rxsed)]

# TODO: 2015-01-13 - [ ] @resume(2015-01-13) fix: rewrite as per update style
gen.sofa.k <- function(creatinine, urine24, urine1=NULL, rxrrt=NULL) {

    # Attach if debugging
    # attach(chk.dt)
    # print(creatinine)
    # print(urine24)
    # NB cut ranges are (a,b] i.e. a<x<=y
    sofa.k <- cut(
        creatinine,
        c(-Inf,109,170,300,440,+Inf),
        labels= c(0,1,2,3,4))
    sofa.k
    sofa.k <- as.numeric(levels(sofa.k))[sofa.k]
    # print(describe(sofa.k))

    # If RRT information provided
    if (!is.null(rxrrt)) {
        update <- ifelse(
            rxrrt %in% c("TRUE", "True", TRUE), 4, NA)
        sofa.k <- ifelse(!is.na(update), update, sofa.k)
    }
    # print(describe(sofa.k))

    # Don't use hourly urines for now - not part of SOFA definition
    if (is.null(urine1)) {
        urine.sofa <- urine24
    } else {
        # Prioritise 24h urine over hourly measures
        urine.sofa <- ifelse(!is.na(urine24), urine24, 24 * urine1)
    }
    # print(urine.sofa)

    update <- ifelse(urine.sofa >=200 & urine.sofa < 500, 3, NA)
    sofa.k <- ifelse(!is.na(update), max(update,sofa.k,na.rm=TRUE), sofa.k)
    update <- ifelse(urine.sofa >=0 & urine.sofa < 200, 4, NA)
    sofa.k <- ifelse(!is.na(update), max(update,sofa.k,na.rm=TRUE), sofa.k)

    # print(describe((sofa.k)))
    return(sofa.k)
    # detach(chk.dt)
}

# Test sofa.k
# Generate test data
# chk.dt <- data.table(
#     creatinine = sample( c(NA, round(1000 * runif(30))), 30, replace=TRUE ),
#     urine24    = sample( c(NA, round(5000 * runif(30))), 30, replace=TRUE ),
#     urine1     = sample( c(NA, round(500 * runif(30))), 30, replace=TRUE ),
#     rxrrt      = sample( c(NA, "True", "False"), 30, replace=TRUE )
#     )
# chk.dt
# chk.dt[, sofa.k := gen.sofa.k(creatinine=creatinine, urine24=urine24)]
# chk.dt[, sofa.k := gen.sofa.k(creatinine=creatinine, urine24=urine24, urine1=urine1)]
# chk.dt[, sofa.k := gen.sofa.k(creatinine=creatinine, urine24=urine24, rxrrt=rxrrt)]
# chk.dt


# x <- wdt.long[, sofa.k := gen.sofa.k(creatinine=creatinine, urine24=urine24, rxrrt=rxrrt)]
# head(x)
