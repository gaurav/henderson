
=head1 NAME

concat2dwc.pl - Convert concatenated WikiSource code into Darwin Core records.

=head1 SYNOPSIS

    perl concat2dwc.pl < concat_input.txt > darwincore.txt

=cut

use strict;
use warnings;

use 5.0100;

binmode(STDOUT, ":utf8");

my @entries;

my $current_entry;
while(<>) {
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

foreach my $entry (@entries) {
    # TODO: Split by {{...}} references, then process all of them.   
    # We can't just download them, because relative order is really important here.
}
