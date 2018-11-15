# args: (1) data_file (output from previous step, final_species_data.csv). (2) ecoregions (a file of ecoregion names and ids, attributes_and_data/eco_id_with_names.csv) (3) output1 (for biomes) (4) output2 (for ecoregions)

# GLOBAL ARGUMENTS
args <- commandArgs(TRUE)
for(i in 1:length(args)){
  eval(parse(text = args[[i]]))
}

get_biomes = function (data){
	all_biomes = data$biome
	all_biomes = gsub("[[:space:]]", "", all_biomes)
	splitter = unlist(strsplit(all_biomes,","))
	odd_ind = seq(1,length(unlist(strsplit(splitter,"_"))),2)
	even_ind = seq(2,length(unlist(strsplit(splitter,"_"))),2)
	biomes = unlist(strsplit(splitter,"_"))[odd_ind]
	occurrences = unlist(strsplit(splitter,"_"))[even_ind]
	
	return (list(biomes,occurrences))
}

get_ecoregions = function (data){
	all_ecoregions = data$eco_id
	all_ecoregions = gsub("[[:space:]]", "", all_ecoregions)
	splitter = unlist(strsplit(all_ecoregions,","))
	odd_ind = seq(1,length(unlist(strsplit(splitter,"_"))),2)
	even_ind = seq(2,length(unlist(strsplit(splitter,"_"))),2)
	ecoregions = unlist(strsplit(splitter,"_"))[odd_ind]
	occurrences = unlist(strsplit(splitter,"_"))[even_ind]
	
	return(list(ecoregions,occurrences))
}

data = read.csv(data_file,stringsAsFactors=F, na.strings = c(NA,""))
ecoregions_data = read.csv(ecoregions,stringsAsFactors=F)

factors = 23

eco_data = data.frame(matrix(nrow = nrow(ecoregions_data), ncol = factors))
names(eco_data) = c("eco_id","name","occurrences","sp","dp","pp","na","annual","herb_p","woody","unclass_herb","unclass_per","no_lifeform",
		"mixed","unresolved","conflict","basal_m","higher_m","angiosperm","basal_d","rosids","asterids","no_tax")
eco_data$eco_id = ecoregions_data$eco_id
eco_data$name = ecoregions_data$eco_name

biome_data = data.frame(matrix(nrow = 14, ncol = factors))
names(biome_data) = c("biome","name","occurrences","sp","dp","pp","na","annual","herb_p","woody","unclass_herb","unclass_per","no_lifeform",
		"mixed","unresolved","conflict","basal_m","higher_m","angiosperm","basal_d","rosids","asterids","no_tax")
biome_data$biome = seq(1,14,1)

# initialize data frames as zeros
eco_data[,3:ncol(eco_data)] = 0
biome_data[,3:ncol(biome_data)] = 0

# update count in table
update_count = function(row,original_data_row,curr_occ){
	row$occurrences = row$occurrences + curr_occ
	row$sp = row$sp + 1
	if (is.na(original_data_row$ploidy)){ row$na = row$na + 1 }
		else if (original_data_row$ploidy==0){ row$dp = row$dp + 1 }
			else if (original_data_row$ploidy==1){ row$pp = row$pp + 1 }
	if (is.na(original_data_row$lifeform)) { row$no_lifeform = row$no_lifeform + 1 }
		else if (original_data_row$lifeform == "Annual") { row$annual = row$annual + 1 }
			else if (original_data_row$lifeform == "Perennial herb") { row$herb_p = row$herb_p + 1 }
				else if (original_data_row$lifeform == "Woody") { row$woody = row$woody + 1 }
					else if (original_data_row$lifeform == "Unclassified herb") { row$unclass_herb = row$unclass_herb + 1 }
						else if (original_data_row$lifeform == "Unclassified perennial") { row$unclass_per = row$unclass_per + 1 }
							else if (original_data_row$lifeform == "mixed") { row$mixed = row$mixed + 1 }
								else if (original_data_row$lifeform == "unresolved") { row$unresolved = row$unresolved + 1 }
									else if (original_data_row$lifeform =="Conflict") { row$conflict = row$conflict + 1 }

	if (is.na(original_data_row$Wood_major_group)) { row$no_tax = row$no_tax + 1 }
			else if (original_data_row$Wood_major_group =="Basal monocots (non-commelinid monocots)") { row$basal_m = row$basal_m + 1 }
				else if (original_data_row$Wood_major_group =="Higher monocots (commelinids)") { row$higher_m = row$higher_m + 1 }
					else if (original_data_row$Wood_major_group =="Basal angiosperms") { row$angiosperm = row$angiosperm + 1 }
						else if (original_data_row$Wood_major_group =="Basal dicots (non-asterid +non-rosid dicots)") { row$basal_d = row$basal_d + 1 }
							else if (original_data_row$Wood_major_group =="Dicots - core rosids") { row$rosids = row$rosids + 1 }
								else if (original_data_row$Wood_major_group =="Dicots - core asterids") { row$asterids = row$asterids + 1 }
	return (row)
}

