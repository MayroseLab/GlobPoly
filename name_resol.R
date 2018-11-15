# args: (1) genus (2) working_dir (3) name_res_script (name resolution script path) (4) db_filename (for Taxonome) (5) parse_script (parse Taxonome script path) (6) crops_list_file

args <- commandArgs(TRUE)
for(i in 1:length(args)){
  eval(parse(text = args[[i]]))
}

create_input_for_Taxonome = function(data){
	unique_sp = unique(data$species)
	new_data = data.frame(matrix(ncol = 2, nrow = length(unique_sp)))
	names(new_data) = c("Id","Name")
	new_data$Id = seq(1:nrow(new_data))
	new_data$Name = unique_sp
	
	return(new_data)
}

# main
setwd(working_dir)
data_file = paste(genus,"Filtered.csv",sep="")
# if filtering process cleared all occurrences - quit
if (!file.exists(data_file)){
	quit()
}
data = read.csv(data_file, stringsAsFactors=F, na.strings=c("NA","UNKNOWN",""))
new_data = create_input_for_Taxonome(data)

output_file = paste(genus,"ToResolve.csv",sep="")
write.csv(new_data,output_file,row.names=F)


# run name resolution
taxonome_output_file = paste(genus,"TaxonomeOutput.csv",sep="")
taxonome_log = paste(genus,"log.csv",sep="")
command = paste("python ",name_res_script," --db-filename ",db_filename," --input-filename ",paste(getwd(),output_file,sep="/")," --results-filename ",paste(getwd(),taxonome_output_file,sep="/"),
" --log-filename ",paste(getwd(),taxonome_log,sep="/")," --authfield True",sep="")
system("module load python/python-3.3.0 ; module load perl/perl-5.16.3 ; setenv LANG aa_DJ.utf8 ;")
system(command)

# parse name resolution results
parsed_file = paste(genus,"Resolved.csv",sep="")
command = paste("perl",parse_script,working_dir, data_file,taxonome_output_file, parsed_file, genus, crops_list_file)
system(command);