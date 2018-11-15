# args: (1) working_dir (2) genus (3) output_file

# GLOBAL ARGUMENTS
args <- commandArgs(TRUE)
for(i in 1:length(args)){
  eval(parse(text = args[[i]]))
}


genera = read.csv(genera, header=F, stringsAsFactors=F)
names(genera) = "genus"
setwd(working_dir)

all_genera_table = NULL

for (i in 1:nrow(genera)){
	setwd(working_dir)
	genus = genera$genus[i]
	if (!file.exists(genus)){
		next
	}
	setwd(genus)
	
	filename = paste(genus,"AllData.csv",sep="")
	if (!file.exists(filename)){
		next
	}
	
	data = read.csv(filename,stringsAsFactors=F)
	#print (paste(genus,nrow(data)))
	all_genera_table = rbind (all_genera_table,data)	
}

setwd(working_dir)
write.csv(all_genera_table,file=output_file, row.names=F)
