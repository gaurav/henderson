
use strict;
use warnings;

use XML::XPath;
use XML::XPath::XMLParser;

die "No argument provided: please provide the filename to process" unless exists $ARGV[0];
my $xp = XML::XPath->new($ARGV[0]) or die "Could not open '$ARGV[0]'.";
my $nodeset = $xp->find('/transcription/page');

binmode(STDOUT, ":utf8");

my $str = "";
for my $node (@{$nodeset}) {
    my $title = $node->getAttribute('title');
    my $uri = $node->getAttribute('uri');

    my $content = $node->getChildNode(2);
    die "No content node present" unless defined $content;

    $str .= "\n\n{{#from|title=$title|uri=$uri}}\n\n";
    $str .= $content->string_value();
}

$str =~ s/<noinclude>.*?<\/noinclude>//gs;
print $str;
