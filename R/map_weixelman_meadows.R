# weixelman meadows


# Load Libraries ----------------------------------------------------------

library(dplyr); library(readr); library(lubridate)

# READ IN DATA ------------------------------------------------------------

## Weixelman Data
dat<-read_csv("./data/base/2016 Sierra Nevada FS plots March 29 2016.csv")
str(dat)

load("./data/base/mdw_geedat2.rda")  # mdws: full google earth dataset (1424 mdws)
#str(mdws)

# need to extract the XY for meadows to plot:
mdws_xy<- mdws %>% distinct(ID) %>%
  #filter(!is.na(lat)) %>%
  as.data.frame()
dim(mdws_xy)

# Projection
WGS84 <- "+proj=longlat +ellps=WGS84 +datum=WGS84"

# mdw shapefile
library(rgdal)
mdw.sp<- readOGR("./data/base/Sierra_Nevada_MultiSource_Meadow_Polygons_Compilation_v1_simplify10m.shp", layer="Sierra_Nevada_MultiSource_Meadow_Polygons_Compilation_v1_simplify10m", verbose = F)
mdw.sp<-spTransform(mdw.sp, CRS(WGS84))
str(mdw.sp@data)
mdw.df<-as.data.frame(mdw.sp)
plot(mdw.df$LONG_DD, mdw.df$LAT_DD, pch=21, bg="forestgreen", cex=1.2)

# get centroids: can use rgeos or just use shape attributes
# library(rgeos)
# cntrds<-as.data.frame(gCentroid(mdw.sp, byid=TRUE)) # produces spatial points df
# str(cntrds)
# plot(cntrds, pch=21, bg="forestgreen", cex=1.2)
# points(mdw.sp@data$LONG_DD, mdw.sp@data$LAT_DD, pch=21, bg="gray80", cex=0.7)

# only meadows over 0.6 hectares here
load("./data/base/mdw_xydat.rda") # xydat: GE mdws dataset just XYs
str(xydat)

# MERGE WITH EXISTING MEADOWS ---------------------------------------------

# merge with all meadows
wx.mdw<-left_join(dat, mdw.df, by=c("UCDavis_Object_ID"="ID"))
dim(wx.mdw)

points(wx.mdw$LONG_DD, wx.mdw$LAT_DD, pch=16, col="yellow")

# merge with just NDVI-NDWI mdws (over 1 hectares = 2.47 acres, 1 acre=0.404686 hectares)
#wx.mdw.GE<-left_join(dat, xydat, by=c("UCDavis_Object_ID"="ID"))
#h(wx.mdw.GE)

library(ggplot2)
ggplot(data=wx.mdw)+ geom_histogram(aes(AREA_ACRE*0.404686), bins = 25)+
  xlim(c(0,25))+xlab("Hectares (threshold for GE >1.4 hec)")

# MAKE A SHINY MAP --------------------------------------------------------

library(leaflet)

m <- leaflet() %>% addTiles() %>% 
  #setView(lng = -120.8, lat = 39, zoom = 8) %>%  # set to Auburn/Colfax, zoom 5 for CA 
  addTiles(group = "OSM") %>%
  addProviderTiles("Stamen.TopOSMFeatures", group = "OSM Features") %>%
  addProviderTiles("Esri.WorldImagery", group = "ESRI Aerial") %>%
  addProviderTiles("Thunderforest.Landscape", group = "Topo") %>%
  hideGroup("OSM Features") %>% 
  

# proposed sites
addCircleMarkers(data=wx.mdw, group="Weixelman Sites",
                 lng= ~LONG_DD, lat= ~LAT_DD,
                 popup=paste0("Plot: ", wx.mdw$PLOT, "<br>", "Name: ", 
                              wx.mdw$PLOTNAME2, "<br>", "UCD_ID: ",
                              wx.mdw$UCDavis_Object_ID, "<br>", "Area_acres: ",
                              wx.mdw$AREA_ACRE, "<br>", "HUC12: ",
                              wx.mdw$HUC12, "<br>", "Elev_mean_m: ",
                              wx.mdw$ELEV_MEAN),
                 stroke=TRUE, weight=0.6,radius=10,
                 fillOpacity = 0.8, color="black",
                 fillColor = "yellow") %>%
  

  # all mdws
  addCircleMarkers(data=mdw.df, group="UCD Mdws",
                   lng= ~LONG_DD, lat= ~LAT_DD,
                   popup=paste0("UCD_ID: ", mdw.df$ID, "<br>", "Area_acres: ",
                                mdw.df$AREA_ACRE, "<br>", "HUC12: ",
                                mdw.df$HUC12, "<br>", "Ownership: ",
                                mdw.df$OWNERSHIP, "<br>", "Elev_mean_m: ",
                                mdw.df$ELEV_MEAN),
                   radius = 3,
                   #radius = ~ifelse(mdw.df$ELEV_MEAN>=2000, 3, 5),
                   fillColor= ~ifelse(mdw.df$ELEV_MEAN>=2000, "maroon", "darkgreen"),
                   stroke=TRUE, weight=0.6, fillOpacity= 0.8, color="black") %>%
  hideGroup("UCD Mdws") %>%
  
  # add a legend for all mdw points
  addLegend("bottomright", colors = c("maroon", "darkgreen"),
            labels=c(">=2000 m", "<2000 m"),
            title = "Mdw Elev Mean:",
            opacity = 0.7) %>% 
  

  # # HUC8
  # addPolygons(data = h8, group = "HUC8", 
  #             fill=FALSE, weight = 2,stroke = TRUE,
  #             opacity = 0.2, color = "darkblue",
  #             popup=paste0("HUC8: ", h8@data$HUC_8, "<br>", "Name: ",
  #                          h8@data$HU_8_NAME, "<br>", "Alt. Name: ",
  #                          h8@data$FIRST_HUC_)) %>%
  # hideGroup("HUC8") %>%
  

  # add controls for basemaps and data
  addLayersControl(
    baseGroups = c("OSM", "ESRI Aerial", "Topo"),
    overlayGroups = c("Weixelman Sites","UCD Mdws",
                      "OSM Features"),
    options = layersControlOptions(collapsed = T))


# Print Map
m
