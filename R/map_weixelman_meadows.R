# weixelman meadows


# Load Libraries ----------------------------------------------------------

library(dplyr); library(readr); library(lubridate)

# READ IN DATA ------------------------------------------------------------

## Weixelman Data
dat<-read_csv("./data/base/2016 Sierra Nevada FS plots March 29 2016.csv")
str(dat)

load("./data/base/mdw_geedat2.rda")  # mdws: full google earth dataset (1424 mdws)
# str(mdws)

# need to extract the XY for meadows to plot:
mdws_xy<- comb %>% distinct(ID) %>%
  #filter(!is.na(lat)) %>%
  as.data.frame()

# only meadows over 1.4 hectares here
load("./data/base/mdw_xydat.rda") # xydat: GE mdws dataset just XYs  

str(xydat)

# MERGE WITH EXISTING MEADOWS ---------------------------------------------

wx.mdw<-left_join(dat, xydat, by=c("UCDavis_Object_ID"="ID"))
wx.mdw
