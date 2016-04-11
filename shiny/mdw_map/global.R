## This loads all data and packages required for the app
## updated 2016-01-30
## See template used here: http://shiny.snap.uaf.edu/cc4liteFinal/ 
# LOAD PACKAGES -----------------------------------------------------------

lapply(list("shiny", "shinythemes", "shinyBS", "rCharts", "plyr", 
            "leaflet", "htmltools", "magrittr", "ggplot2", "dygraphs", 
            "xts", "maps", "sp", "rgdal", "scales", "geojsonio"), 
       function(x) library(x, character.only=T))

lapply(list.files(path = paste0(getwd(),"/data"),pattern="^mdw_.*\\.rda$", full.names=T), load, envir=.GlobalEnv)

caption <- 'These data are based on 8 day composites of NDVI and NDWI. They were pulled from Google Earth Imagery using (30 m LANDSAT).'

# list of all sites 
sites <- sort(unique(mdws$ID))

# LOAD SPATIAL DATA -------------------------------------------------------

## read in MEADOW POLYGON geodata from shapefile
# mdwGIS <- readOGR("geodata/SNMdws_polys_data_v2.shp", layer="SNMdws_polys_data_v2")
# ogrInfo("geodata/SNMdws_polys_data_v2.shp", layer="SNMdws_polys_data_v2")
# summary(mdwGIS)
# mdwGIS<- spTransform(mdwGIS, CRS("+proj=longlat +datum=WGS84"))

## read in DWR hydroregions
# dwr<- readOGR("geodata/DWR_hydroregions_utm11.shp", layer="DWR_hydroregions_utm11")
# ogrInfo("geodata/DWR_hydroregions_utm11.shp", layer="DWR_hydroregions_utm11")
# dwr<-spTransform(dwr, CRS("+proj=longlat +datum=WGS84"))

## READING IN GEOJSON using 'rgdal: readOGR'
dwr<-readOGR(dsn = "DWR_hydro.geojson", "OGRGeoJSON") # reads in as SP.poly

## READING IN GEOJSON using 'geojsonio: geojson_read'
mdwJSON <- geojson_read("SNMMPC.geojson", what="sp") # reads as Spatial Polygons Dataframe

## READING IN GEOGJSON using 'readLines'
# mdwGIS <- readLines("geodata/SNMMPC.geojson") %>% paste(collapse = "\n") # Fast flat format, can't extract for popup 


# test map
# (map <- leaflet() %>% addTiles(group = "OSM") %>% fitBounds(-121.34153, 35.77856, -118.14748, 40.26938)%>% 
#   #addGeoJSON(mdwGIS, weight = 4, fill = TRUE, color="yellow",fillColor = "yellow2",fillOpacity = 0.5) %>%
#   addPolygons(data=dwr, group = "DWR Hydrologic Regions", fill=FALSE, weight = 3,stroke = TRUE,
#               opacity = 0.3, color = "blue",
#               popup=htmlEscape(dwr2@data$HR_NAME)) %>% 
#   addPolygons(data=mdwJSON, group="Mdws", weight=4, fill=T, color="yellow", fillColor="yellow2", fillOpacity=0.5,
#               opacity=0.3, popup=paste0(mdwJSON@data$ID, "<br>","Elev_mean (m): ", mdwJSON@data$ELEV_MEAN)))



# rCharts -----------------------------------------------------------------
# 
# require(rCharts)
# require(dplyr)
# dat<-filter(mdws, ID=="UCDSNM000008", wtyr>=2000)
# dat$dates<-as.character(dat$date)
# 
# m<-rPlot(mean ~ dates, data = dat, type = 'point', 
#             size = list(const = 2.4), color = "index")
# m$show(cdn=TRUE)
# 
# np<-nPlot(mean ~ dates, group="wtyr", data= dat, type="multiBarChart")
# np$show(cdn=TRUE)
# 
# h1 <- hPlot(x = "dates", y = "mean", data = dat, 
#             type = c("scatter", "line", "bar"), group = "index", size="mean")
# h1$show(cdn=TRUE)
# 
# h1 <- hPlot(x = "wtyrwk", y = "mean", data = dat, 
#             type = c("scatter", "bar"), group = "index", size=0.5)
# h1$show(cdn=TRUE)
# 
# m1<-rPlot(x="dates", y="mean", color='index', data = dat, type = c('line'))
# m1$set(pointSize=0.8, lineWidth=1.1)
# m1$guides(y = list(min = 0, max=1.0, titles=""))
# m1$set(title = "Comparison of NDVI and NDWI")
# m1$show(cdn=TRUE)

