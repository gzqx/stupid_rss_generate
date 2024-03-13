#package STUPID::RSS_GENERATOR 0.01;
$VERSION=0.01;

use warnings;
use strict;
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
use XML::RSS;
use Log::Log4perl qw(:easy);
use Encode;
use File::BaseDir qw(xdg_data_home xdg_config_home xdg_cache_home);
use File::Spec qw(catdir); #handle path concatenation platform-independently


use constant DEFAULT_RECORD_NAME		=> 'record.yaml';
use constant RECORD_TIME_FORMAT			=> '%Y-%m-%d-%H-%M-%S';
use constant PRINT_HUMAN_TIME_FORMAT	=> '%Y-%m-%d %H:%M:%S';
use constant GENESIS					=> Time::Piece->strptime('1970-01-01-00-00-00', RECORD_TIME_FORMAT);
use constant RSS_FOLDER					=> './rss_folder';
use constant NEW_LINE_UTF8				=> encode("UTF-8", '\n');
use constant XDG_DATA_DIR				=> xdg_data_home();
use constant XDG_CONFIG_DIR				=> xdg_config_home();
use constant XDG_CACHE_DIR				=> xdg_cache_home();


my $cliRecordFile;
my $verbose=1;
my $automation;
my $help;
my $rssFolderPath='./rss/';
my $fetchGap=20;
my $LOG_FILE_PATH='.stupid_rss_generator.log';
my $useXDG=0;


GetOptions{
	'R|record=s'	=> \$cliRecordFile,
	'f|feed-path=s'	=> \$rssFolderPath,
	'g|fetch-gap=i'	=> \$fetchGap,
	'v|verbose'		=> \$verbose,
	'h|help'		=> \$help,
	'lf|logfile=s'	=> \$LOG_FILE_PATH,
	'a|auto'		=> \$automation,
	'xdg'			=> \$useXDG,
} or die "Unknown option!\n";

# First things first, initial logger
Log::Log4perl->easy_init({
		level	=> $INFO,
		file	=> $LOG_FILE_PATH,
	});

unless (-d $rssFolderPath){
	mkdir $rssFolderPath or die "Failed to create $rssFolderPath.";
	say "$rssFolderPath not exist. Created One.";
}



#book yaml template
my $bookTemplate={
	Title							=> '',
	Author							=> '',
	ContentPageUrl 					=> '',
	LastChapterFetched				=> '0',
	CreationTime					=> GENESIS->strftime(RECORD_TIME_FORMAT),
	LastFetchTime					=> GENESIS->strftime(RECORD_TIME_FORMAT),
	LastCheckTime					=> GENESIS->strftime(RECORD_TIME_FORMAT),
	HashOfTitle						=> '',
	RegrexForTitle					=> '',
	RegrexForChapterLinkAndNumber	=> '',
	RegrexForChapterNumber			=> '',
	RegrexForChapterTitle			=> '',
	RegrexForText					=> '',
	RSSFeed							=> '',
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
		my $yaml=YAML::Tiny->new();
		my $rss=XML::RSS->new(version => '2.0');
		my $newBook=clone($bookTemplate);
		($newBook,$rss)=&addNewBook($newBook);
		push @$yaml, $newBook;
		my $rssFileName=$rss->channel('title').'.rss';
		$yaml->write($recordFile) or die ("Failed to save to $recordFile");
		$rss->save(catdir($rssFolderPath, $rssFileName) ) or die ("Failed to save to $rssFolderPath$rssFileName");
	} else {
		say "No '$recordFile' found or created, exiting.";
		exit;
	}
} else {
#update books if record file found
	my $yaml=YAML::Tiny->read("$recordFile");
	foreach my $targetBook (@{$yaml}){
		my $rss=XML::RSS->new(version => 2.0);
		my $rssFileName=$targetBook->{Title}.".rss";
		if (-e $rssFolderPath.$rssFileName){
			$rss->parsefile($rssFolderPath.$rssFileName);
		} else{
			$rss->channel(
				title	=> "$targetBook->{Title}",
				link	=> "$targetBook->{ContentPageUrl}",
			);
		}
		#TODO:support limit rss entries per file
		my $updatedTargetBook;
		($targetBook, $rss)=&updateBooks($targetBook,$rss);
		INFO("Update RSS file at ".$rssFolderPath.$rssFileName);
		TRACE("Content of RSS string is:\n".$rss->as_string);
		$rss->save($rssFolderPath.$rssFileName) or die ("Failed to save to $rssFolderPath$rssFileName");
	}
	$yaml->write($recordFile);
}


