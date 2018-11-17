Code used for the analyses in the publication "The Global Biogeography of Polyploid Plants" (Nature Ecology & Evolution, currently in press).  
Reference:  
Link:  
Also see related data at Figshare project:

Following are the steps that reproduce the results in the paper:  
**_1.	Filter occurrences_**  
_Script:_ filtering.R  
_Description:_ Using the CleanCoordinates wrapper function of the CoordinateClearner R package, together with additional filters, the occurrences files are filtered. Additional filters include: (1) basis of record must be different than LIVING_SPECIMEN or LITERATURE, and the decimal part of each of the coordinates must have at least 2 digits.   
_Input:_ 	(1) working_dir	(2) new_dir (destination) (3) genera (list of working genera) (4) suffix (input file suffix, e.g., “GBIF.csv” for “genusGBIF.csv”)  
_Output:_ genusFiltered.csv   
  
**_2.	Name resolution_**  
_Script:_ name_resol.R  
_Description:_ Works on the genusFiltered.csv file. Calls Taxonome (Kluyver & Osborne 2013; doi: 10.1002/ece3.529) to perform name resolution and discard accepted names that are crops species (attributes_and_data/crops.csv). Accepted names with score ≥0.8 will replace original names. In case of resolution to another genus, these names are printed to a different leftovers file (NR_leftovers.csv).   
name_resol.R  output: genusToResolve.csv  NameResolution_New.py  output: genusTaxonomeOutput.csv  parse_taxonome.pl (inputs: (1) working_dir (2) genera_list) outputs: (1) genusResolved.csv (2) NR_leftovers.csv  parse_NR_leftovers.R  genusResolved.csv  
** Required environment: python-3.3.0, perl-5.16.3, LANG aa_DJ.utf8  
_Input:_ 	(1) genus (2) working_dir (3) name_res_script (name resolution script path) (4) db_filename (for Taxonome) (5) parse_script (parse Taxonome script path) (6) crops_list_file  
_Output:_ (1) genusToResolve.csv	(2) genusTaxonomeOutput.csv 	(3) genusResolved-log.csv (4) genusToResolve.csv-syn.csv 	(5) NR_leftovers.csv (6) genusResolved.csv  
  
**_3.	Add locality, ploidy level, taxonomy and lifeform to species_**  
_Script:_ add_locality_ploidy.R  
_Description:_ Works on the genusResolved.csv file: (1) ensures there are at least 5 occurrences per species. (2) Adds to each occurrence its corresponding biome and ecoregion according to coordinates, (3) aggregates occurrences of the same species together and summarizes them, (4) adds to each species ploidy level, (5) taxonomy and (6) lifeform.   
_Input:_	(1) working_dir  (2) genus (3) wwf_folder (where the wwf ecoregions layer is, attributes_and_data/teow) (4) ploidy_path (where the genus Ploidy.csv file is located) (5) lifeform_file (path to lifeform database) (6) tax_file (path to taxonomy database)  
_Output:_	 genusAllData.csv  
  
**_4.	Put all species data in one table_**  
_Description:_ unifies all genusAllData.csv files to a single file  
_Script:_ build_large_species_file.R  
_Input:_	(1) working_dir  (2) genus  (3) output_file  
_Output:_ output_file  
  
**_5.	Summarize all species into ecoregions and biomes_**   
_Script:_ construct_locality_freqs.R  
_Description:_ Transforms the species-level to biomes and ecoregions-level. Summarizes for each ecoregion the total number of occurrences, number of species, number of diploids, number of polyploids, number of each taxonomical classification, and number of each lifeform classification.  
_Input:_ (1) data_file (output from previous step, final_species_data.csv). (2) ecoregions (a file of ecoregion names and ids, attributes_and_data/eco_id_with_names.csv) (3) output1 (for biomes) (4) output2 (for ecoregions)  
_Output:_ (1) output1 (2) output2  
  
**_6.	Add attributes per ecoregion_**  
_Script:_ prepare_data_for_analysis.R  
_Description:_ Adds the following attributes to each ecoregion: BIOCLIM variables, altitude, elevation amplitude, change in climate, NPP, human footprint, phosphorus retention, difference in extent of glaciation, latitude, and species richness. The variables are transformed as described in the paper.   
_Input:_ (1) data_file (2) features_path (3) glaciers_data  (4) latitude_data (5) spr_data (6) phosphorus_data (7) eco_code_id (8) output_file (arguments 1-7 can be found in /attributes_and_data)  
_Output:_ output_file  
  
**_7.	GLM_**  
_Script:_ glm_per_var.R  
_Description:_ performs a GLM analysis per attribute (single-predictor model) on the output of the previous step.  
Intput: data_file  
_Output:_ output_file  
  
**_8.	Relative importance_**  
_Script:_ relative_importance.R  
_Description:_ performs relative importance analysis on the output of stage #6.  
Intput: data_file  
  
**_9.	Structural Equation Modelling_**  
_Script:_ sem.R  
_Description:_ performs SEM analysis on the output of stage #6.  
_Intput:_ data_file  
