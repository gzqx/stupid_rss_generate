use warnings;
use utf8;
use 5.027;
use Getopt::Long;
use HTML::TreeBuilder;
use IO::Prompter;
use LWP::UserAgent;
use Time::Piece;
use URI;
use YAML::Tiny;

use constant DEFAULT_RECORD_NAME	=> 'record.yaml';
use constant TIME_FORMAT			=> '%Y-%m-%d-%H-%M-%S';
use constant GENESIS				=> '1970-01-01-00-00-00';

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

#book yaml template
my $bookTemplate={
	Title				=> '',
	Author				=> '',
	ContentPage 		=> '',
	LastChapterFetched	=> '',
	LastFetchTime		=> '',
	LastCheckTime		=> '',
	HashOfTitle			=> '',
};

my $recordFile=DEFAULT_RECORD_NAME;

# If recordfile is passed through argument
if ($cliRecordFile){
	$recordFile=$cliRecordFile;
}

#TODO: what to do if recordfile do exit

#create user agent
#TODO: customize agent
my $userAgent=LWP::UserAgent->new(timeout => 10);
$userAgent->agent('Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/119.0');

#Proxy
#TODO: customized proxy config
my $useSystemProxy=prompt -yn, 'Do you want to use system proxy?';
if ($useSystemProxy =~/^(y|yes)$/i) {
	$userAgent->env_proxy; #use proxy
}

# create record.yaml if not exist, and trigger first book addition
unless (-e $recordFile){
	my $createRecrodFileInput = prompt "File '$recordFile' does not exist. Do you want to create a new one? (y/n)", -yn;
	print "\n";
	if ($createRecrodFileInput =~/^(y|yes)$/i) {
		my $yaml=YAML::Tiny->new;
		$yaml=&addNewBook($yaml);
		$yaml->write($recordFile);
	} else {
		say "No '$recordFile' found or created, exiting.";
		exit;
	}
}


sub addNewBook{
	my $yaml=pop @_;
	my $contentUrlInput= prompt "Input the link to the content page:";
	#format uri
	my $contentUrl=URI->new($contentUrlInput);
	if (not $contentUrl->scheme) {
		say ("Using https by default. If you want http connection, specify it in the link");
		$contentUrl->scheme('https'); #use https unless user specified http
	}
	#test url
	my $contentPageResponse=$userAgent->get($contentUrl);
	if($contentPageResponse->is_success) {
		$contentPageResponse->decoded_content;
		my $contentPageTree=HTML::TreeBuilder->new_from_content($contentPageResponse);
	}else{
		say ("Timeout, check your url or internet connection.");
	}

	#create template copy

}

sub updateBooks{
	#download content page
	my ($contentUrl)=@_;
	my $contentPageResponse=$userAgent->get($contentUrl);
	if($contentPageResponse->is_success) {
	}
	print "\n";
}
