
use strict;
use warnings;

use XML::XPath;
use XML::XPath::XMLParser;

my $xp = XML::XPath->new('notebook1.xml');
my $nodeset = $xp->find('/transcription/page/content');

binmode(STDOUT, ":utf8");

my $str = "";
for my $x (@{$nodeset}) {
    $str .= $x->string_value;
}

$str =~ s/<noinclude>.*?<\/noinclude>//gs;
print $str;
