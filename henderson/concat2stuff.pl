
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
use POSIX;

binmode(STDOUT, ":utf8");

my @entries;

my $current_entry;
while(<STDIN>) {
    if(/^(.*)\s*{{new-entry}}\s*(.*)$/i) {
        # Append the string before the new entry to the current entry.
        $current_entry .= $1; 

        push @entries, $current_entry;

        # Set up the next current entry with the rest of the last line.
        $current_entry = $2;
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

my $csv = Text::CSV->new({eol => "\n", binary => 1});
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

    # From https://docs.google.com/spreadsheet/ccc?key=0AvsrI9Pi83gYdGpnLUZadG56ejJuQmZMSHFiX1hFTkE#gid=0
    return [
        "catalogNumber", 
        "dc:modified",
        "basisOfRecord",
        "institutionCode",
        "collectionCode",
        "associatedMedia",
        "fieldNotes",
        "scientificName",
        "vernacularName",
        "ScrapedName",
        "AnnotatorName",
        "VerbatimDate",
        "identifiedBy",
        "dateIdentified",
        "associatedReferences",
        "dataGeneralizations",
        "identificationRemarks",
        "occurenceRemarks",
        "country",
        "countryCode",
        "stateProvince",
        "county",
        "locality",
        "verbatimLocality",
        "ScrapeGoatField",
        "decimal latitude",
        "decimal longitude",
        "geodeticDatum",
        "coordinateUncertaintyInMeters",
        "georeferencedBy",
        "georeferencedDate",
        "Kingdom",
        "Phylum",
        "Class",
        "Order",
        "Family",
        "Genus",
        "Species",
        "EventDate",
        "Day",
        "Month",
        "Year"
        ]
        if not defined $tag;

    state $current_place;
    state $current_place_str;
    state $current_date;
    state $current_page_uri;
    state $current_state;
    state %page_count;

    if($tag =~ /^place\|(.*)/i) {
        $current_place = $1;
        $current_place_str = $1;

        if($current_place =~ /(.*)\|(.*)/) {
            $current_place = $1;
            $current_place_str = $2;
        }

        if($current_place =~ /^(\w+), (\w+)$/) {
            $current_state = $2;
        }
    }

    if($tag =~ /^dated\|(\d+)-(\d+)-(\d+).*/i) {
        $current_date = "$1-$2-$3";
    }

    if($tag =~ /^#from.*\|uri=(.*)\|?/i) {
        $current_page_uri = $1;
    }

    if($tag =~ /^taxon\|(.*)$/i) {
        my $taxon_name = $1;
        my $taxon_str = $1;

        if($taxon_name =~ /(.*)\|(.*)/) {
            $taxon_name = $1;
            $taxon_str = $2;
        }

        # What we got: return [$entry_count, $taxon_name, $current_date, $current_place, $current_page_uri, $entry];
        my ($notebook_number) =     ($current_page_uri =~ /Page:Field_Notes_of_Junius_Henderson,_Notebook_(\d+)\..{1,4}\//);
        die "No notebook number discernable in URI '$current_page_uri'" unless defined $notebook_number;

        my ($page_number) =         ($current_page_uri =~ /Page:Field_Notes_of_Junius_Henderson,_Notebook_\d+\..{1,4}\/(\d+)\?/);
        die "No page number discernable in URI '$current_page_uri'" unless defined $page_number;

        if(not exists $page_count{$page_number}) {
            $page_count{$page_number} = "A";
        } else {
            $page_count{$page_number}++;
        }

        return [
            # "catalogNumber", 
            "JHFN$notebook_number-$page_number-" . $page_count{$page_number}, 

            # "dc:modified",
            POSIX::strftime('%Y-%m-%d', localtime),

            # "basisOfRecord",
            "HumanObservation",

            # "institutionCode",
            "UCM",

            # "collectionCode",
            "HendersonNotes",

            # "associatedMedia",
            $current_page_uri,

            # "fieldNotes",
            "http://en.wikisource.org/wiki/Field_Notes_of_Junius_Henderson",
    
            # "scientificName",
            "", #$taxon_name,

            # "vernacularName",
            "", #$taxon_str,

            # ScrapedName
            $taxon_str,

            # AnnotatorName
            $taxon_name,

            # "VerbatimDate",
            $current_date,

            # "identifiedBy",
            "Junius Henderson",

            # "dateIdentified",
            $current_date,

            # "associatedReferences",
            "",

            # "dataGeneralizations",
            "", # $entry,

            # "identificationRemarks",
            "",

            # "occurenceRemarks",
            "", #$entry,

            # "country",
            "United States of America",

            # "countryCode",
            "US",

            # "stateProvince",
            $current_state, 
        
            # "county",
            "",
            
            # "locality",
            "",

            # "verbatimLocality",
            $current_place_str,

            # "ScrapeGoatField",
            "",
            
            # "decimal latitude",
            "",

            # "decimal longitude",
            "",

            # "geodeticDatum",
            "",

            # "coordinateUncertaintyInMeters",
            "",

            # "georeferencedBy",
            "",

            # "georeferencedDate",
            "",

            # "Kingdom",
            "",

            # "Phylum",
            "",

            # "Class",
            "",

            # "Order",
            "",

            # "Family",
            "",

            # "Genus",
            "",

            # "Species",
            "",

            # "EventDate",
            "",

            # "Day",
            "",

            # "Month",
            "",

            # "Year"
            ""
        ];
    }

    return undef;
}

sub trail { 
    my ($tag, $entry, $entry_count) = @_;

    return ["EntryNo", "Date", "Place", "URI", "Entry"]
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
        return [$entry_count, $current_date, $current_place, $current_page_uri, "entry"];
    }

    return undef;
}
