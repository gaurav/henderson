
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

my $count_annotations = Statistics::Descriptive::Full->new();
my $count_dateds = Statistics::Descriptive::Full->new();
my $count_taxa = Statistics::Descriptive::Full->new();
my $count_places = Statistics::Descriptive::Full->new();
my $count_editors = Statistics::Descriptive::Full->new();

my $dateds = Statistics::Descriptive::Full->new();
my $taxa = Statistics::Descriptive::Full->new();
my $places = Statistics::Descriptive::Full->new();

my %editors_pages_edited;
my %editors_contributions;

my $str = "";
my @nodes = @{$nodeset};

my $page_no = 0;
for my $node (@nodes) {
    $page_no++;

    my $title = $node->getAttribute('title');
    my $uri = $node->getAttribute('uri');

    my $annotation_entries = $xp->find('annotations/attribute', $node);

    my $num_annotations = scalar @$annotation_entries;
    my $num_dateds = 0;
    my $num_places = 0;
    my $num_taxa = 0;

    for my $annotation (@$annotation_entries) {
        my $key = $annotation->getAttribute('key');
        my $value = $annotation->getAttribute('value');

        if($key eq 'dated') {
            $value = POSIX::mktime(0, 0, 0, $3, ($2 - 1), ($1-1900))
                if($value =~ /^(\d+)-(\d+)-(\d+)$/);
            $dateds->add_data($value);
            $num_dateds++;
        }

        if($key eq 'place') {
            # $places->add_data($value);
            $num_places++;
        }

        if($key eq 'taxon') {
            # $taxa->add_data($key);
            $num_taxa++;
        }
    }

    $editor_entries = $xp->find('editors/attribute', $node);

    my $num_editors = scalar @$editor_entries;
    for my $editor (@$editor_entries) {
        
    }

    my $content = $node->getChildNode(2);
    die "No content node present" unless defined $content;

    $count_annotations->add_data($num_annotations);
    $count_dateds->add_data($num_dateds);
    $count_taxa->add_data($num_taxa);
    $count_places->add_data($num_places);
    $count_editors->add_data($num_editors);

    say "$page_no, $num_annotations, $num_dateds, $num_places, $num_taxa, $num_editors";
}

say STDERR "Summary for " . $root->getAttribute('title');

sub spread_as_string($) {
    my $data = shift;

    return sprintf("%g/page (sd=%g, range=%g-%g, median=%g, IQR=%g-%g, n=%d)",
        $data->mean,
        $data->standard_deviation,
        $data->min,
        $data->max,
        $data->median,
        scalar($data->percentile(25)),
        scalar($data->percentile(75)),
        $data->count
    );
}

sub localtime_short($) {
    my $time = shift;

    return POSIX::strftime("%A, %B %d, %G", localtime($time));
}

my @dateds = $dateds->get_data();
my %unique_dates;
my $count_unique_dates = 0;
my %duplicate_dates;
foreach my $date (@dateds) {
    if (exists $unique_dates{$date}) {
        $unique_dates{$date}++;
        if (exists $duplicate_dates{$date}) {
            $duplicate_dates{$date}++;
        } else {
            $duplicate_dates{$date} = 2;
        }
    } else {
        $unique_dates{$date} = 1;
        $count_unique_dates++;
    }
}

my $duplicate_dates = "";
if(scalar(keys %duplicate_dates) == 0) {
    $duplicate_dates = "none";
} else {
    my @sorted_dates = 
        sort {$duplicate_dates{$a} <=> $duplicate_dates{$b}} 
        keys %duplicate_dates;
    my @duplicate_dates;
    foreach my $date (@sorted_dates) {
        push(@duplicate_dates, localtime_short($date) . ": " . $duplicate_dates{$date}) . " time(s)";
    }
    $duplicate_dates = join(", ", @duplicate_dates);
}

say STDERR "\tNumber of pages: " . (scalar @nodes);
say STDERR "\tNumber of annotations: " . $count_annotations->sum() . 
    "\n\t  Spread: " . spread_as_string($count_annotations);

say STDERR "\tNumber of places: " . $count_places->sum() . 
    "\n\t  Spread: " . spread_as_string($count_places);

say STDERR "\tNumber of taxa: " . $count_taxa->sum() . 
    "\n\t  Spread: " . spread_as_string($count_taxa);

say STDERR "\tNumber of date annotations: " . $count_dateds->sum() .
    "\n\t  Spread: " . spread_as_string($count_dateds);
say STDERR "\t  Date range:";
say STDERR "\t    Unique dates: $count_unique_dates (duplicated: $duplicate_dates)";
say STDERR "\t    Min: " . localtime_short($dateds->min);
say STDERR "\t    Max: " . localtime_short($dateds->max);
say STDERR "\t    Median: " . localtime_short($dateds->median);

say STDERR "\n";

my $no_of_editors = (scalar keys %editors_contributions);
say STDERR "\tNumber of editors: $no_of_editors" .
    "\n\t  Spread: " . spread_as_string($count_editors);
    "\n\t  Total contributions: " . (values %editors_contributions) .
