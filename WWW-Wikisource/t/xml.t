#!perl -T

# Tests XML export.

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
print OUTPUT $xml;
close(OUTPUT);

diag "XML output written to $filename.";
pass("Reached the end");
