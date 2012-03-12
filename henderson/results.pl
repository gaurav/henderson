
=head1 NAME

results.pl - Calculate result statistics for an XML file.

=cut

use v5.010;
use strict;
use warnings;

use XML::XPath;
use XML::XPath::XMLParser;

use Statistics::Descriptive;

die "No argument provided: please provide the filename to process" unless exists $ARGV[0];
my $xp = XML::XPath->new($ARGV[0]) or die "Could not open '$ARGV[0]'.";

my $root = @{$xp->find('/transcription')}[0];
my $nodeset = $xp->find('/transcription/page');

binmode(STDOUT, ":utf8");

my $annotations = Statistics::Descriptive::Full->new();
my $annotation_dateds = Statistics::Descriptive::Full->new();

my $str = "";
my @nodes = @{$nodeset};

my $page_no = 0;
for my $node (@nodes) {
    $page_no++;

    my $title = $node->getAttribute('title');
    my $uri = $node->getAttribute('uri');

    my $annotation_entries = $xp->find('annotations/attribute', $node);
    my $num_annotations = scalar @$annotation_entries;
    $annotations->add_data($num_annotations);

    for my $annotation (@$annotation_entries) {
        my $key = $annotation->getAttribute('key');
        my $value = $annotation->getAttribute('value')

        $value = mktime(
    }

    my $content = $node->getChildNode(2);
    die "No content node present" unless defined $content;

    say STDERR "$page_no, $num_annotations";
}

say "Summary for " . $root->getAttribute('title');

say "\tNumber of pages: " . (scalar @nodes);
say "\tNumber of annotations: " . $annotations->sum() . 
    (sprintf(" (%g/page with sd=%g)", $annotations->mean(), $annotations->standard_deviation()));
say "\tNumber of date annotations: " . $annotation_dateds->count();
