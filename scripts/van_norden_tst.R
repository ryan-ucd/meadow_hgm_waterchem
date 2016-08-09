#' # Using Spin with R instead of Rmd
#' R. Peek
#' html_document:
#'	theme: readable
#' 
#' Updated: `r format(Sys.time(), '%Y-%m-%d')`
#' 
#' ## Let's Write Some Notes on Meadow Modeling
#' 
#' The goal of the modeling is to identify relationships between water source 
#' (i.e., whether the meadow region in question is driven primarily *snow* or 
#' *groundwater*) and underlying hydrology/geomorphology. To identify potential
#' links, we will assess the strength of patterns associated with hydrogeomorphic
#' types (**HGM**), and water chemistry in conjunction with remote sensing data
#' from Google Earth Engine (NDVI and NDWI).
#' 
#' ## Pilot Meadow: Van Norden
#' 
#' Van Norden is a large meadow at approximately 7,000 ft. 
#' 
#' ## Load Required Packages & Data
#' First step is to load libraries and data required for analysis.
#+ load-libs, include=TRUE
suppressPackageStartupMessages({
	library(dplyr)
	library(ggplot2)
	library(lubridate)
	library(leaflet)
  library(readr)
  })

#' ## Load Data and Plot
#' Take the Van Norden Meadow and calculate DOWY variance and plot.
#+ plot-ndwi-varability, include=TRUE, eval=FALSE
source("scripts/multiplot.R")
year <- 2011
meadow <- 'Van Norden'
single_both <- NDWI8DAY[NDWI8DAY$WY==year & NDWI8DAY$meadow==meadow,]
limits <- aes(ymax = mean + std, ymin=mean - std)

p2011<- ggplot(data=single_both, aes(x=DOWY, y=mean)) + 
	geom_point()+ # add points
	geom_errorbar(limits, width=0.2) +
	scale_y_continuous( limits = c(-0.25,1), expand = c(0,0) ) +
	theme_bw() + # set to bw theme
	ylab("NDWI") + xlab("Day of Water Year") + # Set axis labels
	ggtitle("NDWI stardard deviation within Childs Meadow for 2011")  # title of graph

year <- 2014
meadow <- 'Van Norden'
single_both <- NDWI8DAY[NDWI8DAY$WY==year & NDWI8DAY$meadow==meadow,]
limits <- aes(ymax = mean + std, ymin=mean - std)

p2014<-ggplot(data=single_both, aes(x=DOWY, y=mean)) + 
	geom_point()+ # add points
	geom_errorbar(limits, width=0.2) +
	scale_y_continuous( limits = c(-0.25,1), expand = c(0,0) ) +
	theme_bw() + # set to bw theme
	ylab("NDWI") + xlab("Day of Water Year") + # Set axis labels
	ggtitle("NDWI stardard deviation within Van Norden Meadow for 2014")  # title of graph

multiplot(p2011, p2014)

#' Now the plot should show the difference between a wet year and a dry year
#' in Van Norden Meadow. What we need to do next is parse this out into proportion 
#' of HGM types, and build a model which will give us a distribution of probabilities 
#' associated with a given HGM type vs. NDVI or NDWI, during a given growing season.
#' Clear as the Little Colorado, I know.
#' 
#' ## Do some More Writing
#' 
#' ## BLah Blah Writing
#' 
#' # Did this work?
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 
#' 

