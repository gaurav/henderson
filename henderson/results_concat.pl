
=head1 NAME

results_concat.pl - Calculate stats on the _concat.txt file.

=head1 SYNOPSIS

=cut

use strict;
use warnings;

use 5.0100;

use Statistics::Descriptive;

use Text::CSV;
use POSIX;
use Getopt::Long;

my $skip_entries = 0;
GetOptions(
    'skip=o' => \$skip_entries
);

binmode(STDOUT, ":utf8");

my $count_annotations = Statistics::Descriptive::Full->new();
my $count_taxa = Statistics::Descriptive::Full->new();
my $count_places = Statistics::Descriptive::Full->new();
my $count_dateds = Statistics::Descriptive::Full->new();

my @entries;
my $entry_no = 0;

my $current_entry = "";
my $first_entry = 0;
while(<STDIN>) {
    if(/^(.*)\s*{{new-entry}}\s*(.*)$/i) {
        # Append the string before the new entry to the current entry.
        $current_entry .= $1; 

        $entry_no++;
        if($entry_no > $skip_entries) {
            say STDERR "First entry: <<$current_entry>>, existing entries = " . (scalar @entries) if(not $first_entry);

            push @entries, $current_entry;
            $first_entry = 1;
        } else {
            $current_entry = "";
            say STDERR "Skipping entry $entry_no.";
        }

        # Set up the next current entry with the rest of the last line.
        $current_entry = $2;
    } else {
        $current_entry .= $_;
    }
}
if($current_entry ne "") {
    push @entries, $current_entry;
}

my $entry_count = 0;
foreach my $entry (@entries) {
    $entry_count++;

    # TODO: Split by {{...}} references, then process all of them.   
    # We can't just download them, because relative order is really important here.
    my @tags = ($entry =~ /{{(#?[\w\s]+\|.*?)}}/ig);
    
    my $num_annotations = 0;
    my $num_taxa = 0;
    my $num_places = 0;
    my $num_dateds = 0;

    foreach my $tag (@tags) {
        $num_annotations++;

        if($tag =~ /^taxon/i) {
            $num_taxa++;
        } elsif($tag =~ /^dated/i) {
            # say "dated: <<$tag>>";
            $num_dateds++;
        } elsif($tag =~ /^place/i) {
            $num_places++;
            # say "place $num_places: <<$tag>>";
        } else {
            # Don't count this tag.
            $num_annotations--;
        }
    }

    $count_annotations->add_data($num_annotations);
    $count_taxa->add_data($num_taxa);
    $count_places->add_data($num_places);
    $count_dateds->add_data($num_dateds);
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

say STDERR "\tEntries: " . (scalar @entries) . "\n";

say STDERR "\tAnnotations: " . $count_annotations->sum() .
    "\n\t  Annotations/page: " . spread_as_string($count_annotations);

say STDERR 
    "\n\t  Taxon annotations: " . $count_taxa->sum() .
    "\n\t    Spread: " . spread_as_string($count_taxa);

say STDERR 
    "\n\t  Place annotations: " . $count_places->sum() .
    "\n\t    Spread: " . spread_as_string($count_places);

say STDERR 
    "\n\t  Date annotations: " . $count_dateds->sum() .
    "\n\t    Spread: " . spread_as_string($count_dateds);

say STDERR "";
