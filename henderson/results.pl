
=head1 NAME

results.pl - Calculate result statistics for an XML file.

=cut

use v5.010;
use strict;
use warnings;

use XML::XPath;
use XML::XPath::XMLParser;

use Statistics::Descriptive;
use URI::Escape;
use Getopt::Long;

my $skip_pages = 0;
GetOptions(
    'skip=o' => \$skip_pages
);

die "No argument provided: please provide the filename to process" unless exists $ARGV[0];
my $xp = XML::XPath->new($ARGV[0]) or die "Could not open '$ARGV[0]'.";

my $root = @{$xp->find('/transcription')}[0];
my $nodeset = $xp->find('/transcription/page');

binmode(STDOUT, ":utf8");

my $count_annotations = Statistics::Descriptive::Full->new();
my $count_dateds = Statistics::Descriptive::Full->new();
my $count_taxa = Statistics::Descriptive::Full->new();
my $count_places = Statistics::Descriptive::Full->new();
my $count_edits = Statistics::Descriptive::Full->new();
my $count_editors = Statistics::Descriptive::Full->new();

my $dateds = Statistics::Descriptive::Full->new();
my @taxa = ();
my @places = ();

my %editors_pages_edited;
my %editors_edits_made;

my $str = "";
my @nodes = @{$nodeset};

my $pages_processed = 0;

my $first_entry = 0;
my $page_no = 0;
for my $node (@nodes) {
    $page_no++;

    if($page_no <= $skip_pages) {
        say STDERR "Skipping page $page_no.";
        next;
    }

    if(not $first_entry) {
        say STDERR "First page: <<" . $node->string_value . ">>";
        $first_entry = 1;
    }

    my $title = $node->getAttribute('title');
    my $uri = $node->getAttribute('uri');

    my $annotation_entries = $xp->find('annotations/attribute', $node);

    my $num_annotations = 0;
    my $num_dateds = 0;
    my $num_places = 0;
    my $num_taxa = 0;

    for my $annotation (@$annotation_entries) {
        my $key = lc($annotation->getAttribute('key'));
        my $value = $annotation->getAttribute('value');
        my $count = $annotation->getAttribute('count');

        $num_annotations += $count;

        if($key eq 'dated') {
            $value = POSIX::mktime(0, 0, 0, $3, ($2 - 1), ($1-1900))
                if($value =~ /^(\d+)-(\d+)-(\d+)$/);
            $dateds->add_data($value) for(1..$count);
            $num_dateds += $count;
        }

        if($key eq 'place') {
            push @places, $value for(1..$count);
            $num_places += $count;
        }

        if($key eq 'taxon') {
            push @taxa, $value for(1..$count);
            $num_taxa += $count;
        }
    }

    my $editor_entries = $xp->find('editors/attribute', $node);
    my $num_editors = scalar @$editor_entries;

    my $num_edits = 0;
    for my $editor (@$editor_entries) {
        my $editor_username = $editor->getAttribute('key');
        my $editor_contribs = $editor->getAttribute('value');
 
        $num_edits += $editor_contribs;

        if (exists $editors_edits_made{$editor_username}) {
            $editors_edits_made{$editor_username} += $editor_contribs;
            $editors_pages_edited{$editor_username}++;
        } else {
            $editors_edits_made{$editor_username} = $editor_contribs;
            $editors_pages_edited{$editor_username} = 1;
        }
    }

    my $content = $node->getChildNode(2);
    die "No content node present" unless defined $content;

    $count_annotations->add_data($num_annotations);
    $count_dateds->add_data($num_dateds);
    $count_taxa->add_data($num_taxa);
    $count_places->add_data($num_places);
    $count_editors->add_data($num_editors);
    $count_edits->add_data($num_edits);

    say "$page_no, $num_annotations, $num_dateds, $num_places, $num_taxa, $num_editors, $num_edits";
    $pages_processed++;
}

