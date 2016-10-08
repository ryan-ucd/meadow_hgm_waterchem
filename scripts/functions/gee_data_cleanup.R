# data clean up from GEE export script (https://ee-api.appspot.com/4516f8d865d540625e7581b28c8e79f5)
# data represents landsat NDWI values for a selected meadow. Data includes mean, median, variance, and standard deviation. 

require(plyr)
require(stringr)

# set digits option so sig figs don't get truncated
options(digits = 20)

# parse date from source (example_source = 'LANDSAT/LT5_L1T_32DAY_NDWI/19840305')
parse_date <- function(string){
  parsed <- strsplit(string, "/") # split on forward slash
  YYYYMMDD <- parsed[[1]][3] # get third element aka "date"
  #date <- as.Date(YYYYMMDD, format="%Y%m%d")
  return(YYYYMMDD)
}

# parse sensor from source (example_source = 'LANDSAT/LT5_L1T_32DAY_NDWI/19840305')
parse_sensor <- function(string){
  parsed <- strsplit(string, "/") # split on forward slash
  sensor_data <- parsed[[1]][2] # get second element aka "LT5_*"
  split_sensor <- strsplit(sensor_data, "_") # "LT5" "L1T" "32Day" "NDWI
  sensor_type <- split_sensor[[1]][1] # sensor type 
  #index_type <- split_sensor[[1]][4] # index type 
  return(sensor_type)
}

# parse index type from source (example_source = 'LANDSAT/LT5_L1T_32DAY_NDWI/19840305')
parse_index <- function(string){
  parsed <- strsplit(string, "/") # split on forward slash
  sensor_data <- parsed[[1]][2] # get second element aka "LT5_*"
  split_sensor <- strsplit(sensor_data, "_") # "LT5" "L1T" "32Day" "NDWI
  #sensor_type <- split_sensor[[1]][1] # sensor type 
  index_type <- split_sensor[[1]][4] # index type 
  return(index_type)
}

# clean up columns and returns tidy df
gee_tidy_df <- function(raw){
  raw["date"] <- sapply(raw$source, parse_date)
  raw["sensor"] <- sapply(raw$source, parse_sensor)
  raw["index"] <- sapply(raw$source, parse_index)
  raw["mean"]<- as.numeric(raw$mean)
  raw["median"]<- as.numeric(raw$median)
  raw["stdDev"]<- as.numeric(raw$stdDev)
  raw <- subset(raw, select = -c(.geo)) # drop .geo column
  raw[raw==""] <- NA # add NA for blanks
  raw <- na.omit(raw) # remove anything that is blank
  return(raw)
}

### EXAMPLE

# # read in raw csv
# raw_ndwi <- read.csv(file='raw/mdws_batch_NDWI_scale100_gt10.csv',  colClasses = "character")
# raw_ndvi <- read.csv(file='raw/mdws_batch_NDVI_scale100_gt10.csv',  colClasses = "character")
# 
# # clean up df
# ndwi_data <- gee_tidy_df(raw_ndwi)
# ndvi_data <- gee_tidy_df(raw_ndvi)
# 
# # bind both df together
# data <- rbind(ndwi_data, ndvi_data)
# 
# # remove temporary data
# rm(raw_ndwi, raw_ndvi, ndvi_data, ndwi_data)
