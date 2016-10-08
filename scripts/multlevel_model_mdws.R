## Modeling Meadow Resiliency via Groundwater/Surfacewater
## Use NDVI/NDWI to assess whether meadows are sensitive to annual/seasonal 
## changes in water via snowmelt & ppt.
## Using bayesian mixed-models from RSTAN and rethinking packages.

## 2015-Dec. 
## Ryan Peek

# Load Packages -----------------------------------------------------------
library(ggplot2)
library(dplyr)
library(readr)
library(lubridate)
library(stringr)
library(rethinking)

# LOAD GEE MEADOW DATA ----------------------------------------------------

mdws<-read_rds(path = "./raw/UCD_mdws_gt10_scaled100m_SNMMPC.rds")

mdws$date<-ymd(mdws$date)
mdws$wtyr<-wtr_yr(mdws$date)
mdws$month<-month(mdws$date)
mdws$jweek<-week(mdws$date)
# add water yr week
mdws$wtyrwk<-ifelse(mdws$jweek>39, mdws$jweek-40, mdws$jweek + 13)
mdws$hect<-mdws$AREA_ACRE*0.404686
str(mdws)
summary(mdws$hect)
summary(mdws$wtyrwk)
ht(mdws[,c("date","jweek","month","wtyrwk")])

load(file = "data/mdw_geedat2.rda")


# GGPLOT ------------------------------------------------------------------

useID<-"UCDSNM000008"
ggplot() + geom_smooth(data=mdws[mdws$ID==useID,], aes(x=jweek, y=mean, color=index))+
  geom_point(data=mdws[mdws$ID==useID,], aes(x=jweek, y=mean, color=index))+theme_bw()

ggplot() + geom_smooth(data=mdws[mdws$ID==useID,], aes(x=wtyrwk, y=mean, color=index))+
  geom_point(data=mdws[mdws$ID==useID,], aes(x=wtyrwk, y=mean, color=index))+theme_bw()

ggplot() + geom_smooth(data=mdws[mdws$ID==useID,], aes(x=wtyr, y=mean, color=index))+
  geom_point(data=mdws[mdws$ID==useID,], aes(x=wtyr, y=mean, color=index))+theme_bw()


# SHINY PLOT --------------------------------------------------------------

library(shiny)
shinyApp(
  ui = fluidPage(
    h3("NDVI-NDWI"),
    inputPanel(
      selectInput("data", label="Data Interval",
                  choices=c("wtyr","month","jweek","wtyrwk","date"), 
                  selected="month"),
      selectInput("mdw", label="Pick a Meadow", choices=unique(mdws$ID))
    ),
    mainPanel(
      plotOutput("Plot", width = "800px", height="500px")
    )
  ),
  
  server = function(input, output) {
    
    output$Plot<-renderPlot({
      df<-reactive({mdws[mdws$ID==input$mdw,]})
      print(ggplot() + geom_smooth(data=mdws[mdws$ID==input$mdw,], 
                                   aes_string(x=input$data, y="mean", color="index"))+
        geom_point(data=mdws[mdws$ID==input$mdw,], 
                   aes_string(x=input$data, y="mean", color="index"))+theme_bw()
      )
    })
  }
)

# PREP MODEL --------------------------------------------------------------

# filter to meadows >=10 hec & HGM type: NDVI
df<-filter(mdws, hect>=10, HGM_TYPE=!is.na(HGM_TYPE), index=="NDVI")
length(unique(df$ID))# 146 meadows

dfsum<-df %>% 
  group_by(wtyr) %>% 
  summarize("tot.mdws"=n_distinct(ID),
            "tot.H12"=n_distinct(HUC12))
h(dfsum)

# take random subsample of meadows
subsample<-sample(df$ID, size = 21, replace = F)

# filter to subsample
dff<-filter(df, ID %in% subsample)
length(unique(dff$ID))# 146 meadows

dfsum<-dff %>% 
  group_by(wtyr) %>% 
  summarize("tot.mdws"=n_distinct(ID),
            "tot.H12"=n_distinct(HUC12))
h(dfsum)