sub addNewBook{
	#TODO: add new book to existing yaml
	my $newBook=pop @_;

	$newBook->{CreationTime}=localtime->strftime(RECORD_TIME_FORMAT);
	
	my $contentUrlInput= prompt -v, "Input the link to the content page:\n";
	#format uri
	my $contentUrl=URI->new($contentUrlInput);
	if (not $contentUrl->scheme) {
		say ("Using https by default. If you want http connection, specify it in the link");
		$contentUrl->scheme('https'); #use https unless user specified http
	}
	#create RSS template
	my $rssNewBook=XML::RSS->new(version => '2.0');
	
	#file newbook content
	$newBook->{ContentPageUrl}=$contentUrl->as_string;
	#TODO Reuse regrex from same domain
	$newBook->{RegrexForTitle}=prompt -v, "Input the regrex for extracting the book title from content page:\n";
	$newBook->{RegrexForChapterLinkAndNumber}=prompt -v, "Input the regrex for extracting the Chapter Link and Number from content page:\n";
	$newBook->{RegrexForChapterTitle}=prompt -v, "Input the regrex for extracting the Chapter Title from text page:\n";
	$newBook->{RegrexForText}=prompt -v, "Input the regrex for extracting the text from text page:\n";

	($newBook,$rssNewBook)=&updateBooks($newBook,$rssNewBook);
	return ($newBook, $rssNewBook);
}

sub updateBooks{
	my ($targetBook,$rssBook)=@_;

	#get content page
	my $contentPageResponse=$userAgent->get($targetBook->{ContentPageUrl});
	if ($contentPageResponse->is_success) {
		my $contentPageContent=$contentPageResponse->decoded_content;
		# if it is a new book
		if ($targetBook->{Title} eq "" && $contentPageContent =~/$targetBook->{RegrexForTitle}/){
			$targetBook->{Title} = $1; 
			INFO("Title of book is $targetBook->{Title}");
			$rssBook->channel(
				title			=> "$targetBook->{Title}",
				link			=> "$targetBook->{ContentPageUrl}",
				pubDate			=> localtime->strftime(RECORD_TIME_FORMAT),
				lastBuildDate	=> localtime->strftime(RECORD_TIME_FORMAT),
			);
		}
		while($contentPageContent =~/$targetBook->{RegrexForChapterLinkAndNumber}/g){
			#TODO: Handle Chinese number with Lingua::ZH::Numbers
			#TODO: Handle situation when link and number is not in same line or link somehow managed to come after chapter number
			my $chapterLink=$1;
			INFO("Chapter link is $chapterLink");
			my $chapterCounter = $2;
			INFO("Chapter checked is No.$chapterCounter");

			#fetch new chapter if there is any
			if ($chapterCounter > $targetBook->{LastChapterFetched}){
				my $textPageResponse=$userAgent->get($chapterLink);
				if ($textPageResponse->is_success){
					my $textPageContent=$textPageResponse->decoded_content;
					#get chapter title
					my $chapterTitle='';
					if ($textPageContent =~/$targetBook->{RegrexForChapterTitle}/){
						$chapterTitle=$1;
						INFO("Chapter Title is $chapterTitle");
					}else{
						say "Failed to get chapter title. Check your regrex.";
						ERROR("Failed to get chapter title with regrex:\n".$targetBook->{RegrexForChapterTitle});
					}
					#get chapter text
					my $text='<![CDATA[';
					while ($textPageContent=~/$targetBook->{RegrexForText}/g){
						$text.="<p>".$1."</p>";
						#&vsay("Get a new line of text as: \n $text");
					}
					$text.="]]>";
					$rssBook->add_item(
						title		=> "$chapterTitle",
						link		=> "$chapterLink",
						description	=> "$text",
						pubDate		=> localtime->strftime(RECORD_TIME_FORMAT),
					);
				}
				$targetBook->{LastChapterFetched}++;
				sleep($fetchGap); #Prevent been blocked for too much request
			}
		}
	}else{
		say ("Timeout when requesting content page, check your url or internet connection.");
	}
	return ($targetBook,$rssBook);
}

