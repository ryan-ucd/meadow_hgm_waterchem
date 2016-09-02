# data clean up from GEE export script (https://ee-api.appspot.com/4516f8d865d540625e7581b28c8e79f5)
# data represents landsat NDWI values for a selected meadow. Data includes mean, median, variance, and standard deviation. 

require(plyr)
require(stringr)

# set digits option so sig figs don't get truncated
options(digits = 20)

# gsub strip out any characters/letters from column
clean_col <- function(col){
  as.numeric(gsub('[^-E0-9.]', '', col)) 
}

# parse date from source (example_source = 'LANDSAT/LT5_L1T_32DAY_NDWI/19840305')
parse_date <- function(string){
  parsed <- strsplit(string, '/') # split on forward slash
  YYYYMMDD <- parsed[[1]][3] # get third element aka "date"
  #date <- as.Date(YYYYMMDD, format="%Y%m%d")
  return(YYYYMMDD)
}

# clean up columns and returns tidy df
tidy_df <- function(messy_data, meadow_name){
  data <- data.frame(messy_data["source"], sapply(messy_data[, !names(messy_data) %in% c("source", ".geo")] , clean_col))
  data["date"] <- sapply(data$source, parse_date)
  data["meadow"]<-meadow_name
  return (data)
}

########################################################
# batch all meadows
# folder='raw/NDWI8DAY/'
# get_csv <- list.files(folder, pattern = "*.csv")
# 
# meadows <- c()
# NDWI8DAY <- data.frame()
# 
# for(i in 1:length(get_csv)) {
#   name <- strsplit(get_csv[i], "_")[[1]][1]
#   print(name)
#   meadows <- append(meadows, name)
#   csv<-read.csv(paste(folder,get_csv[i], sep=""), colClasses = "character")
#   meadow<-tidy_df(csv, name)
#   NDWI8DAY<-rbind(NDWI8DAY, meadow)
#   rm(csv, meadow, name)
#   }
#      
#   
     