# p <- Highcharts$new()
# p$colors(c("#666666", colorRampPalette(c("darkgreen", "yellow", "orange", "orangered"))))
# p$title(text=paste("Remote Sensing Data: ", input$variable, "for", input$location), style=list(color="#000000"))
# p$subtitle(text=paste("at a ", input$date, " time scale"), style=list(color="gray"))
# #p$legend(verticalAlign="top", y=50, itemStyle=list(color="gray"))
# #p$xAxis(categories=month.abb)
# #p$yAxis(title=list(text=paste0(input$variable, " (", Unit(), ")"), style=list(color="gray")), min=Min())
# d <- mdws[,c(1,3,7,35:39)]
# d <- filter(d, ID=="UCDSNM000008")
# 
# p1 <- rPlot(mean ~ wtyrwk, data=d, group="wtyr", color="index",  type = "point")
# 
# # make other layer
# d2 <- d %>% 
#   group_by(ID, wtyr, index) %>% summarize(mean=mean(mean)) %>% as.data.frame()
# 
# p1$layer(data = d2, type = 'line', 
#          color = list(const = 'blue'), copy_layer = T, tooltip = NULL)
# 
# p1

# Add axis labels and format the tooltip
# tfrPlot$yAxis(axisLabel = "NDVI", width = 62)
# 
# tfrPlot$xAxis(axisLabel = "Month")
# 
# tfrPlot$chart(tooltipContent = "#! function(key, x, y){
#               return '<h3>' + key + '</h3>' + 
#               '<p>' + y + ' in ' + x + '</p>'
#               } !#")

# SHINY PLOT --------------------------------------------------------------

# library(shiny)
# shinyApp(
#   ui = fluidPage(
#     h3("NDVI-NDWI"),
#     inputPanel(
#       selectInput("data", label="Data Interval",
#                   choices=c("wtyr","month","jweek","wtyrwk","date"), 
#                   selected="month"),
#       selectInput("mdw", label="Pick a Meadow", choices=unique(comb$ID))
#     ),
#     mainPanel(
#       plotOutput("Plot", width = "800px", height="500px")
#     )
#   ),
#   
#   server = function(input, output) {
#     
#     output$Plot<-renderPlot({
#       df<-reactive({comb[comb$siteID==input$mdw,]})
#       print(ggplot() + geom_smooth(data=comb[comb$ID==input$mdw,], 
#                                    aes_string(x=input$data, y="mean", color="index"))+
#               geom_point(data=comb[comb$ID==input$mdw,], 
#                          aes_string(x=input$data, y="mean", color="index"))+theme_bw()
#       )
#     })
#   }
# )

# LEAFLET MAP -------------------------------------------------------------
# # set basemap to mean of all points
# m <- leaflet(data = xydat) %>%  
#   clearBounds()  # clear bounds to range of data
# #setView(lng = -119.7, lat = 38.38, zoom = 6) # set to mean of totals
# 
# m %>% 
#   # set basemaps
#   addTiles(group = "OSM") %>%
#   addProviderTiles("Stamen.Toner", group = "Toner") %>%
#   
#   # set map view and zoom
#   # setView(lng=-120, lat=39, zoom=5) %>%
#   
#   # add data
#   addCircleMarkers(data = xydat, group = "Meadows", 
#                    lng = ~lon, lat = ~lat, 
#                    color= ~pals(FLOW_SLOPE),
#                    #radius=~ifelse(FLOW_SLOPE>=0.01, 10, 6),
#                    radius=6,
#                    #stroke=TRUE,
#                    fillOpacity=0.5,
#                    popup=htmlEscape(paste0("Flow Slope: ", as.character(round(xydat$FLOW_SLOPE,digits = 2))))) %>% 
#   
#   addMarkers(data = xydat, group = "MeadowsMarks", 
#              lng = ~lon, lat = ~lat, 
#              popup=htmlEscape(paste0("Flow Slope: ", as.character(round(xydat$FLOW_SLOPE,digits = 2))))) %>% 
#   
#   
#   # add controls for basemaps and data
#   addLayersControl(
#     baseGroups = c("OSM", "Toner"),
#     overlayGroups = c("Meadows", "MeadowsMarks"),
#     options = layersControlOptions(collapsed = FALSE))
# 
