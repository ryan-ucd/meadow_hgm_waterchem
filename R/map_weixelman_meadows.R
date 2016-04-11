# weixelman meadows


# Load Libraries ----------------------------------------------------------

library(dplyr); library(readr); library(lubridate)

# READ IN DATA ------------------------------------------------------------

## Weixelman Data
dat<-read_csv("./data/base/2016 Sierra Nevada FS plots March 29 2016.csv")
str(dat)

load("./data/base/mdw_geedat2.rda")  # mdws: full dataset
str(mdws)

load("./data/base/mdw_xydat.rda") # xydat: mdws dataset just XYs # but not full xy set? WTF?
str(xydat)

# MERGE WITH EXISTING MEADOWS ---------------------------------------------

wx.mdw<-left_join(dat, xydat, by=c("UCDavis_Object_ID"="ID"))
wx.mdw
