# Make Map of Study Sites

library(rgdal)
library(readr)
library(viridis)
library(ggplot2)
library(ggsn)
library(maps)
library(mapdata)
library(ggmap)
library(dplyr)
library(googleVis)
library(ggmap)
library(cowplot)
library(ggrepel) # for labeling
library(ggsn) # for scale bar



# GET DATA AND MAKE SPATIAL -----------------------------------------------

# read in sites
sites<-read_csv(file = "data_output/wx_mdw_sub_UCID.csv") %>% as.data.frame()

sites$lon<-sites$LAT_DD # for ggmap purposes
sites$lat<-sites$LONG_DD # for ggmap purposes

# Combine sub and sub-ds for plot
sites <- sites %>% 
  mutate(hgm_class_comb2=ifelse(hgm_code=="sub-ds","sub", hgm_code),
         meadow_ID=seq(1:nrow(sites)))

# Needs to be in numeric form (use lat long columns)
sites.SP  <- SpatialPointsDataFrame(sites[,c(27,26)],sites[,-c(27,26)])
str(sites.SP) # Now is class SpatialPointsDataFrame


# REPROJECT ---------------------------------------------------------------

lats84<-CRS("+init=epsg:4326") # set the default for lat/longs
utms <- CRS("+init=epsg:32610")

proj4string(sites.SP)<-lats84 # whatever datum was WGS84
# reproject if in different Projection 'using spTransform'

# Write as geojson
# writeOGR(sites.SP, 'data_output/hgm_mdw_sites','hgm_mdw_sites', driver='GeoJSON')

# GET SHPS ----------------------------------------------------------------

# major western US rivers
rivers<- readOGR(dsn = "./data/shps", layer = "CentralValleyTribsAndRivs") # using rgdal

# we can use ogrInfo to see CRS, attributes, etc.
ogrInfo(dsn="./data/shps", layer="CentralValleyTribsAndRivs") # see shapefile info

proj4string(rivers) # check projection
rivers<-spTransform(rivers, lats84) # add the projection so it matches

# USE GGMAPS ---------------------------------------------------------

# Get the basemap
ca <- get_map(
  #location='california',
  c(lon=-120,lat=38.7),
  zoom=7,crop=T,
  scale="auto",color="bw",source="google",
  maptype="terrain") # can change to terrain

gg <- ggmap(ca, extent='panel',padding=0) 

# Get rivers layer fortified
rivers_df<-fortify(rivers) # make data spatial for ggplot

# WITH PALETTE
ggSites <- gg + 
  geom_path(data=rivers_df, aes(long, lat, group=group, fill=NULL), 
            color="#2A788EFF", alpha=0.7) + 
  geom_label_repel(data=sites, aes(x=LONG_DD, y=LAT_DD, label=meadow_ID),
                   label.size=0.1, size=3, alpha=0.8, nudge_x=0.17, 
                   nudge_y=0.1, fontface = "bold.italic", 
                   label.r=unit(0.20, "lines"))+
  geom_point(data=sites, aes(x=LONG_DD, y=LAT_DD, 
                             fill=as.factor(hgm_class_comb2)),
             show.legend=T, pch=21, size=4.5, 
             color="black",alpha=0.85) +
  theme_bw() + ylab("Latitude") + xlab("Longitude") +
  theme(
    panel.border = element_rect(colour = "black", fill=NA, size=1),
    legend.position=c(1,1),legend.justification=c(1,1),
    legend.direction="vertical",legend.text=element_text(size=8),
    legend.title=element_text(size=8, face="bold"),
    legend.key=element_blank(),
    legend.box.just = c("top"), 
    legend.background = element_rect(fill=alpha('white', 0.6), 
                                     colour = "gray30")) +
  scale_fill_viridis("HGM Type",option = "C", discrete = T)
print(ggSites)

# ADD NORTH ARROW AND SCALE BAR -------------------------------------------


finalmap <- ggSites + 
  # using the ggmap bounding box to get the extent for the scale bar
  scalebar(x.min = attr(ca, "bb")[[2]], 
           y.min=attr(ca, "bb")[[1]], 
           x.max =attr(ca, "bb")[[4]], 
           y.max=attr(ca, "bb")[[3]], 
           dist = 75, anchor = c(x=-122.7, y=36.3), 
           dd2km = T, model = 'WGS84', location = "topleft", st.size = 3.3, st.dist = 0.02)

finalmap

# Issues with adding a North Arrow: need to use north2 with empty ggplot() calls, otherwise north()...this works but can't save it as a ggplot object
#north2(finalmap, x = 0.85, y=0.15, scale = 0.08, symbol = 12)

# save plot
ggsave(filename = "./fig_output/site_map_hgm_mdws.png", width = 6, height = 6, units = "in", dpi = 300)
ggsave(filename = "./fig_output/site_map_hgm_mdws.svg", width = 6, height = 6, units = "in", dpi = 300)
ggsave(filename = "./fig_output/site_map_hgm_mdws2.pdf", width = 9, height = 7, units = "in")

# ADD OVERVIEW MAP --------------------------------------------------------

# start by plotting the state/county
CA<-map_data("state",region=c('california'));
CAcounty<-map_data("county",region=c('CA'),boundary=FALSE,lty=3, col="gray30",add=TRUE)

# basic map
overviewmap<-ggplot() + 
  geom_polygon(data=CA, aes(long, lat, group=group), color="black", fill=NA) +
  geom_polygon(data=CAcounty, aes(long, lat, group=group), 
               color="gray50", fill=NA, linetype=3)+
  geom_point(data=sites, aes(x=LONG_DD, y=LAT_DD), pch=23, bg="gray40", col="gray80")+
  coord_equal()+
  theme(plot.background =
          element_rect(fill = "white", linetype = 1,
                       size = 0.3, colour = "black"),
        axis.line=element_blank(),
        axis.text.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        legend.position="none")
overviewmap

# Use cowplot
library(cowplot)
#draw_plot(x: The x location of the lower left corner of the plot.
# y: The y location of the lower left corner of the plot.
# width, height: the width and the height of the plot)

ggdraw() + 
  draw_plot(finalmap, 0, 0, 1, 1) +
  draw_plot(overviewmap, 0.72,0.72,0.25,0.25)

ggsave(filename = "./figs/site_map_inset.png", width = 6, height = 6, units = "in", dpi = 300)
ggsave(filename = "./figs/site_map_inset.pdf", width = 6, height = 6, units = "in", dpi = 300)
ggsave(filename = "./figs/site_map_inset.svg", width = 6, height = 6, units="in", dpi=300)