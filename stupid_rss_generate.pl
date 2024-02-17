use warnings;
use utf8;
use 5.027;
use YAML::Tiny;
use IO::Prompter;
use Getopt::Long;

my $cliRecordFile;
my $verbose;
my $automation;
my $help;

GetOptions{
	'R|record=s'	=> \$cliRecordFile,
	'v|verbose'		=> \$verbose,
	'h|help'		=> \$help,
	'a|auto'		=> \$automation,
} or die "Unknown option!\n";

my $recordFile='record.yaml';
if ($cliRecordFile){
	$recordFile=$cliRecordFile;
}

unless (-e $recordFile){
	my $input= prompt "File '$recordFile' does not exit. Do you want to create a new one? (y/n)", -re=>'^(y|yes|n|no)$';
	if ($input =~/^(y|yes)$/i) {
		&addNewBook();
	} else {
		exit;
	}
}

sub addNewBook{
	my $yaml=YAML::Tiny->new;
	my $contentUrlInput= prompt "Input the link to the content pate:";


	$yaml->write($recordFile);
}

