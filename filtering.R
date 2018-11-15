# args: (1) genus (2) working_dir

library(tidyverse)
library(rgbif)
library(countrycode)
library(CoordinateCleaner)
library (rnaturalearthdata)

args <- commandArgs(TRUE)
for(i in 1:length(args)){
  eval(parse(text = args[[i]]))
}

clean_data = function(data){
  names(data)[12:13] = c("decimallatitude","decimallongitude")
  
  # convert latitude, longitude and coordinateUncertainty to numeric values
  data[,c(12:14)] = apply(data[,c(12:14)], 2, function(x) as.numeric(as.character(x)));
  #convert country code from ISO2c to ISO3c
  data$countrycode <- countrycode(data$countrycode, origin = 'iso2c', destination = 'iso3c')
  
  # remove coordinate uncertainty under threshold
  data <- data %>%
    filter(coordinateuncertaintyinmeters <= 10000 | is.na(coordinateuncertaintyinmeters))
  
  # remove basis of record "literature" or "living specimen"
  data = data[which(!data$basisofrecord=="LIVING_SPECIMEN" |
                          !data$basisofrecord=="LITERATURE"),]
  
  # cc_outl() and cc_sea() require too much of memory --> go back to them later
  dat.cl <- data%>%
    cc_val()%>%
    cc_equ()%>%
    cc_cap()%>%
    cc_cen()%>%
    cc_coun(iso3 = "countrycode")%>%
    cc_gbif()%>%
    cc_inst()%>%
    cc_zero()%>%
    cc_dupl()
  
  # requires more memory --> perform after initial filtering
  dat.cl <- dat.cl%>%
    cc_sea()
  
  # requires more memory --> perform after initial filtering
  dat.cl <- dat.cl%>%
    cc_outl()
  
  # if species name is missing - take it from "scientific name"
  ind = which(is.na(dat.cl$species) & !is.na(dat.cl$scientificname))
  dat.cl$species[ind] = dat.cl$scientificname[ind]
  # remove rows without species name
  dat.cl = dat.cl[which(!is.na(dat.cl$species)),] 
  
  # remove INVALID issues lines
  omit_lines = which((grepl("INVALID",dat.cl$issue) & !grepl("DATE_INVALID",dat.cl$issue) & !grepl("URI_INVALID",dat.cl$issue) & !grepl("COUNT_INVALID",dat.cl$issue) & !grepl("COORDINATE_PRECISION_INVALID",dat.cl$issue)) | grepl("ZERO_COORDINATE",dat.cl$issue) | grepl("COUNTRY_MISMATCH",dat.cl$issue) | grepl("COORDINATE_OUT_OF_RANGE",dat.cl$issue))
  if (length(omit_lines)!=0){
    dat.cl = dat.cl[-omit_lines,]
  }
  
  # decimal part must have at least 2
  length_decimal_lat = nchar(sub("^[^.]*", "", dat.cl$decimallatitude))-1
  length_decimal_lon = nchar(sub("^[^.]*", "", dat.cl$decimallongitude))-1
  dat.cl = dat.cl[which(length_decimal_lat>=2 & length_decimal_lon>=2),] 
    
  # discard irrelevant columns
  dat.cl = dat.cl[,which(names(dat.cl)%in%
      c("family","genus","species","decimallatitude","decimallongitude"))]
}

# main
setwd(working_dir)
data_file = paste(genus,"GBIF.csv",sep="")
data = read.csv(data_file, stringsAsFactors=F, na.strings=c("NA","UNKNOWN",""))
data = clean_data(data)
# no occurrences left in the dataset
if (nrow(data)==0) { 
quit(n)
}
output_file = paste(genus,"Filtered.csv", sep="")
write.csv(data,output_file,row.names=F)