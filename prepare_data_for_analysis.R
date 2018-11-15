data = read.csv(data_file, stringsAsFactors=F)

############################ MERGE ATTRIBUTES PER ECOREGIONS ############################
# bioclims
variables = c(paste("bio",seq(1:19),sep="_"),"alt","npp","human_footprint")
for (i in 1:length(variables)){
  feature = read.csv(paste(features_path,variables[i],".csv",sep=""),stringsAsFactors=F)
  if (i==20){ # elevation apmlitude (assigned as "bio_20")
    tmp = feature[,c(3,7)]
    tmp = tmp$X90.-tmp$X10.
    feature2 = feature
    feature2[5] = tmp
    feature2 = feature2[,c(2,5)]
    names(feature2) = c("eco_id","bio_20_50")
    data = merge(data,feature2,by="eco_id",all.x=T)
  }
  feature = feature[,c(2,5)]
  names(feature) = c("eco_id",paste("bio",i,"50",sep="_"))
  if (i==20) {names(feature) = c("eco_id","alt_50")}
  if (i==21) {names(feature) = c("eco_id","npp_50")}
  if (i==22) {names(feature) = c("eco_id","human_footprint_50")}
  data = merge(data,feature,by="eco_id",all.x=T)
}

# change-in-climate
paleo = c(paste("cclgmbi",seq(1:19),sep=""))
for (i in 1:length(paleo)){
  feature = read.csv(paste(features_path,paleo[i],".csv",sep=""),stringsAsFactors=F)
  feature = feature[,c(2,5)]
  names(feature) = c("eco_id",paste("paleo",i,"50",sep="_"))
  data = merge(data,feature,by="eco_id",all.x=T)
}

# change-in-climate features are difference between current and past bioclim
data[,49:67] = data[,26:44] - data[,49:67]

# glaciers 
feature = read.csv(glaciers_data,stringsAsFactors=F)
names(feature) = c("eco_id","current","lgm","diff_glaciers")
data = merge(data,feature,by="eco_id",all.x=T)
data$diff_glaciers[which(data$diff_glaciers==0)] = NA

# latitude 
feature = read.csv(latitude_data,stringsAsFactors=F)
feature = feature[,c(1,3)]
names(feature) = c("eco_id","lat")
data = merge(data,feature,by="eco_id",all.x=T)

# species richness 
feature = read.csv(spr_data,stringsAsFactors=F)
data = merge(data,feature,by="eco_id",all.x=T)

# P retention (median) 
feature = read.csv(phosphorus_data,stringsAsFactors=F)
feature = feature[,c(1,5)]
ecoregions = read.csv(eco_code_id,stringsAsFactors=F)
names(ecoregions) = c("eco_id","eco_code")
feature = merge(feature,ecoregions,by="eco_code",all.x=T)
feature = feature[!is.na(feature$eco_id),-1]
names(feature) = c("P_median","eco_id")
data = merge(data,feature,by="eco_id",all.x=T)

############################ END OF ATTRIBUTES MERGING ############################

data = data[which(data$sp>9),] # discard ecoregions with less than 10 species
data = data[which(data$dp+data$pp>4),] # discard ecoregions with less than 5 ploidy inferences
data$resolved_lifeform = data$woody + data$herb_p + data$annual

############################ TRANSFORMATIONS ############################
# bioclim precipitation transformation
precipitation = paste("bio",seq(12,19),"50",sep="_")
precipitation = precipitation[precipitation!="bio_15_50"] # do not transform bio_15
data[,which(names(data)%in%precipitation)] = log(data[,which(names(data)%in%precipitation)]+1) 
# paleo precipitation transformation
paleo_precipitation = paste("paleo",seq(12,19),"50",sep="_")
paleo_precipitation = precipitation[precipitation!="paleo_15_50"] # do not transform paleo_15
data[,which(names(data)%in%paleo_precipitation)] = log(data[,which(names(data)%in%paleo_precipitation)]+1) 
# altitude, elevation amplitude and species richness transformation
data$alt_50 = log(data$alt_50) 
data$bio_20_50 = log((data$bio_20_50)+1) 
data$sp_richness = log((data$sp_richness)+1) 

data$diff_glaciers[which(data$diff_glaciers<0)] = 0 # negative differences are assigned as 0 
data$diff_glaciers = logit(data$diff_glaciers, adjust = 0.025) # percentages --> logit transf.

# "weighted" logit transformation
# lifeform
data$woody_perc = log((data$woody+0.5)/(data$resolved_lifeform-data$woody+0.5))
data$herbaceous_p_perc = log((data$herb_p+0.5)/(data$resolved_lifeform-data$herb_p+0.5))
data$herbaceous_a_perc = log((data$annual+0.5)/(data$resolved_lifeform-data$annual+0.5))
# taxonomy
data$basal_m_perc = log((data$basal_m+0.5)/(data$sp-data$basal_m+0.5))
data$commelinids_perc = log((data$higher_m+0.5)/(data$sp-data$higher_m+0.5))
data$basal_angios_perc = log((data$angiosperm+0.5)/(data$sp-data$angiosperm+0.5))
data$basal_d_perc = log((data$basal_d+0.5)/(data$sp-data$basal_d+0.5))
data$rosids_perc = log((data$rosids+0.5)/(data$sp-data$rosids+0.5))
data$asterids_perc = log((data$asterids+0.5)/(data$sp-data$asterids+0.5))

write.csv(data,file = output_file,row.names=F)
