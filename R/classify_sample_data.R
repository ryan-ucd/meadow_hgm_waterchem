# classify and sample meadow data
# 2016-04-14

# Load Libraries ----------------------------------------------------------

library(dplyr); library(readr); library(lubridate); library(ggplot2)

#library(rgdal)

# LOAD DATA & MERGE ------------------------------------------------------
# 
# ## Weixelman Data
# dat<-read_csv("./data/base/2016 Sierra Nevada FS plots March 29 2016.csv")
# 
# ## Full Weixelman dataset
# dat2<-read_csv("./data/base/2016 Sierra Nevada FS plots with HGM.csv")
# str(dat2)
# 
# ## mdw shapefile
# mdw.sp<- readOGR("./data/base/Sierra_Nevada_MultiSource_Meadow_Polygons_Compilation_v1_simplify10m.shp", layer="Sierra_Nevada_MultiSource_Meadow_Polygons_Compilation_v1_simplify10m", verbose = F)
# 
# ## projection
# WGS84 <- "+proj=longlat +ellps=WGS84 +datum=WGS84"
# mdw.sp<-spTransform(mdw.sp, CRS(WGS84)) # add a projection
# 
# ## make a dataframe
# mdw.df<-as.data.frame(mdw.sp)
# mdw.df$ID<-as.character(mdw.df$ID)
# 
# # merge with all meadows
# wx.mdw<-left_join(dat, mdw.df, by=c("UCDavis_Object_ID"="ID"))
# dim(wx.mdw)
# 
# # merge with XY data
# dat3<-left_join(dat2, wx.mdw, by=c("PLOT"="PLOT"))
# dat.wx<-select(dat3, PLOT:source_type, ELEV_MEAN, LAT_DD, LONG_DD)
# h(dat.wx)
# 
# write_csv(dat3, path = "./data/base/2016_SN_FS_Plots_HGM.csv")

# CLASSIFY! ---------------------------------------------------------------

## full weixelman dataset
dat.wx<-read_csv("./data/base/2016_SN_FS_Plots_HGM.csv") %>% 
  select(PLOT:source_type, PLOTNAME2:Shape_Area) %>% 
  rename(METHOD = METHOD.x)
names(dat.wx)

## count how many w/ ELEV_MEAN > 2100
dim(dat.wx[dat.wx$ELEV_MEAN>2100,]) # 56 meadows

## bin by source_type
# dat.wx %>% group_by(source_type) %>% summarize(n(),min(ELEV_MEAN), max(ELEV_MEAN))

## make hgm classes and drop type 8 (DRY)
dat.wx$hgm_classes<-cut(dat.wx$source_type, breaks = seq(0,7,1), labels = seq(1,7))
table(dat.wx$hgm_classes) # view table of classes

## make elev classes with 2100 as cutoff
dat.wx$elev_2100<-ifelse(dat.wx$elev<2100, 0,1) # this is weixelman elev
dat.wx$elev_2100_factor<-ifelse(dat.wx$elev<2100, "<2100",">=2100")
dat.wx$elev_av_2100<-ifelse(dat.wx$ELEV_MEAN<2100, "<2100",">=2100") # this is UCDSNMC elev

table(dat.wx$elev_2100) # 59 less than 2100, 55 >2100

table(dat.wx$elev_av_2100) # 59 less than 2100, 55 >2100

## basic plot
# plot(dat.wx$elev ~ dat.wx$source_type, col=ifelse(dat.wx$elev>2100, "maroon","forestgreen"))

ggplot()+ geom_bar(data=dat.wx, aes(x=source_type, fill=elev_2100_factor))

# SAMPLE ------------------------------------------------------------------

names(dat.wx)

# select cols of interest first: 
wx.samp<-dat.wx %>% 
  select(PLOT:UCDavisObject_ID, elev:ELEV_MEAN, LAT_DD:elev_av_2100) %>% 
  group_by(source_type, elev_av_2100) %>% 
  sample_n(size = 2, replace=TRUE)

glimpse(wx.samp)
h(as.data.frame(wx.samp))


ggplot()+ geom_bar(data=wx.samp, aes(x=source_type, fill=elev_av_2100))
