use warnings;
use strict;
use utf8;
use 5.036;
use Getopt::Long;
use HTML::TreeBuilder;
use IO::Prompter;
use LWP::UserAgent;
use Time::Piece;
use URI;
use YAML::Tiny;
use Clone qw(clone);
use XML::RSS;
use Log::Log4perl qw(:easy);
use Encode;
use File::BaseDir qw(xdg_data_home xdg_config_home xdg_cache_home);
use File::Spec::Functions; #handle path concatenation platform-independently

use lib 'lib';
use SerialSubRssGenerator qw/addNewBook updateBooks/;
use SerialSubRssGenerator::Constants;

#use constant DEFAULT_RECORD_NAME		=> 'record.yaml';
#use constant RECORD_TIME_FORMAT			=> '%Y-%m-%d-%H-%M-%S';
#use constant PRINT_HUMAN_TIME_FORMAT	=> '%Y-%m-%d %H:%M:%S';
#use constant GENESIS					=> Time::Piece->strptime('1970-01-01-00-00-00', RECORD_TIME_FORMAT);
#use constant RSS_FOLDER					=> './rss_folder';
#use constant NEW_LINE_UTF8				=> encode("UTF-8", '\n');
#use constant XDG_DATA_DIR				=> xdg_data_home();
#use constant XDG_CONFIG_DIR				=> xdg_config_home();
#use constant XDG_CACHE_DIR				=> xdg_cache_home();


my $cliRecordFile;
my $verbose;
my $automation;
#TODO cli help
my $help;
my $rssFolderPath=DEFAULT_RSS_FOLDER;
my $fetchGap;
my $logFilePath=DEFAULT_LOG_FILE_NAME;
my $useXDG;
my $otherConfigFilePath=DEFAULT_CONFIG_FILE_NAME;


GetOptions(
	'c|config=s'	=> \$otherConfigFilePath,
	'R|record=s'	=> \$cliRecordFile,
	'f|feed-path=s'	=> \$rssFolderPath,
	'g|fetch-gap=i'	=> \$fetchGap,
	'v|verbose'		=> \$verbose,
	'h|help'		=> \$help,
	'lf|logfile=s'	=> \$logFilePath,
	'a|auto'		=> \$automation,
	'xdg'			=> \$useXDG,
) or die "Unknown option!\n";

# First things first, initial logger
Log::Log4perl->easy_init({
		level	=> $INFO,
		file	=> $logFilePath,
	});

INFO("Started at ".localtime->strftime(PRINT_HUMAN_TIME_FORMAT));

# Second things second, load config
my $otherConfig={
	FetchGap		=> DEFAULT_FETCH_GAP,
	UserAgent		=> DEFAULT_USER_AGENT,
};

if (-e $otherConfigFilePath) {
	my $otherConfigYaml=YAML::Tiny->read($otherConfigFilePath)->[0];
	foreach (keys %$otherConfigYaml){
		if (exists $otherConfig->{$_}){
			$otherConfig->{$_}=$otherConfigYaml->{$_};
			INFO("Changed $_ from default to $otherConfigYaml->{$_} from $otherConfigFilePath");
		} else {
			WARN("$otherConfigYaml->{$_} from $otherConfigFilePath is a unknown option. Omitted.");
		}
	}
} 



# Third and last: stupid-bang starts

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
$userAgent->agent($otherConfig->{UserAgent});

#Proxy
#TODO: customized proxy config
my $useSystemProxy=prompt -yn, 'Do you want to use system proxy?';
if ($useSystemProxy =~/^(y|yes)$/i) {
	$userAgent->env_proxy; #use proxy
}

# create record.yaml if not exist, and trigger first book addition
unless (-e $recordFile){
	my $createRecordFileInput = prompt "File '$recordFile' does not exist. Do you want to create a new one? (y/n)\n", -yn;
	if ($createRecordFileInput =~/^(y|yes)$/i) {
		my $yaml=YAML::Tiny->new();
		my $rss=XML::RSS->new(version => '2.0');
		my $newBook=clone($bookTemplate);
		($newBook,$rss)=&addNewBook($newBook,$otherConfig);
		push @$yaml, $newBook;
		my $rssFileName=$rss->channel('title').'.rss';
		$yaml->write($recordFile) or die ("Failed to save to $recordFile");
		$rss->save(catfile($rssFolderPath, $rssFileName) ) or die ("Failed to save to $rssFolderPath$rssFileName");
	} else {
		say "No '$recordFile' found or created, exiting.";
		exit;
	}
} else {
	#update books if record file found
	INFO("Find record file $recordFile.");
	my $yaml=YAML::Tiny->read("$recordFile");
	foreach my $targetBook (@{$yaml}){
		INFO("Find book entry $targetBook->{Title}.");
		my $rss=XML::RSS->new(version => 2.0);
		my $rssFileName=$targetBook->{Title}.".rss";
		my $rssFile=catfile($rssFolderPath,$rssFileName);
		if (-e $rssFile){
			INFO("Find rss file $rssFile.");
			$rss->parsefile($rssFile);
		} else{
			INFO("Rss file $rssFile not found, created one.");
			$rss->channel(
				title	=> "$targetBook->{Title}",
				link	=> "$targetBook->{ContentPageUrl}",
			);
		}
		#TODO:support limit rss entries per file
		my $updatedTargetBook;
		($targetBook, $rss)=&updateBooks($targetBook,$rss,$otherConfig);
		INFO("Update RSS file at ".$rssFolderPath.$rssFileName);
		TRACE("Content of RSS string is:\n".$rss->as_string);
		$rss->save($rssFile) or die ("Failed to save to $rssFile");
	}
	$yaml->write($recordFile);
}