# Scale and center data:
dff$mean_s<- (dff$mean - mean(dff$mean)) / sd(dff$mean) # wait til filtered for NDVI/NDWI
dff$lat_s<- (dff$LAT_DD - mean(dff$LAT_DD)) / sd(dff$LAT_DD)
dff$name_id<-coerce_index(dff$ID)
dff$wtyr_seq<-coerce_index(dff$wtyr)
dff$wtyrlag1<-dff$wtyr-1 # lag 1 year
dff$h8<- str_sub(dff$HUC12,1,8)
dff$h8_num<- coerce_index(as.factor(dff$h8)) # shift to numeric
dff$hgm_num<- coerce_index(as.factor(dff$HGM_TYPE)) # shift to numeric
dff$edgecomplex_s<-(dff$EDGE_COMPL - mean(dff$EDGE_COMPL)) / sd(dff$EDGE_COMPL)
dff$domrock<-coerce_index(as.factor(dff$DOM_ROCKTY)) # shift factor to numeric
dff$vegmaj<-coerce_index(as.factor(dff$VEG_MAJORI)) # shift factor to numeric
dff$kf_s<-(dff$Kf - mean(dff$Kf)) / sd(dff$Kf)
dff$claytotR_s<-(dff$ClayTot_r - mean(dff$ClayTot_r)) / sd(dff$ClayTot_r)
dff$soilcomp<-coerce_index(as.factor(dff$COMP_NAME)) # shift factor to numeric
dff$flow_slope_s<-(dff$FLOW_SLOPE - mean(dff$FLOW_SLOPE)) / sd(dff$FLOW_SLOPE)
dff$elevmean_s<- (dff$ELEV_MEAN - mean(dff$ELEV_MEAN)) / sd(dff$ELEV_MEAN)
dff$catch_s<- (dff$CATCHMENT_ - mean(dff$CATCHMENT_)) / sd(dff$CATCHMENT_)
dff$shapearea_s<- (dff$Shape_Area - mean(dff$Shape_Area)) / sd(dff$Shape_Area)
dff$flowrange_s<- (dff$FLOW_RANGE - mean(dff$FLOW_RANGE))/ sd(dff$FLOW_RANGE)

names(dff)
ndvi<-select(dff, ID,name_id, mean,mean_s, wtyr_seq, wtyr:hect, h8_num:flowrange_s)
#ndwi<-select(dff, ID, mean, wtyr:flowrange_s, -h8)
names(ndvi)
summary(ndvi)

# MODEL NOTES ------------------------------------------------------------------

# Notes from Richard...need to deal with temporal autocorrelation, i.e.,
# does previous year affect current year? Which variables interact? 
# This could be due to soils or underlying geology, some regions/meadows may
# respond to lag more than others.
# Also add covariance distance matrix for meadows to see if spatial pattern exists
# this may highlight the watershed/catchment scale.

# FIXED EFFECTS -----------------------------------------------------------
names(ndvi)

# rename outcomes
dlist <- list(
  name=ndvi$name_id,
  wtyr=ndvi$wtyr,
  wtyr_seq=ndvi$wtyr_seq,
  wtyrwk=ndvi$wtyrwk,
  h8 = ndvi$h8_num,
  ndvi = ndvi$mean, # unscaled
  ndvi_s = ndvi$mean_s,
  hgm = ndvi$hgm_num, # hgm ID
  hect=ndvi$hect,
  kf = ndvi$kf_s,
  clay=ndvi$claytotR_s,
  domrock=ndvi$domrock,
  soil=ndvi$soilcomp,
  flowslope=ndvi$flow_slope_s,
  edge = ndvi$edgecomplex_s,
  catcharea = ndvi$catch_s,
  flowrange= ndvi$flowrange_s,
  elev=ndvi$elevmean_s
)

# FIXED EFFECTS -----------------------------------------------------------

# Varying intercepts (year) for non-climatic variables


m1a <- map2stan(
  alist(
    mean_s ~ dnorm(mu, sigma), 
    mu <- a + a_yr[wtyr_seq] +  belev*elev + bwtyrwk*wtyrwk,
    a ~ dnorm(0,10),
    a_yr[wtyr_seq] ~ dnorm(0,sigma),
    sigma ~ cauchy(0,2),
    c(belev, bwtyrwk) ~ dnorm(0,10)
  ),
  data=dlist, chains = 2, iter=5000, cores=2)


# Varying intercepts (year) for non-climatic variables

m1a <- map2stan(
  alist(
    mean_s ~ dnorm(mu, sigma), 
    mu <- a + a_yr[wyr] + bclay*clay + bflowslope*flowslope + 
      belev*elevmean + bkf*kf + bedge*edge + bcatch*catcharea,
    a ~ dnorm(0,10),
    a_yr[wyr] ~ dnorm(0,sigma),
    sigma ~ cauchy(0,2),
    c(bclay, bflowslope, belev, bkf, bedge, bcatch) ~ dnorm(0,10)
  ),
  data=dlist, chains = 2, warmup = 2000, iter=5000)

