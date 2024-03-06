use Module::Metadata;
use ExtUtils::MakeMaker;

my %prereqs;

my @modules = qw(Getopt::Long HTML::TreeBuilder IO::Prompter LWP::UserAgent Time::Piece URI YAML::Tiny Clone Lingua::ZH::Numbers XML::RSS);

foreach my $module (@modules) {
    my $version = Module::Metadata->new_from_module($module)->version();
    $prereqs{$module} = $version if $version;
}

WriteMakefile(
    NAME         => 'STUPID::RSS_GENERATOR',
    VERSION_FROM => 'stupid_rss_generator.pl',
    PREREQ_PM    => \%prereqs,
);
