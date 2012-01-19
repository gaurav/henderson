use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Wikisource',
    license             => 'perl',
    dist_author         => q{Gaurav Vaidya <gaurav@ggvaidya.com>},
    dist_version_from   => 'lib/WWW/Wikisource.pm',
    build_requires => {
        'Test::More' => 0,
        'Try::Tiny' => 0,
        'Carp' => 0,
        'MediaWiki::API' => 0
    },
    add_to_cleanup      => [ 'WWW-Wikisource-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
