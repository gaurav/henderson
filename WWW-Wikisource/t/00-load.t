#!perl -T
#
# Boilerplate load code to check that the modules can be loaded.
#

use Test::More tests => 3;

BEGIN {
    use_ok( 'WWW::Wikisource' ) || print "Bail out!";
    use_ok( 'WWW::Wikisource::Page' ) || print "Bail out!";
    use_ok( 'WWW::Wikisource::IndexPage' ) || print "Bail out!";
}

diag( "Testing WWW::Wikisource $WWW::Wikisource::VERSION, Perl $], $^X" );
