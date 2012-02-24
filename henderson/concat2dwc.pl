
=head1 NAME

concat2dwc.pl - Convert concatenated WikiSource code into Darwin Core records.

=head1 SYNOPSIS

    perl concat2dwc.pl < concat_input.txt > darwincore.txt

=cut

use strict;
use warnings;

binmode(STDOUT, ":utf8");

my @entries;

while(<>) {
    chomp;

    if(/<br>
}

$str =~ s/<noinclude>.*?<\/noinclude>//gs;
print $str;
