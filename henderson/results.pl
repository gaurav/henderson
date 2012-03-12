
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

my $dateds = Statistics::Descriptive::Full->new();

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

    for my $annotation (@$annotation_entries) {
        my $key = $annotation->getAttribute('key');
        my $value = $annotation->getAttribute('value');

        if($key eq 'dated') {
            $value = POSIX::mktime(0, 0, 0, $3, ($2 - 1), ($1-1900))
                if($value =~ /^(\d+)-(\d+)-(\d+)$/);
            $dateds->add_data($value);
            $num_dateds++;
        }
    }

    my $content = $node->getChildNode(2);
    die "No content node present" unless defined $content;

    $count_annotations->add_data($num_annotations);
    $count_dateds->add_data($num_dateds);

    say "$page_no, $num_annotations, $num_dateds";
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
say STDERR "\tNumber of date annotations: " . $count_dateds->sum() .
    "\n\t  Spread: " . spread_as_string($count_dateds);
say STDERR "\t  Date range:";
say STDERR "\t    Unique dates: $count_unique_dates (duplicated: $duplicate_dates)";
say STDERR "\t    Min: " . localtime_short($dateds->min);
say STDERR "\t    Max: " . localtime_short($dateds->max);
say STDERR "\t    Median: " . localtime_short($dateds->median);
