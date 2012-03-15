
=head1 NAME

list.pl - Returns a list of all 'annotation-type' results.

=cut

use v5.010;
use strict;
use warnings;

use XML::XPath;
use XML::XPath::XMLParser;

use Statistics::Descriptive;
use URI::Escape;
use Getopt::Long;
use Text::CSV;

my $skip_pages = 0;
GetOptions(
    'skip=o' => \$skip_pages
);

die "No argument provided: please provide the filename to process." unless exists $ARGV[0];
my $xp = XML::XPath->new($ARGV[0]) or die "Could not open '$ARGV[0]'.";

die "No annotation type to use: please provider another argument." unless exists $ARGV[1];
my $annotation_type = $ARGV[1];

my $root = @{$xp->find('/transcription')}[0];
my $nodeset = $xp->find('/transcription/page');

binmode(STDOUT, ":utf8");

my $str = "";
my @nodes = @{$nodeset};

my $pages_processed = 0;

my %annotations;
my %editors_edits_made;
my %editors_pages_edited;

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

    for my $annotation (@$annotation_entries) {
        my $key = lc($annotation->getAttribute('key'));
        my $value = $annotation->getAttribute('value');

        if($key eq $annotation_type) {
            #if($key eq 'dated') {
            #    $value = POSIX::mktime(0, 0, 0, $3, ($2 - 1), ($1-1900))
            #        if($value =~ /^(\d+)-(\d+)-(\d+)$/);
            #}

            if(exists $annotations{$value}) {
                $annotations{$value}++;
            } else {
                $annotations{$value} = 1;
            }
        }
    }

    my $editor_entries = $xp->find('editors/attribute', $node);

    my $num_edits = 0;
    if($annotation_type eq 'editors') {
        for my $editor (@$editor_entries) {
            my $editor_username = $editor->getAttribute('key');
            my $editor_contribs = $editor->getAttribute('value');
     
            if (exists $editors_edits_made{$editor_username}) {
                $editors_edits_made{$editor_username} += $editor_contribs;
                $editors_pages_edited{$editor_username}++;
            } else {
                $editors_edits_made{$editor_username} = $editor_contribs;
                $editors_pages_edited{$editor_username} = 1;
            }
        }
    }

    $pages_processed++;
}

say STDERR "$pages_processed pages processed.";

my %hash_to_sort;
sub sorter {
    #if($hash_to_sort{$a} == $hash_to_sort{$b}) {
    return lc($a) cmp lc($b);
    #} else {
    #    return $hash_to_sort{$b} <=> $hash_to_sort{$a};
    #}
}

my $csv = Text::CSV->new();
if($annotation_type eq 'editors') {
    say "editor_name,count_edits,count_pages";

    %hash_to_sort = %editors_edits_made;
    
    foreach my $key (sort sorter keys %editors_edits_made) {
        $csv->combine($key, $editors_edits_made{$key}, $editors_pages_edited{$key});
        say $csv->string();
    }

} else {
    say "value,frequency";
    
    %hash_to_sort = %annotations;
    foreach my $key (sort sorter keys %annotations) {
        $csv->combine($key, $annotations{$key});
        say $csv->string();
    }
}
