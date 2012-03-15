
=head1 NAME

list_concat.pl - Generates lists from the concat files.

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

die "No annotation type provided." unless defined $ARGV[0];
my $annotation_type = $ARGV[0];

binmode(STDOUT, ":utf8");

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

my %annotations;

my $entry_count = 0;
foreach my $entry (@entries) {
    $entry_count++;

    # TODO: Split by {{...}} references, then process all of them.   
    # We can't just download them, because relative order is really important here.
    my @tags = ($entry =~ /{{(#?[\w\s]+\|.*?)}}/ig);
    
    foreach my $tag (@tags) {
        if($tag =~ /^$annotation_type\|(.*)$/i) {
            my $value = $1;
            if($value =~ /^\s*(.*?)\s*\|\s*(.*)\s*$/) {
                $value = $1;
            }

            if(exists $annotations{$value}) {
                $annotations{$value}++;
            } else {
                $annotations{$value} = 1;
            }
        }
    }
}

say STDERR "$entry_count entries processed.";

my %hash_to_sort;
sub sorter {
    #if($hash_to_sort{$a} == $hash_to_sort{$b}) {
    return lc($a) cmp lc($b);
    #} else {
    #    return $hash_to_sort{$b} <=> $hash_to_sort{$a};
    #}
}

my $csv = Text::CSV->new();
say "value,frequency";

%hash_to_sort = %annotations;
foreach my $key (sort sorter keys %annotations) {
    $csv->combine($key, $annotations{$key});
    say $csv->string();
}
