import argparse
import csv
import sys
import re
import os
import sqlite3
#sys.path.append('/groups/itay_mayrose/share/ploidb/NameResolution/Taxonome_1_5/')
from taxonome.taxa.collection import run_match_taxa
from taxonome import tracker
from taxonome.taxa import file_csv, TaxonSet, Taxon, name_selector
import sqlite3
from taxonome.taxa.file_csv import load_taxa
from taxonome.taxa.name_selector import NameSelector
from taxonome.tracker import CSVTaxaTracker, _flatten_name, CSVListMatches

import unicodedata

from difflib import SequenceMatcher

#Global flag for Syn/Unres_casese:
FLAG_STATUS=''
ID_Accepted_dict ={}
ID_synonym_dict ={}
ID_Unres_dict ={}

__author__ = 'moshe'  # Modified by Michal May2016


def similar(a, b):
	return SequenceMatcher(None, a, b).ratio()


class FirstNameSelector(NameSelector):

	def user_select(self, name_options, name, allow_retype, tracker):

		name_to_return = name_options[0]
		try:
			print("handling multiple names for %s - return %s" % (name,name_to_return))
		except:
			print("EXCEPTION(FirstNameSelector): Couldn't handle multiple names for %s" % name)

		return name_to_return


def prepare_syn_unres_Files(Output_file):

	# Get path of Input file:
	Path_output = Output_file.rsplit('/', 1)[0]
	Header_line = "Id,Name,Authority\n"

	Synonym_input_file = Path_output + '/SynInput.csv'
	with open(Synonym_input_file,'w+' ,encoding='utf-8', errors='ignore') as Syn_Input:
		Syn_Input.write(Header_line)
	Unresolved_input_file = Path_output + '/UnresInput.csv'
	with open(Unresolved_input_file,'w+' ,encoding='utf-8', errors='ignore') as Unres_Input:
		Unres_Input.write(Header_line)

	return Output_file,Synonym_input_file,Unresolved_input_file

class MyCSVListMatches(CSVListMatches):
	taxon = None
	matched_name = None

	def __init__(self, fileobj, fieldnames, header=True):
		# Full Name/Authority - accepted name/authority.
		# Name/Authority - accepted name/authority after removing non ascii chars
		# Matched Name - closest sysnoym (or accepted) name found in taxonome DB
		fieldnames = ["Name", "Authority", "Original name", "Original authority","Coded Name", "Coded Authority", "Score","Matched Name"] + fieldnames
		self.writer = csv.DictWriter(fileobj, fieldnames, extrasaction='ignore')
		if header:
			self.writer.writeheader()

	def start_taxon(self, tax):
		super().start_taxon(tax)
		self.taxon = tax

	def name_transform(self, name, newname, event, **kwargs):
		super().name_transform(name, newname, event, **kwargs)
		# The idea is: (1) always have a matched_name (2) matched name should be the intermediate step i.e. before synonyms/accepted names
		if (self.matched_name is None) or (event != 'synonymy' and event != 'preferring accepted name'):
			self.matched_name = newname


	def reset(self):
		if self.fromname:
			score = self.fuzzyscore if self.toname else None
			d = dict(self.taxon.info)
			tax_ID = d['Id']
			d['Original name'], d['Original authority'] = _flatten_name(self.taxon.name)
			d['Name'], d['Authority']= _flatten_name(self.toname)
			d['Score'] = score

			d['Matched Name'] = None
			matched_name_noauth, matched_author = _flatten_name(self.matched_name)
			if matched_name_noauth is not None:
				d['Matched Name'] = "%s %s" % (matched_name_noauth, matched_author)




			d['Coded Name'] = escape_organism_name(d['Name'])
			d['Coded Authority'] = escape_organism_name(d['Authority'])
			# Replace hybrid_marker '×' with '× ' (add the missing space): added by Michal D.
			d['Name'] = handle_Species_hybrid_marker_name(d['Name'])
			d['Original name'] = handle_Species_hybrid_marker_name(d['Original name'])
			d['Matched Name'] = handle_Species_hybrid_marker_name(d['Matched Name'])

			#Save ID, score status data:
			if(FLAG_STATUS == 'Accepted'):
				ID_Accepted_dict[tax_ID]=score
			elif FLAG_STATUS == 'Synonym':
				ID_synonym_dict[tax_ID]=score
			elif FLAG_STATUS == 'Unresolved':
				ID_Unres_dict[tax_ID]=score
			self.writer.writerow(d)


		self.fromname = None
		self.toname = None
		self.taxon = None
		self.matched_name = None




