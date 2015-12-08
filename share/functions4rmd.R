# author: Steve Harris
# date: 2015-01-10
# subject: Function definitions for paper R markdown

# Readme
# ======


# Todo
# ====


# Log
# ===
# 2015-01-10
# - file created
require(data.table)

t.test.format <- function(data=wdt, var, byvar, dp=1) {
    # Run a t-test and return formatted difference and CI
    data <- data[,c(var, byvar),with=FALSE]
    fmt <- paste("%.", dp, "f", sep="")

    byvar.var       <- t.test(data[[1]] ~ data[[2]], data=data)
    byvar.var.d     <- byvar.var$estimate[1] - byvar.var$estimate[2]

    est1            <- sprintf(fmt, byvar.var$estimate[1])
    est2            <- sprintf(fmt, byvar.var$estimate[2])
    l95             <- sprintf(fmt, abs(byvar.var$conf.int[1]))
    u95             <- sprintf(fmt, abs(byvar.var$conf.int[2]))

    # get order right
    if (abs(byvar.var$conf.int[1])>abs(byvar.var$conf.int[2])) {
        x   <- l95
        l95 <- u95
        u95 <- x
    }

    byvar.var.d     <- sprintf(fmt, abs(byvar.var.d))
    byvar.var.ci    <- paste(l95, '--', u95, sep='')

    return(list(
        est1 = est1,
        est2 = est2,
        d = byvar.var.d, 
        ci = byvar.var.ci))
}

median.difference <- function(x, i) {
    require(boot)
    # bootstrap median for 95%CI
    # see http://stats.stackexchange.com/questions/21103/confidence-interval-for-median?rq=1
    y <- x[i] # i is a random index
    m1 <- median(y[beds_none==0]$time2icu)
    m2 <- median(y[beds_none==1]$time2icu)
    median.difference <- m2 - m1
}

ff.mediqr <- function(var, data=wdt, dp=0) {
    # Return median and IQR
    fmt <- paste("%.", dp, "f", sep="")
    v <- with(data, get(var))
    v.q <- sprintf(fmt, quantile(v, na.rm=TRUE))
    v.iqr <- paste(v.q[2], "--", v.q[4], sep="")
    return(list(q50=v.q[3], iqr=v.iqr))

}

ff.np <- function(var, data=wdt, dp=1) {
    # Return n and % for binary vars
    v <- with(data, get(var))
    fmt <- paste("%.", dp, "f", sep="")
    v.yn  <- data[,.(n=.N,pct=100*.N/nrow(data)),by=v]
    setorder(v.yn, v)
    print(v.yn)
    v.n <- sprintf("%.0f", v.yn$n)
    v.p <- sprintf(fmt, v.yn$pct)
    # Return as list so you can use $ for subsetting
    return(list(n=v.n,p=v.p))
}

prop.test.format <- function(var, byvar, data=wdt, dp=1) {
    data <- data[,c(var, byvar),with=FALSE]
    fmt <- paste("%.", dp, "f", sep="")
    byvar.var <- prop.test(with(data, table(data[[2]], data[[1]])))

    byvar.var.d     <- byvar.var$estimate[1] - byvar.var$estimate[2]

    est1            <- sprintf(fmt, 100*byvar.var$estimate[1])
    est2            <- sprintf(fmt, 100*byvar.var$estimate[2])
    l95             <- sprintf(fmt, 100*abs(byvar.var$conf.int[1]))
    u95             <- sprintf(fmt, 100*abs(byvar.var$conf.int[2]))

    # get order right
    if (abs(byvar.var$conf.int[1])>abs(byvar.var$conf.int[2])) {
        x   <- l95
        l95 <- u95
        u95 <- x
    }

    byvar.var.d     <- sprintf(fmt, abs(byvar.var.d))
    byvar.var.ci    <- paste(l95, '--', u95, sep='')

    return(list(
        est1 = est1,
        est2 = est2,
        d = byvar.var.d, 
        ci = byvar.var.ci))
}