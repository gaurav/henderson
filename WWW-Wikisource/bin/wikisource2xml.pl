#!perl -T

# Does XML download, badly.

use strict;
use warnings;

use Data::Dumper;
use Try::Tiny;

use WWW::Wikisource;

my $ws = WWW::Wikisource->new();

die "No title provided for download!" unless defined $ARGV[0];
my $index_page = $ws->get_index($ARGV[0]);

my $xml = $index_page->as_xml();

binmode(STDOUT, ":utf8");
print STDOUT $xml;
