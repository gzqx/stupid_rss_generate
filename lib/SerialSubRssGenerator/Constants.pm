package SerialSubRssGenerator::Constants;
our $VERSION = '0.01';

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

use Const::Exporter;
 

my $recordTimeFormat = '%Y-%m-%d-%H-%M-%S';

my %constants = (
    'DEFAULT_RECORD_NAME'		=> 'record.yaml',
    'RECORD_TIME_FORMAT'		=> $recordTimeFormat,
    'PRINT_HUMAN_TIME_FORMAT'	=> '%Y-%m-%d %H:%M:%S',
    'GENESIS'					=> Time::Piece->strptime('1970-01-01-00-00-00', $recordTimeFormat),
    'DEFAULT_RSS_FOLDER'		=> './rss_folder',
    'NEW_LINE_UTF8'				=> encode("UTF-8", '\n'),
    'XDG_DATA_DIR'				=> xdg_data_home(),
    'XDG_CONFIG_DIR'			=> xdg_config_home(),
    'XDG_CACHE_DIR'				=> xdg_cache_home(),
 );

 Const::Exporter->import(
     constants  => [%constants],
     default    => [keys %constants],
 );

 1;
