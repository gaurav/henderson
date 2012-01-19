#!perl -T

use strict;
use warnings;
use Test::More tests => 4;

use Data::Dumper;

use WWW::Wikisource;

my $ws = WWW::Wikisource->new();
isa_ok($ws, 'WWW::Wikisource');

# Test a non-existent page.
my $blank = $ws->get('1249293019201929290191020910129100');
is($blank, undef, "Non-existent page not found on Wikisource");

# Test a normal page.
my $page = $ws->get('Field_Notes_of_Junius_Henderson/Notebook_1');
is($page->{'title'}, 'Field Notes of Junius Henderson/Notebook 1');
is($page->{'ns'}, 0, "Is this page in the article (0) namespace");

# Test an index page.
my $index = $ws->get('Index:Field Notes of Junius Henderson, Notebook 1.djvu');
diag Dumper($index);

