#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Wikisource' ) || print "Bail out!
";
}

diag( "Testing WWW::Wikisource $WWW::Wikisource::VERSION, Perl $], $^X" );