for (i in 1:nrow(data)){
	print(i)
	res = get_biomes(data[i,]) # get species' biomes
	biomes = res[[1]]; occurrences = res[[2]]
	remove_ind = NULL
	if ("98" %in% biomes){ # remove "98" from biomes
		remove_ind = which(biomes=="98")
		biomes = biomes[-remove_ind] 
		occurrences = occurrences[-remove_ind]
	} 
	if ("99" %in% biomes){ # remove "99" from biomes
		remove_ind = which(biomes=="99")
		biomes = biomes[-remove_ind] 
		occurrences = occurrences[-remove_ind]
	}

	# do not consider species with less than 5 occurrences
	remove_ind = NULL
	if (length(which(as.numeric(occurrences)<5))>0){
		remove_ind = which(as.numeric(occurrences)<5)
		occurrences = occurrences[-remove_ind]
		biomes = biomes[-remove_ind] 
	}
	
	data$biomes[i] = length(biomes)
	for (b in 1:length(biomes)){ # iterate over all biomes
		row_ind = which(biome_data$biome==biomes[b])
		updated_row = update_count(biome_data[row_ind,],data[i,],as.numeric(occurrences[b]))
		biome_data[row_ind,] = updated_row
	}
	
	remove_ind = NULL
	if (is.na(data$eco_id[i])){ # possible that there are biomes without ecoregions
		next
	}
	res = get_ecoregions(data[i,]) # get species' ecoregions
	ecoregions = res[[1]]; occurrences = res[[2]]
	if ("-9998" %in% ecoregions){ # remove "-9998" from biomes
		remove_ind = which(ecoregions=="-9998")
		ecoregions = ecoregions[-remove_ind] 
		occurrences = occurrences[-remove_ind]
	} 
	if ("-9999" %in% ecoregions){ # remove "-9999" from biomes
		remove_ind = which(ecoregions=="-9999")
		ecoregions = ecoregions[-remove_ind] 
		occurrences = occurrences[-remove_ind]
	}
	
	# do not consider species with less than 5 occurrences
	remove_ind = NULL
	if (length(which(as.numeric(occurrences)<5))>0){
		remove_ind = which(as.numeric(occurrences)<5)
		occurrences = occurrences[-remove_ind]
		ecoregions = ecoregions[-remove_ind]
	}
	
	data$ecoregions[i] = length(ecoregions)
	for (e in 1:length(ecoregions)){
		row_ind = which(eco_data$eco_id==ecoregions[e])
		updated_row = update_count(eco_data[row_ind,],data[i,],as.numeric(occurrences[e]))
		eco_data[row_ind,] = updated_row
	}
}

# add biome number to each ecoregion
biome_data$pp_perc = biome_data$pp/biome_data$sp*100 # pp_perc in each ecoregion
biome_data$pp_perc_resolved = biome_data$pp/(biome_data$pp + biome_data$dp)*100

eco_data$pp_perc_sp = eco_data$pp/eco_data$sp*100 # pp_perc in each ecoregion
eco_data$pp_perc_resolved = eco_data$pp/(eco_data$pp + eco_data$dp)*100

write.csv(file = output1,biome_data,row.names=F)
write.csv(file = output2,eco_data,row.names=F)