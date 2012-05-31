#!perl -T
# 
# xml.t
#
# Tests XML export; however, it really just does an XML export and sees if the
# process dies. If we ever develop an XSD, we can validate that against the
# produced XML file and see if that worked.
#

use strict;
use warnings;
use Test::More tests => 1;

use Data::Dumper;
use Try::Tiny;

use WWW::Wikisource;

my $ws = WWW::Wikisource->new();
my $index_page = $ws->get_index('Index:Field Notes of Junius Henderson, Notebook 1.djvu');

my $xml = $index_page->as_xml();
my $filename = '/tmp/output.xml';

open(OUTPUT, '>', $filename) or die ("Could not open 'output.xml' for output.");
binmode(OUTPUT, ":utf8");
print OUTPUT $xml;
close(OUTPUT);

diag "XML output written to $filename.";
pass("Reached the end");