#genus_name = "Iris"
#name_to_resolve = "iris lazica"

def generate_csv_with_relevant_genus(db_filename, input_filename,out_file,namefield,authfield):
	with open(input_filename, encoding='utf-8', errors='ignore') as f:
		input_taxa = load_taxa(f, namefield=namefield, authfield=authfield)


	genus_set = set()
	for name in input_taxa.names:
		species_name_parts = name.split(' ')
		genus_set.add(species_name_parts[0].strip())

	print("Using the following genera: %s " % ",".join(genus_set))
	where_clause = ""

	conn = sqlite3.connect(db_filename)
	curs = conn.cursor()

	with open(out_file,mode="w",encoding='utf8',newline='') as out_handle:
		writer = csv.writer(out_handle,delimiter=',')
		writer.writerow(['Name','Author','Accepted_name','Accepted_author'])

		add_genus_count = 0
		while len(genus_set) > 0:
			# TODO: put back with lower etc
			genus = genus_set.pop()
			#genus_ = genus.replace("'","''")
			where_clause += " OR Specie like '%s%%'" %genus
			#where_clause += " OR lower(Name) like lower('%%%s%%')" % genus
			add_genus_count += 1

			if add_genus_count > 30 or len(genus_set) == 0:
				query_by_genus = "SELECT Specie, Author,Accepted_Specie, Accepted_author, Status "\
								 "FROM Accepted_Names "\
								 "WHERE 1=0 %s" % where_clause

				print (query_by_genus)
				curs.execute(query_by_genus)
				rows = curs.fetchall()
				writer.writerows(rows)

				print("%d results were returned running query: %s " % (len(rows),query_by_genus))
				add_genus_count = 0
				where_clause = ""
	conn.close()


def generate_csv_with_relevant_syn_genus(db_filename, input_filename,out_file,namefield,authfield):
	with open(input_filename, encoding='utf-8', errors='ignore') as f:
		input_taxa = load_taxa(f, namefield=namefield, authfield=authfield)



	genus_set = set()
	for name in input_taxa.names:
		species_name_parts = name.split(' ')
		genus_set.add(species_name_parts[0].strip())

	print("Using the following genera: %s " % ",".join(genus_set))
	where_clause = ""
	conn = sqlite3.connect(db_filename)
	curs = conn.cursor()
	#query_by_genus = "SELECT Name , Author,Accepted_name, Accepted_author FROM TPL_names where lower(Name) like lower('%%%s%%')" % genus_name

	with open(out_file,mode="w",encoding='utf8',newline='') as out_handle:
		writer = csv.writer(out_handle,delimiter=',')
		writer.writerow(['Name','Author','Accepted_name','Accepted_author'])

		add_genus_count = 0
		while len(genus_set) > 0:
			# TODO: put back with lower etc
			genus = genus_set.pop()
			#genus_ = genus.replace("'","''")
			where_clause += " OR Specie like '%s%%'" %genus


			#where_clause += " OR lower(Name) like lower('%%%s%%')" % genus
			add_genus_count += 1

			if add_genus_count > 30 or len(genus_set) == 0:
				query_by_genus = "SELECT Specie, Author,Accepted_Specie, Accepted_author, Status "\
								 "FROM Synonym_Names "\
								 "WHERE 1=0 %s" % where_clause

				print (query_by_genus)
				curs.execute(query_by_genus)
				rows = curs.fetchall()
				writer.writerows(rows)

				print("%d results were returned running query: %s " % (len(rows),query_by_genus))

				add_genus_count = 0
				where_clause = ""
	conn.close()

