use Module::Metadata;
use ExtUtils::MakeMaker;

my %prereqs;


WriteMakefile(
    NAME         => 'STUPID::RSS_GENERATOR',
    VERSION_FROM => 'stupid_rss_generator.pl',
    PREREQ_PM    => {
        'Getopt::Long' => 2.54,
        'Clone' => 0.46,
        'Lingua::ZH::Numbers' => 0.04,
        'LWP::UserAgent' => 6.76,
        'Time::Piece' => 1.3401,
        'HTML::TreeBuilder' => 5.07,
        'XML::RSS' => 1.63,
        'IO::Prompter' => 0.005001,
        'YAML::Tiny' => 1.74,
        'URI' => 5.27,
    },
);
