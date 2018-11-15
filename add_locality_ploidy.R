# args: (1) working_dir  (2) genus (3) wwf_folder (where the wwf ecoregions layer is, attributes_and_data/teow) (4) ploidy_path (where the genus Ploidy.csv file is located) (5) lifeform_file (path to lifeform database) (6) tax_file (path to taxonomy database)

require("raster")
require("rgdal")
require("plyr")

# Get arguments from last script
args <- commandArgs(TRUE)
for(i in 1:length(args)){
  eval(parse(text = args[[i]]))
}

add_locality = function(wwf_folder,data){
  # extracdt ecoregions and biomes data
  wwf_polygon<- readOGR(wwf_folder,"wwf_terr_ecos")
  poly_proj <- proj4string(wwf_polygon) 
  genus_coord = data.frame(data$decimallongitude,data$decimallatitude)
  names(genus_coord)= c("long","lat")
  coordinates(genus_coord) <- c("long","lat")
  points<- SpatialPointsDataFrame(genus_coord,data, proj4string=CRS("+proj=longlat +datum=WGS84"))
  
  # add biomes and ecoregions 
  proj4string(points) <- CRS(poly_proj)
  ecoregions=over(points, wwf_polygon) # assigned biomes to each point according to the polygon
  biome = ecoregions$BIOME #biomes vector
  eco_id = ecoregions$ECO_ID # ecoregions vector
  data = cbind(data,biome,eco_id) # add vectors to the occurrences data
  data = data[which(!is.na(data$eco_id)),] # discard rows that don't have biome or ecoregion
  data = data[which(data$eco_id!=-9998 & data$eco_id!=-9999),] # discard rows that have eco_id of -9998 or -9999
  
  return(data)
}

add_ploidy = function(ploidy_path,genus,data){
  ploidy_file = paste(ploidy_path,genus,"/",genus,"_Chromevol_prune/chromevol_out/",genus,"Ploidy.csv",sep="")
  if (!file.exists(ploidy_file)){ # no ploidy inference at all
    data$ploidy = NA
    return(data)
  }
  ploidy_data = read.csv(ploidy_file, stringsAsFactors=F)
  # remove taxa with NA from ploidy data file
  ploidy_data = ploidy_data[which(!is.na(ploidy_data$Ploidy.inference)),]
  ploidy_data = ploidy_data[,c(1,3)]
  names(ploidy_data) = c("species","ploidy")
  data = merge(data,ploidy_data,by="species", all.x = T)# merge files 
  
  return(data)
}


add_taxonomy = function(data,tax_file){
  if (length(unique(data$genus))>1){ # if no consistency in genus assignment take the majority
    genera_df = as.data.frame(table(data$genus),stringsAsFactors=F)
    data$genus = genera_df$Var1[which.max(genera_df$Freq)]
  }
  
  tax_dat = read.csv(tax_file,stringsAsFactors=F)
  ind = which(tax_dat$genus==data$genus[1])
  data$Wood_major_group = NA
  if (length(ind)!=0){ # classification found. If not found - no taxonomy
    data$Wood_major_group = tax_dat$Wood_major_group[ind]
  }
  data = data[which(!is.na(data$Wood_major_group)),]
  return(data)
}

aggregate_occurrences = function(data){
  # if more than 1 family in the genus records, assign the majority
  if (length(unique(data$family>1))){
    tmp_df = as.data.frame(table(data$family),stringsAsFactors=F)
    data$family = tmp_df$Var1[which.max(tmp_df$Freq)]
  }
  # if more than 1 genus in the genus recors, assign the majority
  if (length(unique(data$genus>1))){
    tmp_df = as.data.frame(table(data$genus),stringsAsFactors=F)
    data$genus = tmp_df$Var1[which.max(tmp_df$Freq)]
  }
  
  data_agg <- ddply(data, .(species), summarize,
                    family = unique(paste(family)),
                    genus = unique(paste(genus)),
                    biome=paste(biome,collapse=","), 
                    eco_id=paste(eco_id,collapse=","),
                    Wood_major_group = unique(paste(Wood_major_group)))
  
  lines = data_agg$biome
  lines_applied = lapply(lines, function(x) data.frame(table(as.numeric(unlist(strsplit(x,","))))))
  lines_applied_strings = lapply(lines_applied, function(x) toString(paste(x$Var1,x$Freq,sep="_")))
  data_agg$biome = unlist(lines_applied_strings)
  data_agg$num_biomes = unlist(lapply(lines_applied_strings, function(x) nchar(x)-nchar(gsub("_", "", x))))

  lines = data_agg$eco_id
  lines_applied = lapply(lines, function(x) data.frame(table(as.numeric(unlist(strsplit(x,","))))))
  lines_applied_strings = lapply(lines_applied, function(x) toString(paste(x$Var1,x$Freq,sep="_")))
  data_agg$eco_id = unlist(lines_applied_strings)
  data_agg$num_ecos = unlist(lapply(lines_applied_strings, function(x) nchar(x)-nchar(gsub("_", "", x))))
   
  lines = data$species
  data_agg$total_occurrences = data.frame(table(lines))$Freq
  
  data_agg$Wood_major_group = data$Wood_major_group[1]
  data_agg = data_agg[which(data_agg$total_occurrences>4),]
  
  return(data_agg)
}  

add_lifeform = function(data,lifeform_file){
  ## several exceptions according to Table S10 
  if (data$genus%in%c("Acer","Erica","Viburnum","Aspalathus") | (data$family%in%c("Arecaceae","Betulaceae"))){
	data$lifeform = "Woody"
	write.csv(data,paste(genus,"AllData.csv",sep=""),row.names=F)
	return(data)
  }
  if (data$family=="Amaryllidaceae"){
	data$lifeform = "Perennial herb"
	write.csv(data,paste(genus,"AllData.csv",sep=""),row.names=F)
	return(data)
  }
  LF = read.csv(lifeform_file,stringsAsFactors = F)
  data = merge(data,LF, by="species",all.x = T)
  write.csv(data,paste(genus,"AllData.csv",sep=""),row.names=F)
}


setwd(working_dir)
data_file = paste(genus,"Resolved.csv",sep="")
# check that genus passed name resoution
if (!file.exists(data_file)){
  quit()
}

data = read.csv(data_file,na.strings = c("NA","UNKNOWN",""), stringsAsFactors=F)
if (ncol(data)==1){
	data = read.csv(data_file,na.strings = c("NA","UNKNOWN",""), stringsAsFactors=F, sep=" ")
}

# add ecoregions and biomes per occurrence
data = add_locality(wwf_folder,data)
# add taxonomy classification
data = add_taxonomy(data,tax_file)
if (nrow(data)==0){
  quit()
}
# reduce data to the species-level (aggregate occurrences together)
data = aggregate_occurrences(data)
if (nrow(data)==0){
  quit()
}
# add ploidy level per species
data = add_ploidy(ploidy_path,genus,data)
# add lifeform per species
data = add_lifeform(data,lifeform_file)

