#water year times by year

# sacramento

###### http://cdec.water.ca.gov/cgi-progs/iodir/WSIHIST
#WY      Water year (Oct 1 - Sep 30)
#W       Wet year type
#AN      Above normal year type
#BN      Below normal year type
#D       Dry year type
#C       Critical year type

wy <- read.csv("./data/wy_type.csv")

# add water year as column to df choose either SAC or SJ as region
add_wy_type<-function(df, wy_df, region){
  vars <- c("WY", region)
  wy_region <- wy[vars]
  names(wy_region)[names(wy_region)==region] <- "WYTYPE"
  df<-merge(df, wy_region, by="WY")
  return(df)
}


# need to separate SAC and SJ WY regions 
SJ <- c("BullCreek", "Shorthair", "HerringCreek")
SAC <- c("van_norden", "Carter", "Childs", "Cow")


NDWI8DAY_SJ <- NDWI8DAY[NDWI8DAY$meadow %in% SJ,]
NDWI8DAY_SAC <- NDWI8DAY[NDWI8DAY$meadow %in% SAC,]

NDWI8DAY_SJ <- add_wy_type(NDWI8DAY_SJ, wy, "SJ")
NDWI8DAY_SAC <- add_wy_type(NDWI8DAY_SAC, wy, "SAC")

NDWI8DAY_WY <- rbind(NDWI8DAY_SJ, NDWI8DAY_SAC)