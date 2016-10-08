# Subset to HGM-WaterSource Mdws for First Version of Model
# 2016-10-08
# R. Peek


# GET LIBRARIES -----------------------------------------------------------

library(rgdal)
library(maps)
library(dplyr)
library(ggplot2)

# LOAD DATA ---------------------------------------------------------------

# Full mdw dataset
mdw.sp<- readOGR("./data/shps/SNMMPC_v1_simplify10m.shp", layer="SNMMPC_v1_simplify10m", verbose = F)
proj4string(mdw.sp)

# Set Projection
wgs84<-CRS("+init=epsg:4326")
nad83<-CRS("+init=epsg:4269")

# mdws.sp<-spTransform(mdw.sp, wgs84)
# proj4string(mdw.sp)

# LOAD SELECTED MDWS ------------------------------------------------------

submdws<-read.csv("./data/water_source_MDW_selection_2016_10_07.csv")
str(submdws)

mdw_list<-as.factor(unique(submdws$UCDavisObject_ID)) # LIST OF WX MDWS
mdw_list

# Subset the full dataset extracting only the desired attributes
names(mdw.sp)
mdw.sub.sp <- subset(mdw.sp, ID %in% mdw_list)
dim(mdw.sub.sp)

proj4string(mdw.sub.sp)
plot(mdw.sub.sp, col="red", lwd=2)
map('state', 'california', add=T)
map('county', 'california',col="gray40", lty=2, add = T)
points(mdw.sub.sp@data$LONG_DD, mdw.sub.sp@data$LAT_DD, pch=21, bg="yellow", cex=2)
summary(mdw.sub.sp@data)

# add a catchment in square km instead of meters
mdw.sub.sp@data$CATCH_KM<-mdw.sub.sp@data$CATCHMENT_/1000000
mdw.sub.sp<-mdw.sub.sp[, -(15)] # remove old Catchment
mdw.sub.sp<-mdw.sub.sp[,c(1:14,28,15:27)] # remove old Catchment
names(mdw.sub.sp@data)
mdw.sub.sp@data

# Write to shp for GEE analysis
writeOGR(obj = mdw.sub.sp, dsn = "data/shps",layer = "mdws_hgm_GEE", driver = "ESRI Shapefile", overwrite_layer = TRUE)



# NEXT STEPS --------------------------------------------------------------

# Once this has been done, open shape in google earth and format...save to kml.
# Make a new fusion table and format, share (make available with link). Then can run 
# in GEE. Resave kml back so edits are retained (added HGM type).

#https://www.google.com/fusiontables/DataSource?docid=12xn4AZGlfJ5t1F7v_lUf6yrSWDMKQW1OrJS2hpXN

# 7 meadows: https://www.google.com/fusiontables/DataSource?docid=15vFFI1Y--ZqBTRX2K2tPomsR4_W_LCw7KtUIuGtq

# GEE SCRIPT --------------------------------------------------------------

# // export feature table with mean, median, stdDev values from landsat collections
# 
# // HGM Meadows Only
# // var meadows = ee.FeatureCollection("ft:12xn4AZGlfJ5t1F7v_lUf6yrSWDMKQW1OrJS2hpXN");
# 
# // subset for only Van Norden (15vFFI1Y--ZqBTRX2K2tPomsR4_W_LCw7KtUIuGtq 7 FS meadows only)
# //  .filter(ee.Filter.eq('NAME', 'Cow'));
# 
# Map.addLayer(meadows, '', 'Meadows');
# 
# // metric to export using EE 8-day composites
# var index = 'NDVI' ;// 'NDVI' or 'NDWI'
# 
# ////////////////////////////////////////////
#   //  landsat 5
# var land5 = ee.ImageCollection('LANDSAT/LT5_L1T_8DAY_' + index).filterBounds(meadows);
# // landsat 7
# var land7 = ee.ImageCollection('LANDSAT/LE7_L1T_8DAY_' + index).filterBounds(meadows);
# // landsat 8
# var land8 = ee.ImageCollection('LANDSAT/LC8_L1T_8DAY_' + index).filterBounds(meadows);
# // combine all from 5, 7, 8
# var combined = ee.ImageCollection(land5.merge(land7).merge(land8));
# 
# 
# print(combined.size());
# 
# /////////////////////////////////////////////////////
#   // summarizes region and add system id property
# var reducers = function(img){
#   var source = img.get("system:id");// get source info from img
#   var fc = meadows.map(function(feature){var fc = feature.set({source: source}); return(fc)}); // set img source by mapping over fc
#   
#   //reduce regions
#   var red = img.reduceRegions({
#     'collection': fc,
#     'reducer': ee.Reducer.mean().combine(ee.Reducer.stdDev(), "", true).combine(ee.Reducer.median(), "", true),
#     'scale': 60, //30 errors out
#     'tileScale': 8 // increase tile scale if running out of memory. 
#   });
#   
#   
#   var red_n = red.filter(ee.Filter.neq('mean', null)); //filter out any null values
#   return(red_n);
# };
# 
# // map reducers over the image collection.
# var results = ee.FeatureCollection(combined.map(reducers));
# 
# // flatten the results
# results = results.flatten();
# 
# // Make a feature without geometry and set the properties to the dictionary of means.
# var strip_geo = function(feature){
#   var new_feature = feature.select(["ID", "source", "mean", "median", "stdDev"], null , false);
#   return new_feature;
# };
# 
# // Map the strip geo function over the results.
# var selected_export = results.map(strip_geo);
# 
# // print out the first result to the console to check that it works
# print(selected_export.first());
# 
# Export.table.toDrive(selected_export, "mdws_batch_" + index);





