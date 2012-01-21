#!perl -T

use strict;
use warnings;
use Test::More tests => 4;

use Data::Dumper;
use Try::Tiny;

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
try {
    $ws->get_index('Index:AAAAAAAAAAAAAar198281.djvu');
    fail("Invalid index page did not throw an exception.");
} catch {
    unless(/Index page .* could not be found/) {
        fail("Incorrect exception thrown when looking up index page: $_");
    } else {
        pass("Index page could not be found exception through correctly.");
    }
};

my $index = $ws->get_index('Index:Field Notes of Junius Henderson, Notebook 1.djvu');
diag $index->dump();

my @pages = $index->get_all_pages();
is(scalar(@pages), $index->{'page_count'}, "All pages loaded for index.");
# diag Dumper({pages => @pages});
diag "First page: " . Dumper($pages[0]);
diag "Last page: " . Dumper($pages[$#pages]);