def generate_csv_with_relevant_unresolved_genus(db_filename, input_filename,out_file,namefield,authfield):
	with open(input_filename, encoding='utf-8', errors='ignore') as f:
		input_taxa = load_taxa(f, namefield=namefield, authfield=authfield)


	genus_set = set()
	for name in input_taxa.names:
		species_name_parts = name.split(' ')
		genus_set.add(species_name_parts[0].strip())

	print("Using the following genera: %s " % ",".join(genus_set))
	where_clause = ""

	conn = sqlite3.connect(db_filename)
	curs = conn.cursor()
	#query_by_genus = "SELECT Name , Author,Accepted_name, Accepted_author FROM TPL_names where lower(Name) like lower('%%%s%%')" % genus_name


	with open(out_file,mode="w",encoding='utf8',newline='') as out_handle:
		writer = csv.writer(out_handle,delimiter=',')
		writer.writerow(['Name','Author','Accepted_name','Accepted_author'])

		add_genus_count = 0
		while len(genus_set) > 0:
			# TODO: put back with lower etc
			genus = genus_set.pop()
			#genus_ = genus.replace("'","''")
			where_clause += " OR Specie like '%s%%'" %genus


			#where_clause += " OR lower(Name) like lower('%%%s%%')" % genus
			add_genus_count += 1

			if add_genus_count > 30 or len(genus_set) == 0:
				query_by_genus = "SELECT Specie, Author,Accepted_Specie, Accepted_author, Status "\
								 "FROM Unresolved_Names "\
								 "WHERE 1=0 %s" % where_clause

				print (query_by_genus)
				curs.execute(query_by_genus)
				rows = curs.fetchall()
				writer.writerows(rows)

				print("%d results were returned running query: %s " % (len(rows),query_by_genus))

				add_genus_count = 0
				where_clause = ""
	conn.close()


def write_synonym_results(input_filename, synonym_filename,mappings_file,log_file,namefield='Name', authfield='Author'):

	with open(synonym_filename,encoding='utf8', errors='ignore') as filehandle:
		taxonset = file_csv.load_synonyms(filehandle, synnamefield='Name', synauthfield='Author',
										  accnamefield='Accepted_name', accauthfield='Accepted_author', get_info=True)

	trackers = []
	files = []
	print("Openning %s" % mappings_file)
	f = open(mappings_file, "w", encoding='utf-8', newline='')
	files.append(f)
	trackers.append(MyCSVListMatches(f,["Id"]))
	print(trackers)

	print("Openning %s" % log_file)
	f = open(log_file, "w", encoding='utf-8', newline='')
	files.append(f)
	trackers.append(tracker.CSVTracker(f))

	print("Loading taxa from input file %s" % input_filename)
	with open(input_filename, encoding='utf-8', errors='ignore') as f:
		input_taxa = load_taxa(f, namefield=namefield, authfield=authfield)

	print("Running match taxa. inpout taxa len=%d synonym len=%d" % (len(input_taxa),len(taxonset)))

	run_match_taxa (input_taxa,taxonset, tracker=trackers,nameselector=FirstNameSelector(),prefer_accepted='all')
	for f in files: f.close()


def handle_Species_hybrid_marker_name(organism_name):
	if organism_name is None:
		return None

	escaped_organism = organism_name
	escaped_organism = escaped_organism.replace("×", "× ")

	return escaped_organism


def escape_organism_name(organism_name):
	if organism_name is None:
		return None


	escaped_organism = organism_name

	escaped_organism = escaped_organism.replace("×", "x ")
	escaped_organism = escaped_organism.replace(" ", "_")
	escaped_organism = escaped_organism.replace(",", "_")
	escaped_organism = escaped_organism.replace("-", "_")
	escaped_organism = escaped_organism.replace("'", "_")
	escaped_organism = escaped_organism.replace("/", "_")
	escaped_organism = escaped_organism.replace("&", "AND")
	escaped_organism = unicodedata.normalize('NFKD', escaped_organism).encode('ascii','ignore')
	escaped_organism = str(escaped_organism, encoding='ascii')

	return escaped_organism