sub spread_as_string($) {
    my $data = shift;

    return sprintf("%g (sd=%g, range=%g-%g, median=%g, IQR=%g-%g, n=%d)",
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

sub get_uniques($$) {
    my ($data, $render_func) = @_;
    my @data = @{$data};

    if(not defined $render_func) {
        $render_func = sub { return join('', @_); };
    }

    my %uniques;
    my $count_uniques = 0;
    my %duplicates;

    foreach my $item (@data) {
        if (exists $uniques{$item}) {
            $uniques{$item}++;
            if (exists $duplicates{$item}) {
                $duplicates{$item}++;
            } else {
                $duplicates{$item} = 2;
            }
        } else {
            $uniques{$item} = 1;
            $count_uniques++;
        }
    }

    my $duplicates = "";
    if(scalar(keys %duplicates) == 0) {
        $duplicates = "none";
    } else {
        my @sorted = 
            sort {$duplicates{$b} <=> $duplicates{$a}} 
            keys %duplicates;

        # print STDERR "Sorted duplicates: " . join(', ', @sorted) . ".";
        my @duplicates;
        foreach my $item (@sorted) {
            # print STDERR "Rendered item $item as " . $render_func->($item) . ".";
            push(@duplicates, $render_func->($item) . ": " . $duplicates{$item} . " times");
        }
        $duplicates = join(", ", @duplicates);
    }

    return ($count_uniques, $duplicates);
}

sub get_uniques_str {
    my ($data, $render_func) = @_;

    my $count = scalar(@$data);
    my($unique_count, $unique_report) = get_uniques($data, $render_func);

    return "$count ($unique_count unique, duplicates: $unique_report)";
}

binmode(STDERR, ':utf8');
say STDERR "\nSummary for " . $root->getAttribute('title');
say STDERR "  URL: http://en.wikisource.org/wiki/" . uri_escape($root->getAttribute('title'));
say STDERR "  Downloaded: " . $root->getAttribute('created');

say STDERR "\tNumber of pages: $pages_processed";

say STDERR "\tNumber of annotations: " . $count_annotations->sum() . 
    "\n\t  Spread: " . spread_as_string($count_annotations);

say STDERR "\n\tNumber of taxa: " . $count_taxa->sum() . 
    "\n\t  Spread: " . spread_as_string($count_taxa) .
    "\n" .
    "\n\t  Data: " .
    "\n\t    Count: " . get_uniques_str(\@taxa);

say STDERR "\n\tNumber of places: " . $count_places->sum() . 
    "\n\t  Spread: " . spread_as_string($count_places) .
    "\n" .
    "\n\t  Data: " .
    "\n\t    Count: " . get_uniques_str(\@places);

say STDERR "\n\tNumber of date annotations: " . $count_dateds->sum() .
    "\n\t  Spread: " . spread_as_string($count_dateds);
say STDERR "\t  Data:";
say STDERR "\t    Count: " . get_uniques_str([$dateds->get_data()], \&localtime_short);
say STDERR "\t    Min: " . localtime_short($dateds->min);
say STDERR "\t    Max: " . localtime_short($dateds->max);
say STDERR "\t    Median: " . localtime_short($dateds->median);

say "\n\tNumber of edits: " . $count_edits->sum() .
    "\n\t  Spread: " . spread_as_string($count_edits);

say STDERR "\n\tNumber of editors: " . (scalar keys %editors_edits_made) .
    "\n\t  Spread: " . spread_as_string($count_editors);

my $count_pages_per_editor = Statistics::Descriptive::Full->new();
$count_pages_per_editor->add_data(values %editors_pages_edited);

say STDERR "\n\tPages per editor: " . 
    "\n\t  Spread: " . spread_as_string($count_pages_per_editor);

my $count_edits_per_editor = Statistics::Descriptive::Full->new();
$count_edits_per_editor->add_data(values %editors_edits_made);

say STDERR "\n\tEdits per editor: " . 
    "\n\t  Spread: " . spread_as_string($count_edits_per_editor);

say STDERR "";
