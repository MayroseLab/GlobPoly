# /share/apps/R310/bin/R CMD BATCH '--no-save --no-restore --args working_dir="/groups/itay_mayrose/annarice/EcoGeo/v7/raw/data_filtered/data" genera_list="/groups/itay_mayrose/annarice/EcoGeo/v7/gbif_angios_after_taxonome2.csv"' /groups/itay_mayrose/annarice/EcoGeo/v7/raw/scripts/parse_NR_leftovers.R /groups/itay_mayrose/annarice/EcoGeo/v7/parseNRleftoversLog &

# input: working_dir, genera (list of all genera), process_genera (genera to work on)
# output: spreads the resolved names to their matching files
# genera,working_dir

# GLOBAL ARGUMENTS
args <- commandArgs(TRUE)
for(i in 1:length(args)){
  eval(parse(text = args[[i]]))
}

genera_list = read.csv(genera_list, header=F, stringsAsFactors=F)
names(genera_list) = "genus"

setwd(working_dir)
list_of_dirs = list.files(working_dir)

for (i in 1:length(genera_list$genus)){ # go over all genera-to-process folders
  genus = genera_list$genus[i]
  print(genus)
  NR_file = paste(genus,"NR_leftovers.csv",sep="/")
  if (file.exists(NR_file)){
    data = try(read.csv(NR_file,header=FALSE))
	if (inherits(data,"try-error")){
		next
	}
	names(data) = c("family","genus","species","decimallatitude","decimallongitude")
    genera = as.character(unique(data$genus))
    # go over all unique names that need to be re-matched to their right genus
    for (j in 1:length(genera)){ 
      genus = genera[j]
      if (genus%in%list_of_dirs){ 
		#print(paste("*****",genera_list$genus[i],"to",genus,"*****"))
        file_name = paste(working_dir,"/",genus,"/",genus,"Resolved.csv",sep="") 
		tmp_data = data[which(data$genus==genus),]
		
		if (file.exists(file_name)){
			data = read.csv(file_name,stringsAsFactors=F) #### added now
			if (ncol(data)==1){ # delimiter should be " "
				data = read.csv(file_name,stringsAsFactors=F, sep=" ") 
			}
			data = rbind(data,tmp_data)
			data = data[!duplicated(data),] # remove duplicates that might appear after name resolution #### added now 
			write.table(data,file=file_name,row.names=FALSE)
		} else {
			new_resolved = data.frame(matrix(ncol=5))
			names(new_resolved) = names(data)
			new_resolved = rbind(new_resolved,tmp_data)
			names(new_resolved) = names(tmp_data)
			new_resolved = new_resolved[-1,]
			new_resolved = new_resolved[!duplicated(new_resolved),] # remove duplicates that might appear after name resolution #### added now 
			write.table(new_resolved,file=file_name,row.names=FALSE)
			print(paste("NEW RESOLVED",genus,sep=""))
		}
      }
    } 
  }
}