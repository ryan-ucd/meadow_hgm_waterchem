# Server Side: Updated 2016-01-30

shinyServer(function(input, output, session){
  
  observeEvent(input$location, {
    x <- input$location
    if(!is.null(x) && x!=""){
      sink("locationLog.txt", append=TRUE, split=FALSE)
      cat(paste0(x, "\n"))
      sink()
    }
  })
  
#   mdwInput <- reactive({
#     selected<- subset(mdwGIS, ID %in% input$location)
#   })
  
  output$Map <- renderLeaflet({
    
    leaflet() %>% 
      addProviderTiles("Esri.WorldTopoMap", group = "Topo") %>%
      addProviderTiles("Esri.WorldImagery", group="Aerial") %>%
      addProviderTiles("Stamen.TopOSMFeatures", group = "Topo Features") %>%
      hideGroup(group = "Topo Features") %>% 
      setView(lng=-120, lat=39, zoom=5) %>%
      
    
      addCircleMarkers(data=xydat, group="Meadows", radius = 4, 
                       color = "black", fill = T, stroke=F, 
                       fillColor = "forestgreen", 
                       fillOpacity=0.8, layerId = ~ID, 
                       popup=htmlEscape(paste0("ID:" , xydat$ID)),
                       clusterOptions = markerClusterOptions(),
                       clusterId = "MdwsCluster") %>% 
      
      # add the DWR Hydro Regions
      # addPolygons(data = dwr, group = "DWR Hydrologic Regions", 
      #             fill=FALSE, weight = 3,stroke = TRUE,
      #             opacity = 0.3, color = "blue",
      #             popup=htmlEscape(dwr@data$HR_NAME)) %>%
      
      # # add the Meadow Polygons
      # addPolygons(data=mdwJSON, group="Mdw Polys", weight=4, fill=T, color="yellow", fillColor="yellow2", fillOpacity=0.4,
      #             opacity=0.3, popup=paste0(mdwJSON@data$ID, "<br>","Elev_mean (m): ", mdwJSON@data$ELEV_MEAN, "<br>",
      #                                       "Dom. Rock Type: ", mdwJSON@data$DOM_ROCKTY)) %>% 
      
      #addPolygons(data=mdwInput(), weight=4, opacity=0.5, color="yellow", fill=FALSE, group = "MdwPolygons") %>% 
      
      addLayersControl(
        baseGroups = c("Topo","Aerial"),
        overlayGroups = c("Topo Features", "Meadows"),
        options = layersControlOptions(collapsed = T))
  })
  
  observeEvent(input$Map_marker_click, {
    p <- input$Map_marker_click
    if(!is.null(p$id)){
      if(is.null(input$location)) updateSelectInput(session, "location", selected=p$id)
      if(!is.null(input$location) && input$location!=p$id) updateSelectInput(session, "location", selected=p$id)
    }
  })
  
  observeEvent(input$Map_marker_click, {
    p <- input$Map_marker_click
    if(p$id=="Selected"){
      leafletProxy("Map") %>% removeMarker(layerId="Selected") 
    } else {
      leafletProxy("Map") %>% setView(lng=p$lng, lat=p$lat, input$Map_zoom) %>% 
        addCircleMarkers(p$lng, p$lat, radius=10, color="black", fillColor="orange", fillOpacity=1, opacity=1, stroke=TRUE, layerId="Selected")
    }
  })
  
  observeEvent(input$location, {
    p <- input$Map_marker_click
    p2 <- subset(xydat, ID==input$location)
    if(nrow(p2)==0){
      leafletProxy("Map") %>% removeMarker(layerId="Selected") %>% removeShape(layerId="MdwPolygons")
    } else {
      leafletProxy("Map") %>% setView(lng=p2$lon, lat=p2$lat, input$Map_zoom) %>% 
        addCircleMarkers(p2$lon, p2$lat, radius=10, color="black", fillColor="orange", fillOpacity=1, opacity=1, stroke=TRUE, layerId="Selected")
    }
  })
  
  
  Colors <- reactive({ 
    if(input$variable=="NDVI") 
      c("#666666", colorRampPalette(c("darkgreen", "yellow", "orange", "orangered")))
    else c("#666666", colorRampPalette(c("aquamarine", "dodgerblue4")))
  })
  

  mdw_loc <- reactive({ subset(mdws, ID==input$location) })
  mdw_var <- reactive({ subset(mdw_loc(), Var==input$variable) })
  
  d0 <- reactive({
    if(input$variable=="NDVI" | input$variable=="NDWI" ){
      if(!exists("mdws")){
        prog <- Progress$new(session, min=0, max=1)
        on.exit(prog$close())
        prog$set(message="Loading data...", value=1)
        load(paste0("mdw_geedat.rda"), envir=.GlobalEnv)
      }
      return(mdws)
    }
  })
  d1_loc <- reactive({ subset(d0(), ID==input$location) })
  d2_var <- reactive({ subset(d1_loc(), index==input$variable) })

  output$Plot<-renderPlot({
    dfplot<-d2_var
    print(ggplot() + geom_smooth(data=dfplot(), 
                                 aes_string(x=input$date, y="mean", color="index"))+
            geom_point(data=dfplot(), 
                       aes_string(x=input$date, y="mean", color="index"))+theme_bw())
  })
  

  # data 
  #wytype <- read_csv('wy_type.csv')
  #mdws2<-inner_join(x = mdws, y = wytype[,c(1,6,11)], by=c("wtyr"="WY") )
  #mdws<-mdws2
  #save(mdws, file="mdw_geedat2.rda")
  
  # read in data as df
  df <- mdws
  
  dataInput <- reactive({
    # subset mdws using unique site identifer
    selected<- subset(mdwJSON, ID %in% input$selected_id)
    })
  
  # construct leaflet map
  output$mymap <- renderLeaflet({
    leaflet() %>% 
      addProviderTiles("Esri.WorldImagery") %>%
      addPolygons(data=dataInput(), weight=4, fill=FALSE) #add polygon
  })
  
  
 # water year plots using NDWI 
  plot_NDWI <- function (data, meadow){
    df<- subset(data, ID %in% meadow & index=="NDWI")
    
    # subset data base on water year types selected in UI
    if (input$wy_type == TRUE)
    { df<- df[df$SAC %in% input$types, ]}
    
    # inital plot of DOWY and NDWI
    p<-ggplot(data=df, aes(x=DOWY, y=mean)) +
      #geom_point() + # add points
      stat_smooth(se=FALSE,  size=1.2) +
      theme_bw() + # set to bw theme
      ylab("NDWI") +
      xlab("Day of Water Year (1984-2014)") + # Set axis labels
      #ggtitle(meadow) + # title of graph
      scale_color_brewer(palette="Set2") # change colors
    
    # add observations if checked in ui
    if (input$individual_obs){
      p<- p + geom_point() # add points
    }
    
    # add water year type if checked in UI
    if (input$wy_type){
      p<- p + aes(group=SAC, colour=SAC) # add points
    }
    
    return(p)
  }
  
  plot_NDVI <- function (data, meadow){
    df<- subset(data, ID %in% meadow & index=="NDVI")
    
    # subset data based on water year types selected in UI
    if (input$wy_type == TRUE)
    { df<- df[df$SAC %in% input$types, ]}
    
    # inital plot of DOWY and NDVI
    p<-ggplot(data=df, aes(x=DOWY, y=mean)) +
      stat_smooth(se=FALSE,  size=1.2) +
      theme_bw() + 
      ylab("NDVI") +
      xlab("Day of Water Year (1984-2014)") + 
      scale_color_brewer(palette="Set2") # change colors
    
    # add observations if checked in ui
    if (input$individual_obs){
      p<- p + geom_point() # add points
    }
    
    # add water year type if checked in UI
    if (input$wy_type){
      p<- p + aes(group=SAC, colour=SAC) # add points
    }
    
    return(p)
  }
  
  
  output$ndwi_plot <- renderPlot({plot_NDWI(df,input$selected_id)})
  
  output$ndvi_plot <- renderPlot({plot_NDVI(df,input$selected_id)})
  
  # add dynamic controls for water year
  output$wycontrol <-renderUI({
    if (input$wy_type == TRUE){
      choices = c("AN", "BN", "W", "D", "C")
      checkboxGroupInput(inputId="types", label=strong("Water Year Types"), choices, selected=choices, inline=TRUE)
    }
  })
  
  # interactive TS
  plot_ts <- function(data, meadow){
    df <- subset(data, ID %in% meadow & index=="NDVI")
    df["date"] <- as.Date(as.character(df$date),format="%Y-%m-%d")
    x <- xts(df$mean,df$date)
    g <- dygraph(x, ylab="NDVI")  %>% dyRangeSelector()
    g <- dyOptions(g, strokeWidth = 0.0, drawPoints = TRUE, pointSize=4)
    return(g)
  }
  
  output$ts_plot <- renderDygraph({plot_ts(df,input$selected_id)})
  
})