def checkScoreOne(score_Accepted,Score_syn,Score_Unres):
	#max score will be selected and the order is: 1st Accepted then Unresolved and last is synonym:
	list_score = []
	if score_Accepted: list_score.append(float(score_Accepted))
	if Score_syn: list_score.append(float(Score_syn))
	if Score_Unres: list_score.append(float(Score_Unres))
	if list_score:
		max_score = max(list_score)
		if score_Accepted == max_score:
			return 'Accepted'
		elif Score_syn == max_score:
			return 'Syn'
		elif Score_Unres == max_score:
			return 'Unres'
	else:
		return 'None'


def print_line_dict(line_dict,file):

	Feildes_header = ['Name','Authority','Original name','Original authority','Coded Name','Coded Authority','Score','Matched Name','Id']
	for header in Feildes_header:
		# To remove commas in feilds that might cause shifts in csv output file:
		line_dict[header]=line_dict[header].replace(',',' ')
		file.write(line_dict[header]+',')
	return

def print_Line(status_val,id_num,filenames,outfile):

	print(status_val)
	if status_val == 'Accepted':
		with open(filenames[0],'r') as f:
			reader = csv.DictReader(f)
			for Accepted_line in reader:
				if Accepted_line['Id'] == id_num:
					print_line_dict(Accepted_line,outfile)
	elif status_val == 'Syn':
		with open(filenames[1],'r') as f:
			reader = csv.DictReader(f)
			for Syn_line in reader:
				print(Syn_line['Id'])
				if Syn_line['Id'] == id_num:
					print(outfile)
					print_line_dict(Syn_line,outfile)
	elif status_val == 'Unres' or status_val == 'None':
		with open(filenames[2],'r') as f:
			reader = csv.DictReader(f)
			for Unres_line in reader:
				if Unres_line['Id'] == id_num:
					print_line_dict(Unres_line,outfile)
	else:
		print("ERROR, ERROR ,ERROR in print_Line")
		return





