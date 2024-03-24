package SerialSubRssGenerator::Constants;
use strict;
use warnings;
our $VERSION = '0.01';

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
use Lingua::ZH::Numbers;
use XML::RSS;
use Log::Log4perl qw(:easy);
use Encode;
use File::BaseDir qw(xdg_data_home xdg_config_home xdg_cache_home);
use File::Spec qw(catdir); #handle path concatenation platform-independently

use Const::Exporter;
 

my $recordTimeFormat = '%Y-%m-%d-%H-%M-%S';

my %constants = (
    'DEFAULT_FETCH_GAP'         => 20,
    'DEFAULT_RECORD_NAME'		=> 'record.yaml',
    'DEFAULT_RSS_FOLDER'		=> './rss',
    'DEFAULT_USER_AGENT'        => 'Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/119.0',
    'GENESIS'					=> Time::Piece->strptime('1970-01-01-00-00-00', $recordTimeFormat),
    'NEW_LINE_UTF8'				=> encode("UTF-8", '\n'),
    'PRINT_HUMAN_TIME_FORMAT'	=> '%Y-%m-%d %H:%M:%S',
    'RECORD_TIME_FORMAT'		=> $recordTimeFormat,
    'XDG_CACHE_DIR'				=> xdg_cache_home(),
    'XDG_CONFIG_DIR'			=> xdg_config_home(),
    'XDG_DATA_DIR'				=> xdg_data_home(),
    'DEFAULT_CONFIG_FILE_NAME'  => '.config.yaml',
    'DEFAULT_LOG_FILE_NAME'     => '.stupid_rss_generator.log',
 );

 Const::Exporter->import(
     constants  => [%constants],
     default    => [keys %constants],
 );

 1;
