#ndwi variability for a single meadow and year

#plot ndwi varability each meadow

require(ggplot2)
source("scripts/multiplot.R")

year <- 2011
meadow <- 'Childs'
single_both <- NDWI8DAY[NDWI8DAY$WY==year & NDWI8DAY$meadow==meadow,]


# DOWY variance
limits <- aes(ymax = mean + std, ymin=mean - std)

p2011<- ggplot(data=single_both, aes(x=DOWY, y=mean)) + 
  geom_point()+ # add points
  geom_errorbar(limits, width=0.2) +
  scale_y_continuous( limits = c(-0.25,1), expand = c(0,0) ) +
  theme_bw() + # set to bw theme
  ylab("NDWI") + xlab("Day of Water Year") + # Set axis labels
  ggtitle("NDWI stardard deviation within Childs Meadow for 2011")  # title of graph

year <- 2014
meadow <- 'Childs'
single_both <- NDWI8DAY[NDWI8DAY$WY==year & NDWI8DAY$meadow==meadow,]


# DOWY variance
limits <- aes(ymax = mean + std, ymin=mean - std)

p2014<-ggplot(data=single_both, aes(x=DOWY, y=mean)) + 
  geom_point()+ # add points
  geom_errorbar(limits, width=0.2) +
  scale_y_continuous( limits = c(-0.25,1), expand = c(0,0) ) +
  theme_bw() + # set to bw theme
  ylab("NDWI") + xlab("Day of Water Year") + # Set axis labels
  ggtitle("NDWI stardard deviation within Childs Meadow for 2014")  # title of graph

multiplot(p2011, p2014)