def do_resolve_names(db_filename,input_filename,results_filename,log_filename,namefield,authfield):

	#To continue writing to the output file with a and not w:
	global FLAG_STATUS
	# Create output file for Syn run and Unresolved run:
	base_output_file = os.path.dirname(results_filename)
	head, tail = os.path.split(results_filename)
	name_file_output_noExt = tail.replace(".csv","")
	Acc_output_f = input_filename + "_temp_AccepOut.csv"
	Syn_output_f = input_filename + "_temp_SynOut.csv"
	Unresolved_output_f = input_filename + "_temp_UnresolvedOut.csv"
	#Acc_output_f = head + "/" + name_file_output_noExt + "_AccepOut.csv"
	#Syn_output_f = head + "/" + name_file_output_noExt + "_SynOut.csv"
	#Unresolved_output_f = head + "/" + name_file_output_noExt + "_UnresolvedOut.csv"
	f_log = open(log_filename,'a')
	#if os.path.exists(log_filename):
	#	f_log = open(log_filename,'a')
	#else:
	#	f_log = open(log_filename,'w')

	# Run name res for each SELECT results: once for Accepted names, then Synonyms and Unresolved:
	f_log.write("\n\n *****************   RUNNING vs Accepted results   *****************  \n\n")
	FLAG_STATUS = 'Accepted'
	genera_accepted_csv_filename = input_filename + "-accepted.csv"
	generate_csv_with_relevant_genus(db_filename=db_filename, input_filename=input_filename,out_file=genera_accepted_csv_filename,namefield=namefield,authfield=authfield)
	write_synonym_results(input_filename=input_filename,synonym_filename = genera_accepted_csv_filename ,mappings_file = Acc_output_f,log_file = log_filename,namefield=namefield,authfield=authfield)

	f_log.write("\n\n *****************   RUNNING vs Synonyms results   *****************  \n\n")
	FLAG_STATUS = 'Synonym'
	genera_synonyms_csv_filename = input_filename + "-syn.csv"
	generate_csv_with_relevant_syn_genus(db_filename=db_filename, input_filename=input_filename,out_file=genera_synonyms_csv_filename,namefield=namefield,authfield=authfield)
	write_synonym_results(input_filename=input_filename,synonym_filename = genera_synonyms_csv_filename ,mappings_file = Syn_output_f,log_file = log_filename,namefield=namefield,authfield=authfield)


	f_log.write("\n\n *****************   RUNNING vs Unresolved results   *****************  \n\n")
	FLAG_STATUS = 'Unresolved'
	genera_unresolved_csv_filename = input_filename + "-unresolved.csv"
	generate_csv_with_relevant_unresolved_genus(db_filename=db_filename, input_filename=input_filename,out_file=genera_unresolved_csv_filename,namefield=namefield,authfield=authfield)
	write_synonym_results(input_filename=input_filename,synonym_filename = genera_unresolved_csv_filename ,mappings_file = Unresolved_output_f,log_file = log_filename,namefield=namefield,authfield=authfield)

	#Concatenate 3 files into one output file:
	filenames = [Acc_output_f, Syn_output_f, Unresolved_output_f]
	#with open(base_output_file + '/CHECK_OUT.txt', 'w') as outfile:
	keys_list = list(ID_Accepted_dict.keys())
	keys_list_int = sorted([ int(x) for x in keys_list ])
	print("LIST-----------------------------------------------\n")
	print(keys_list_int)
	with open(results_filename, 'w') as outfile:
		outfile.write("Name,Authority,Original name,Original authority,Coded Name,Coded Authority,Score,Matched Name,Id\n")
		#Go over all ids in dictionary (all 3 dict have the same ids...)
		#for id_num in ID_Accepted_dict.keys():
		for id_num in keys_list_int:
			id_num = str(id_num)
			print(id_num)
			status_oneScoreVal = checkScoreOne(ID_Accepted_dict[id_num],ID_synonym_dict[id_num],ID_Unres_dict[id_num])	# Options ->  Accepted Syn Unres or None
			print(status_oneScoreVal)
			if status_oneScoreVal is 'None':
				print_Line('Unres',id_num,filenames,outfile)	#print line from Unresolved file
			else:
				print(status_oneScoreVal)
				print(filenames)
				print(outfile)
				print_Line(status_oneScoreVal,id_num,filenames,outfile)
			outfile.write('\n')


if __name__ == "__main__":
	parser = argparse.ArgumentParser(description='Main ploiDB script - builds phylogenetic trees per genus')
	parser.add_argument('--db-filename','-d', help='SQLite DB filename containing the names from plant list', required=True)
	parser.add_argument('--input-filename','-i', help='File with the list of genera to run the matches on', required=True, default=None)
	parser.add_argument('--results-filename','-r', help='Output filename for the results', required=True, default=None)
	parser.add_argument('--log-filename','-l', help='log filename', required=True, default=None)
	parser.add_argument('--authfield','-a', help='author field. Can be name of field, True or None. \
				True means that the author is part of the name, None means there is no author and other string indicates the name of the column in the csv with the author name', required=False, default=None)

	args = parser.parse_args()

	authfield = args.authfield
	if authfield == 'None' or authfield is None:
		print ("Author field is %s. Author name is not provided at all" % authfield)
		authfield = None
	elif authfield == 'True' or authfield is True:
		print ("Author field is %s. Author name is part of the species name" % authfield)
		authfield = True
	elif authfield == 'False' or authfield is False:
		print ("Author field is %s. Not sure what it means... Don't use this False" % authfield)
		authfield = False
	else:
		print ("Author field is %s - author name will be in this column in the csv" % authfield)


	do_resolve_names(args.db_filename,args.input_filename,args.results_filename,args.log_filename,'Name',authfield)

	print(ID_Accepted_dict)
	print(ID_synonym_dict)
	print(ID_Unres_dict)
	print("end of script")



