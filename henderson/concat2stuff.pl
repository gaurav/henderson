
=head1 NAME

concat2stuff.pl - Convert concatenated WikiSource code into stuff.

=head1 SYNOPSIS

    perl concat2stuff.pl dwc  < concat_input.txt > darwincore.txt

Instead of 'dwc', try 'trail'.

=cut

use strict;
use warnings;

use 5.0100;

use Text::CSV;

binmode(STDOUT, ":utf8");

my @entries;

my $current_entry;
while(<STDIN>) {
    if(/^(.*)\s*{{new-entry}}\s*(.*)$/i) {
        # Append the string before the new entry to the current entry.
        $current_entry .= $1; 

        push @entries, $current_entry;

        # Set up the next current entry with the rest of the last line.
        $current_entry .= $2;
    } else {
        $current_entry .= $_;
    }
}
if($current_entry ne "") {
    push @entries, $current_entry;
}

say STDERR "$#entries entries loaded.";

my $method = lc $ARGV[0];
$method = \&dwc if $method eq 'dwc';
$method = \&trail if $method eq 'trail';
die "Invalid method: $method"
    unless ref($method) eq 'CODE';

my $csv = Text::CSV->new({eol => "\n"});
my $header = $method->();
$csv->print(\*STDOUT, $header);

my $entry_count = 0;
foreach my $entry (@entries) {
    $entry_count++;

    # TODO: Split by {{...}} references, then process all of them.   
    # We can't just download them, because relative order is really important here.
    my @tags = ($entry =~ /{{(#?[\w\s]+\|.*?)}}/ig);
    
    foreach my $tag (@tags) {
        my $result = $method->($tag, $entry, $entry_count);
        if(defined $result) {
            $csv->print(\*STDOUT, $result);
        }
    }
}

# Some processing methods.
sub dwc {
    my ($tag, $entry, $entry_count) = @_;

    say "TAG $tag ($entry_count)";
}

sub trail { 
    my ($tag, $entry, $entry_count) = @_;

    return ["Date", "Place", "URI"]
        if not defined $tag;

    state $current_place;
    state $current_date;
    state $current_page_uri;

    my $new_tag = 0;
    if($tag =~ /^place\|(.*?)\|.*/i) {
        $current_place = $1;
        $new_tag = 1;
    }

    if($tag =~ /^dated\|(\d+)-(\d+)-(\d+).*/i) {
        $current_date = "$1-$2-$3";
        $new_tag = 1;
    }

    if($tag =~ /^#from.*\|uri=(.*)\|?/i) {
        $current_page_uri = $1;
    }

    if($new_tag and defined($current_date) and defined($current_place)) {
        return [$current_date, $current_place, $current_page_uri];
    }

    return undef;
}