plot(m1a)
par(mfrow=c(1,1))
plot(precis(m1a))
precis(m1a)
plot(precis(m1a, depth=2))
mtext("Varying effects model")
postcheck(m1a)

pm1a <- extract.samples(m1a)
par(mfrow=c(1,1))
dens(pm1a$bedge, show.HPDI=0.95, lwd=2, col="orange",xlim=c(-0.6,0.6), ylim=c(0,10))
dens(pm1a$bcatch, show.HPDI=0.95, lwd=2, col="darkred", add =T)
dens(pm1a$bkf, show.HPDI=0.95, lwd=2, col="lightcoral", add=T)
dens(pm1a$belev, show.HPDI=0.95, lwd=2, col="red3", add=T)
dens(pm1a$bclay, show.HPDI=0.95, lwd=2, col="blue",add=T)
dens(pm1a$bflowslope, show.HPDI=0.95, lwd=2, col="darkgreen", add=T)
title(main="Posterior distributions")


## make table of output
library(knitr)
kable(as.data.frame(precis(m1a,depth=1)@output))

# varying intercepts (year) for snow and pdsi (Q2 only)
m1b <- map2stan(
  alist(
    ndvi ~ dnorm(mu, sigma), 
    mu <- a + a_yr[year] + bpQ2*pdsiQ2 + bpQ2L1*pdsiQ2L1 + 
      bpQ2L2*pdsiQ2L2 + bsnow*snow + bflwrng*flowrange,
    a ~ dnorm(0,10),
    a_yr[year] ~ dnorm(0,sigma),
    sigma ~ cauchy(0,2),
    c(bpQ2, bpQ2L1, bpQ2L2, bflwrng, bsnow) ~ dnorm(0,10)
    ),
  data=dlist, chains = 2, iter=5000, warmup=2000)
# m1<- resample(m1a, chains = 2, warmup=4000,iter=1e4)

plot(m1b)
par(mfrow=c(1,1))
plot(precis(m1b))
plot(precis(m1b,depth=2))

save(m1a,m1b, file="./docs/models/map_ndvi_pdsi_interceptsRstan.RData")
load("./docs/models/map_ndvi_pdsi_interceptsRstan.RData")
compare(m1b, m1a)

pm1 <- extract.samples(m1b)
par(mfrow=c(1,1))
dens(pm1$bpQ2, show.HPDI=0.95, lwd=2, col="orange",xlim=c(-0.6,0.6), ylim=c(0,10))
dens(pm1$bpQ2L1, show.HPDI=0.95, lwd=2, col="darkred", add =T)
dens(pm1$bpQ2L2, show.HPDI=0.95, lwd=2, col="lightcoral", add=T)
dens(pm1$bflwrng, show.HPDI=0.95, lwd=2, col="red3", add=T)
dens(pm1$bsnow, show.HPDI=0.95, lwd=2, col="blue",add=T)
#dens(pm1$bflowrng, show.HPDI=0.95, lwd=2, col="darkgreen", add=T)
title(main="Posterior distributions")


# Get mean estimates of varying intercepts/slopes
a1a <- apply(pm1$a_yr, 1, mean)
a1b <- apply(pm1$bsnow, 1, mean)

# Plot Slope vs. Intercept
plot(a1b,a1a,xlab="snow",ylab="wtf", pch=21, bg="cyan2")

# Plot Proportion of Contraception use in Urban vs. Rural
yr <- apply(logistic(pm1$a_yr), 1, mean)
snow <- apply(logistic(pm1$bsnow), 1, mean)
plot(yr ~ snow, bg="cyan2", pch=21)
mtext("Proportion of ", font=2)


# RANDOM EFFECTS BY YEAR --------------------------------------------------

m2 <- map2stan(
  alist(
    ndvi ~ dnorm( mu , sigma ),
    mu <- a_yr[year] + b_snw[year]*snow + b_kf*kf + b_snwkf*snow*kf,
    c(a_yr,b_snw)[year] ~ dmvnorm2(c(a,b),sigma_yr,Rho),
    c(b_kf,b_snwkf) ~ dnorm(0,10),
    a ~ dnorm(0,10),
    b ~ dnorm(0,10),
    sigma_yr ~ dcauchy(0,2),
    sigma ~ dcauchy(0,2),
    Rho ~ dlkjcorr(2)
  ) ,
  data=dlist , 
  iter=1000 , warmup=500 , chains=2)

