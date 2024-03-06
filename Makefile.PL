use inc::Module::Install;

name            'STUPID RSS GENERATOR';
abstract        '42';
author          'Arthur Dent';
include         'Module::AutoInstall';
version_from    'stupid_rss_generator.pl';

requires    
    'Getopt::Long'				=> '2.54',
    'Clone'						=> '0.46',
    'Lingua::ZH::Numbers'		=> '0.04',
    'LWP::UserAgent'			=> '6.76',
    'Time::Piece'				=> '1.3401',
    'HTML::TreeBuilder'			=> '5.07',
    'XML::RSS'					=> '1.63',
    'IO::Prompter'				=> '0.005001',
    'YAML::Tiny'				=> '1.74',
    'URI'						=> '5.27';
auto_install(
    -skiptest   => 1,
    force       => 1,
    do_once     => 1,
);

WriteAll;
