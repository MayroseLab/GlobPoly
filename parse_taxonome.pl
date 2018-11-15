# parseTaxonome gets the output of Taxonome and parses it
# args: (1)original file (2)resolved names (3)output file (4) Working genus (5) cropt list

use strict;
use Text::CSV_XS;

my $csv = Text::CSV_XS->new( {binary => 1 } );

#read the two files
my ($dir,$originalFile,$resolvedFile,$outputFile,$workingGenus,$cropsList)=@ARGV;
print("$dir\n");
chdir($dir);

open (IN1, "< $originalFile") or die "can't open $originalFile";
open(IN2, "< $resolvedFile") or die "can't open $resolvedFile";
open(IN3, "< $cropsList") or die "can't open $cropsList";

my ($line,%names,%cropNames,@tempArr,%wrong_names);
$line=<IN2>;

# insert the crops list to a hash
while ($line=<IN3>){
	if ($csv->parse($line))	{	
		my @columns = $csv->fields();
		my $cropName=$columns[0];
		$cropNames{$cropName}="";
	}
}
close (IN3);

#insert the resolved file to a hash
while ($line=<IN2>){
	if ($csv->parse($line))	{	
		my @columns = $csv->fields();
		my $score=$columns[6];
		my $id = $columns[2]; #actually, this is not ID, it is the original name
		my $name = $columns[4]; 
		@tempArr=split(/_/,$name);
		my $genus=$tempArr[0]; my $species=$tempArr[1];
		# if name is not empty AND score is above 0.8 AND there is a score AND the genus matches the current genus AND the species is not a crop species
		if (defined $score){
			if (($name ne "")and (($score gt "0.8") or ($score eq "0.8")) and ($genus eq $workingGenus) and (not exists $cropNames{$columns[0]})){
				#$name=~s/[\s\,\-\"\/\&]/_/g;
				$names{$id}=$name;
			}
			elsif (($genus ne $workingGenus) and ($genus ne "")){
				$wrong_names{$id}=$name;
			}
		}
	}
}
close (IN2);

open (my $out,">$outputFile") or die "can't open $outputFile";
$line=<IN1>;
print $out "$line";

my $out_wrong_names;
if (%wrong_names){
	open ($out_wrong_names,">$dir"."/NR_leftovers.csv") or die "can't open NR_leftovers.csv";
}

#go over all lines of the original file and look for their IDs in the hash
while ($line=<IN1>){
	if ($csv->parse($line))	{	
		my @columns = $csv->fields();
		my $id = $columns[2];
		#my $name = $columns[1];
		if (exists $names{$id}){ # see if the name was resolved properly
				$columns[2]=$names{$id};
				$csv->print($out, \@columns);
				print $out "\n";
		}
		elsif (exists $wrong_names{$id}) { # if it wasn't - see that it doesn't belong to another genus
			@tempArr=split(/_/,$wrong_names{$id});
			my $genus=$tempArr[0];
			$columns[1]= $genus;
			$columns[2]=$wrong_names{$id};
			$csv->print($out_wrong_names, \@columns);
			print $out_wrong_names "\n";
		}
		else {
			next;
		}
	}	
}

if (%wrong_names){
	close ($out_wrong_names);
}
close (IN1);
close $out;