plot(m2) # trace plots look good
precis(m2, depth=2)

save(m2, file="./docs/models/map_ndvi_snw_kf_randomFxRstan.RData")

# posterior correlation btwn intercepts and slopes
post2 <- extract.samples(m2)
par(mfrow=c(1,1))
dens( post2$Rho[,1,2], show.HPDI = 0.95, show.zero = T)

# extract posterior means of partially pooled estimates
a2 <- apply( post2$a_yr , 2 , mean )
b2 <- apply( post2$b_snw , 2 , mean )

yrs<-unique(ndvi$year)

# compute unpooled estimates directly from data
a1 <- sapply( unique(ndvi$name_id), #dlist$name,
              function(i) mean(dlist$snow[dlist$year==i & dlist$kf < 0]) )
b1 <- sapply( dlist$year ,
              function(i) mean(dlist$snow[dlist$year==i & dlist$kf < 0]) ) - a1

# plot both and connect with lines
plot( a1 , b1 , xlab="intercept" , ylab="slope" ,
      pch=16 , col=rangi2 , ylim=c( min(b1)-0.8 , max(b1)+0.8), 
      xlim=c( min(a1)-0.8 , max(a1)+0.8 ) )
points( a2 , b2 , pch=1 )
for ( i in dlist$year ) lines( c(a1[i],a2[i]) , c(b1[i],b2[i]) )

# compute posterior mean bivariate Gaussian
Mu_est <- c( mean(post2$a) , mean(post2$b) )
rho_est <- mean( post2$Rho[,1,2] )
sa_est <- mean( post2$sigma_yr[,1] )
sb_est <- mean( post2$sigma_yr[,2] )
cov_ab <- sa_est*sb_est*rho_est
Sigma_est <- matrix( c(sa_est^2,cov_ab,cov_ab,sb_est^2) , ncol=2 )

# draw contours
library(ellipse)
for ( l in c(0.1,0.3,0.5,0.8,0.99) )
  lines(ellipse(Sigma_est,centre=Mu_est,level=l),
        col=col.alpha("black",0.2))


# VARYING EFFECTS MODEL 3 -------------------------------------------------

m3 <- map2stan(
  alist(
    ndvi ~ dnorm( mu , sigma ),
    mu <- a_name[name] + b_snw[name]*snow*kf + b_kf*kf + b_clay*clay + bkfclay*kf*clay,
    c(a_name,b_snw)[name] ~ dmvnorm2(c(a,b),sigma_name,Rho_name),
    c(b_kf,b_clay, bkfclay) ~ dnorm(0,10),
    a ~ dnorm(0,10),
    b ~ dnorm(0,10),
    sigma ~ dcauchy(0,2),
    sigma_name ~ dcauchy(0,2),
    Rho_name ~ dlkjcorr(4)
  ) ,
  data=dlist , 
  iter=1000 , warmup=500 , chains=2)

plot(m3) # trace plots look good
precis(m3, depth=2)
plot(precis(m3, depth=1))

save(m3, file="./docs/models/map_ndvi_snwkfinteraction_randomFxRstan.RData")

# posterior correlation btwn intercepts and slopes
post3 <- extract.samples(m3)
par(mfrow=c(1,1))
dens( post3$Rho[,1,2], show.HPDI = 0.95, show.zero = T)


# PLOTS -------------------------------------------------------------------

precis(m2)
plot(m2)

png(file = "./docs/models/map2stan_pairs_ndvi_pdsi_yr_lat.png",width = 11, height=8.5, units="in",res=150)
pairs(m2)
dev.off()

pdf(file = "./docs/models/map2stan_ndvi_pdsi_yr_lat.pdf",width = 8, height=6)
plot(precis(m2), main="map2stan: Mdws + PDSI + Yr + Lat")
dev.off()


save(m2,post.m2, file = "./docs/models/map2stan_ndvi_pdsi_yr_lat.RData")

post.m2 <- extract.samples(m2)
par(mfrow=c(1,1))
dens(pm2$blat, show.HPDI=0.95, lwd=2, col="navyblue", xlim=c(-0.27, 0.2))
dens(pm2$bM, show.HPDI=0.95, lwd=2, col="green", add=T)
dens(pm2$bY, show.HPDI=0.95, lwd=2, col="red", add=T)
dens(pm2$bYL, show.HPDI=0.95, lwd=2, col="purple", add=T)

