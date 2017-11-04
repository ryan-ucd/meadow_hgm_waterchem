## CDEC SNOW PLOTTING

library(sharpshootR)  # CDEC.snow.courses, CDECquery, CDECsnowQuery
library(ggplot2)
library(stringr)

# GET DATA AND PREP -------------------------------------------------------

# data(CDEC.snow.courses)
# snw<-CDEC.snow.courses
# str(snw)
# # snw$id<-as.factor(snw$id)
# snw$latitude<-as.numeric(snw$latitude)
# snw$longitude<-as.numeric(snw$longitude)*-1
# snw$apr1avg_in<-snw$april.1.Avg.inches
# snw<-select(snw, course_number, id, elev_feet:longitude,apr1avg_in)
# str(snw)

# CDEC snow data, historical to now for all Stations
# snowhist<-read.csv("./data/base/snow/cdec_all_snow.csv", stringsAsFactors = FALSE)
# h(snowhist)
# snowhist$Datetime<-lubridate::mdy(snowhist$Datetime)
# snowhist$Snow<-as.numeric(snowhist$Snow)
# str(snowhist)
# snowhist<-select(snowhist, Snow:Measure,Datetime:Month)
# 
# dfsnw<-left_join(snowhist, snw, by = c("Station"="id"))
# s(dfsnw)
# dfsnw$Station<-as.factor(dfsnw$Station)
# dfsnw$Measure<-as.factor(dfsnw$Measure)

# save(dfsnw, file="./data/processed/cdec_snow_historical_all.RData")


# LOAD RDATA --------------------------------------------------------------

load("./data_output/cdec_snow_historical_all.RData")

library(dplyr)
# filter to single measurement type
dfsnw1<-filter(dfsnw, Measure=="SNOW WC (INCHES)", Year>1983, Month>=2, Month<5) %>%
  group_by(course_number,Station, Year,latitude,longitude) %>% 
  summarize(snow_cm=2.54*mean(Snow,na.rm=T))

s(dfsnw1)
table(dfsnw1$Year)

# SPATIAL PLOTS -----------------------------------------------------------

## Set the SNOW INCHES Palette
library(RColorBrewer)
breaks<-(c(0,25,50,75,100,125,150,175,200)) # for color scale
palette<-c("darkred","red4","red2","lightcoral","lightpink","limegreen","green2","forestgreen")
paletteBlu<-brewer.pal(9,name="Blues")
paletteGnBu<-brewer.pal(9,name="GnBu")
paletteRdBu<-brewer.pal(9,name="RdBu")

# display.brewer.all() # see the diff palettes

library(googleVis)
library(ggmap)

# Get the basemap
ca <- get_map(
  #location='california',
  c(lon=-120,lat=38.6),
  zoom=7,crop=T,
  scale="auto",color="bw",source="google",
  maptype="terrain") # can change to terrain

gg <- ggmap(ca, extent='device',padding=0) # call the basemap, also: extent="panel",fullpage=TRUE

# PLOT SIMPLE
ggCA <- gg + geom_point(data=dfsnw1[dfsnw1$Year==1984,], 
                        aes(x=longitude, y=latitude, size=snow_cm),
                        show.legend=T, pch=21, color="gray30",
                        fill="blue2", alpha=0.6)+
  theme_bw() + facet_wrap(~Year, ncol=1)
print(ggCA) 

# WITH PALETTE
ggSnw <- gg + geom_point(data=dfsnw1[dfsnw1$Year==1984,], 
                        aes(x=longitude, y=latitude,size=snow_cm, fill=snow_cm),
                        show_guide=F, pch=21)+ theme_bw() + 
  #facet_wrap(~Year+Month, ncol=2)+
  #facet_wrap(~Year, ncol=1)+
  #theme(strip.text.x = element_text(face = "bold.italic",size = 7))+
  # scale_fill_gradientn("Snow Depth (cm)",colours=brewer.pal(9,name="RdBu"),
  # breaks=breaks,values=breaks, rescaler = function(x, ...) x, 
  # oob = identity,limits=range(breaks), space="Lab")
  scale_fill_gradientn("Snow Depth (cm)",colours=paletteRdBu,
                       breaks=breaks,values=breaks, rescaler = function(x, ...) x, 
                       oob = identity,limits=range(breaks), space="Lab")

ggSnw

## NOW LOOP!

# LOOP IT! ----------------------------------------------------------------
# i<-2011

table(dfsnw1$Year)
j=4

for (i in c(1984:1994)){
  # for (j in c(2:4)){
    
    gg + geom_point(data=dfsnw1[dfsnw1$Year==i,], 
                    aes(x=longitude, y=latitude, fill=snow_cm, size=snow_cm),
                    show.legend = F, pch=21,color="gray30")+ theme_bw()+
      #ggtitle(paste0("Meadows (Sac. Hydro. Unit: DWR): Max NDVI - ", i))+
      theme(axis.text.x = element_text(angle = 60, vjust=0.15, size=9))+
      #facet_wrap(.~Year, ncol=1) +
      scale_fill_gradientn("Snow Depth",colours=brewer.pal(8,name="RdBu"),breaks=breaks)
    
  
  print(paste0("saving plot ", i, "-Apr"))
    ggsave(filename = paste0("./docs/looped/hgm_snowcdec_",i,"_full.png"),width = 11,height=8.5,dpi = 150)
  # }
}

