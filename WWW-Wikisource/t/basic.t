#!perl -T
#
# basic.t
#
# This test file checks whether WWW::Wikisouce can retrieve Page and IndexPage objects
# from Wikisource. Pages on the internet used in this test is:
#
# Conventional page:
#   http://en.wikisource.org/wiki/Field_Notes_of_Junius_Henderson/Notebook_1
# 
# Index page:
#   http://en.wikisource.org/wiki/Index:Field Notes of Junius Henderson, Notebook 1.djvu
#   (the module handles URL-encoding)
#

use strict;
use warnings;
use Test::More tests => 5;

use Data::Dumper;
use Try::Tiny;

use WWW::Wikisource;

my $ws = WWW::Wikisource->new();

# Check whether WWW::Wikisource was initialized correctly.
isa_ok($ws, 'WWW::Wikisource');

# Test a non-existent page; this should return undef.
my $blank = $ws->get('1249293019201929290191020910129100');
is($blank, undef, "Non-existent page not found on Wikisource");

# Test a normal page, and check whether the title and namespace
# parameters are loaded correctly.
my $page = $ws->get('Field_Notes_of_Junius_Henderson/Notebook_1');
is($page->title(), 'Field Notes of Junius Henderson/Notebook 1');
is($page->ns(), 0, "Is this page in the article (0) namespace");

# Test a non-existent Index page.
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

# Test an existing page.
my $index_page = $ws->get_index('Index:Field Notes of Junius Henderson, Notebook 1.djvu');

if(0) {
    # These lines can provide more information about this page; but
    # these are not needed for basic testing.
    diag $index_page->dump();

    my $first_page = $index_page->get_page(1);
    diag "Edits made to $first_page: " . Dumper($first_page->revisions());
    diag "Editors who have worked on $first_page: " . Dumper($first_page->all_editors());

    diag "Editorial stats for $index_page: " . Dumper($index_page->get_all_editors_with_revisions());
}

# Retrieve a particular page number from the index page.
$page = $index_page->get_page(3);
diag "Annotations for dated: " . join(", ", @{$page->get_annotations("dated")});
diag "Annotations for taxa: " . join(", ", @{$page->get_annotations("taxon")});
diag "Annotations for place: " . join(", ", @{$page->get_annotations("place")});

# Test permanent URL.
diag "Permanent URL: " . $page->permanent_url();
TODO: {
    local $TODO = "Need to develop a permanent URL test.";
    fail("No permanent URL test yet.");
}

# You can also retrieve all pages at this point, if you like.
if(0) {
    my @pages = $index_page->get_all_pages();
    foreach my $page (@pages) {
       diag "Page $page.\n" . $page->content();
       diag "\n\n";
    }
}

1;
