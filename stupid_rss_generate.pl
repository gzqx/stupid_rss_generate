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
use Clone qw(clone);
use Lingua::ZH::Numbers;

use constant DEFAULT_RECORD_NAME		=> 'record.yaml';
use constant RECORD_TIME_FORMAT			=> '%Y-%m-%d-%H-%M-%S';
use constant PRINT_HUMAN_TIME_FORMAT	=> '%Y-%m-%d %H:%M:%S';
use constant GENESIS					=> Time::Piece->strptime('1970-01-01-00-00-00', RECORD_TIME_FORMAT);

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
	Title					=> '',
	Author					=> '',
	ContentPageUrl 			=> '',
	LastChapterFetched		=> '0',
	LastFetchTime			=> GENESIS->strftime(RECORD_TIME_FORMAT),
	LastCheckTime			=> GENESIS->strftime(RECORD_TIME_FORMAT),
	HashOfTitle				=> '',
	RegrexForTitle			=> '',
	RegrexForChapterNumer	=> '',
	RegrexForChapterTitle	=> '',
	RegrexForText			=> '',
};


my $recordFile=DEFAULT_RECORD_NAME;

# If recordfile is passed through argument
if ($cliRecordFile){
	$recordFile=$cliRecordFile;
}


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
	my $createRecrodFileInput = prompt "File '$recordFile' does not exist. Do you want to create a new one? (y/n)\n", -yn;
	if ($createRecrodFileInput =~/^(y|yes)$/i) {
		my $yaml=YAML::Tiny->new;
		$yaml=&addNewBook($yaml);
		$yaml->write($recordFile);
	} else {
		say "No '$recordFile' found or created, exiting.";
		exit;
	}
}

#TODO: what to do if recordfile do exit

sub addNewBook{
	my $yaml=pop @_;
	my $contentUrlInput= prompt "Input the link to the content page:\n";
	#format uri
	my $contentUrl=URI->new($contentUrlInput);
	if (not $contentUrl->scheme) {
		say ("Using https by default. If you want http connection, specify it in the link");
		$contentUrl->scheme('https'); #use https unless user specified http
	}
	#create template copy
	my $newBook=clone($bookTemplate);
	$newBook->{ContentPageUrl}=$contentUrl;
	#TODO Reuse regrex from same domain
	$newBook->{RegrexForTitle}=prompt "Input the regrex for extracting the book title.\n";
	$newBook->{RegrexForChapterTitle}=prompt "Input the regrex for extracting the Chapter Title.\n";
	$newBook->{RegrexForText}=prompt "Input the regrex for extracting the text.\n";
	&updateBooks($newBook);
}

sub updateBooks{
	#download content page
	my ($targetBook)=@_;

	#get content page
	my $contentPageResponse=$userAgent->get($targetBook->{ContentPageUrl});
	if ($contentPageResponse->is_success) {
		my $contentPageContent=$contentPageResponse->decoded_content;
		if ($targetBook->{Title} eq "" && $contentPageContent =~/$targetBook->{RegrexForTitle}/){
			$targetBook->{Title} = \$1; #get title if no title
		}
		#get last chapter
		my $maxChapterNumber=0;
		while($contentPageContent =~/$targetBook->{RegrexForChapterNumer}/){
			#TODO: Handle Chinese number
			my $chapterCounter = \$1;
			$maxChapterNumber = $chapterCounter if $chapterCounter > $maxChapterNumber;
		}
		if($targetBook->{LastChapterFetched}<$maxChapterNumber){
			&fetchChapters();
		}
		
	}else{
		say ("Timeout, check your url or internet connection.");
	}
}

sub	fetchChapters{
	#TODO
}
