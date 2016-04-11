# Meadows User Interface
# revised 2016-01-30
shinyUI(navbarPage(
  theme=shinytheme("cosmo"),
  title=HTML('<div><a href="http://cws.ucdavis.edu" target="_blank"><img src="./img/CWS_logoWebv2_hi_res.png" width="10%"></a></div>'),
  tabPanel("NDVI & NDWI", value="ndviwi"),
  tabPanel("Time Series", value="timeseries"),
  tabPanel("About", value="about"),
  windowTitle="UCD-Meadows",
  collapsible=TRUE,
  id="tsp",
  tags$head(tags$link(rel="stylesheet", type="text/css", href="styles.css")),
  conditionalPanel("input.tsp=='ndviwi'",
                   fluidRow(
                     column(4, h2("UCD Meadows NDVI-NDWI Plotter"), h3("Explore NDVI and NDWI data")),
                     column(8,
                            fluidRow(
                              column(4, selectInput("location", "UCD MeadowID", c("", xydat$ID), selected="", multiple=F, width="100%")),
                              column(2, selectInput("variable", "Variable", c("NDWI", "NDVI"), selectize = T, selected="NDVI",multiple = T, width="100%")),
                              column(2, selectInput("date", label="Interval",choices=c("WY","month","DOY","DOWY","jweek","wtyrwk","date", ""), selected="month"))
                            )
                     )
                   ),
                   bsTooltip("location", "Pick at Meadow using the UCD_SNMMC ID", "top", options = list(container="body")),
                   bsTooltip("variable", "Select at data type, either NDVI (Normalized Difference Vegation Index) or NDWI (Normalized Difference Water Index)", "top", options = list(container="body")),
                   bsTooltip("date", "Pick a time interval to display the data. WY = Water Year (Oct 1 to Sep 30), DOY = day of year (julian), DOWY = day of WY, jweek = julian week (Jan 1 to Dec 31), wtyrwk = Water Year weeks.", "top", options = list(container="body")),
                   fluidRow(
                     column(4, leafletOutput("Map")),
                     column(8, plotOutput("Plot")
                     )
                   ),
                   br(),
                   fluidRow(
                     column(2, actionButton("help_loc_btn", "About Meadows", class="btn-block"), br()),
                     column(2, actionButton("help_nd_btn", "About NDVI NDWI", class="btn-block")),
                     column(8, h5(HTML(paste(caption, '<a href="http://cws.ucdavis.edu" target="_blank">cws.ucdavis.edu</a>'))))
                   ),
                   bsModal("modal_loc", "Sierra Nevada Meadows (UCD_SNMMC v1)", "help_loc_btn", size="large",
                           HTML('
                                                 <p style="text-align:justify">There about over 17,000 meadows mapped in this app (using SNMMC_v1 data).
                                                 Because pixel size for LANDSAT imagery is 30 meters, meadows < 1.5 hectares were filtered out to reduce inaccurate and noisy data. </p>

                                                 <p style="text-align:justify">For more information about the Meadows dataset and the UCD Meadows Clearinghouse, please read the information found on the <code>About</code> tab at 
                                                 the top of the page for links.</p>'
                           )),
                   
                   bsModal("modal_nd", "NDVI & NDWI Data", "help_nd_btn", size="large",
                           HTML('
                                                 <p style="text-align:justify">These data are derived from remote sensing LANDSAT satellite imagery, and are the Normalized Difference Water Index (NDWI) 
                                                 and the Normalized Difference Vegation Index (NDVI), which enable identification of open water and healthy vegetation, respectively.
                                                 The Earth Engine data catalog includes a complete archive of scenes from Landsat 4, 5, 7, and 8 that have been processed by the United States Geological Survey (USGS). 
                                                 LANDSAT imagery is standardized to 30m for the bands used in this dataset. Each of the LANDSAT models has a different configuration of sensors, with the most recent satellite LANDSAT 8 which came online in 2013 having 9 bands that pick up different parts of the visible and infrared spectrum.
                                                 Earth Engine contains Landsat composites that are made from Level L1T orthorectified scenes, using the computed top-of-atmosphere reflectance. These pre-compiled composites are created by performing band math on all images in a 8-day period.
                                                 NDWI is sensitive to changes in liquid water content of vegetation canopies. It is derived from the Near-IR band and a second IR band, ???1.24??m when available and the nearest available IR band otherwise. It ranges in value from -1.0 to 1.0.
                                                 NDVI is generated from the Near-IR and Red bands of each scene, and ranges in value from -1.0 to 1.0.</p>'
                           ))
  ),
  br(),
  conditionalPanel("input.tsp=='timeseries'",
                   fluidPage(
                     h2("NDVI-NDWI by Water Year Type"),
                     sidebarLayout(
                       sidebarPanel(
                         selectInput("selected_id", "Meadow UCD-ID", choices = as.list(sites)), 
                         
                         checkboxInput(inputId = "individual_obs",
                                       label = strong("Show observations"),
                                       value = FALSE),
                         
                         checkboxInput(inputId = "wy_type",
                                       label = strong("Water Year"),
                                       value = FALSE),
                         
                         uiOutput("wycontrol")
                         
                       ), 
                       
                       mainPanel(
                         tabsetPanel(
                           tabPanel("DOWY NDWI Plot", plotOutput(outputId = "ndwi_plot", height = "400px")), 
                           tabPanel("DOWY NDVI Plot", plotOutput(outputId = "ndvi_plot", height = "400px")),
                           tabPanel("Time Series", dygraphOutput("ts_plot")),
                           tabPanel("Map", leafletOutput("mymap"))
                         ))
                     )
                   )
  ),
  br(),
  conditionalPanel("input.tsp=='about'", source("about.R",local=T)$value)
))