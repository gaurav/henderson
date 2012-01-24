package WWW::Wikisource::IndexPage;

use warnings;
use strict;
use feature 'state'; 
    # To be able to use static-to-method variables.

use Carp;
use Try::Tiny;

use MediaWiki::API;
use XML::Writer;

=head1 NAME

WWW::Wikisource::IndexPage - An Index page on Wikisource

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module lets you access Index pages on Wikisource. Index
pages are special pages provided by the Proofread Page extension
(see http://www.mediawiki.org/wiki/Extension:Proofread_Page)
which provide an index to page scans.

While it is recommended that this module be created by 
L<WWW::Wikisource/get_index>, it can also be created 
independently if necessary.

    use WWW::Wikisource::IndexPage;

    my $index = WWW::Wikisource::IndexPage->new('Index:Field Notes of Junius Henderson, Notebook 1.djvu')

=head1 METHODS

=head2 new

    my $index = WWW::Wikisource::IndexPage->new('Index:Wind in the Willows (1913).djvu')

Creates a new IndexPage object. Calling new() will initiate an HTTP
connection with Wikipedia to load some basic information; individual
transcribed pages will not be loaded at this point.

Certain properties can also be provided in a hashref as the second value.
Valid values include:

=over 4

=item MediaWikiAPI

The MediaWiki::API object to use to talk to Wikipedia.

=back

=cut

sub new {
    my $class = shift;
    my $title = shift;
    my $props = shift;
    
    croak "No title provided!"  unless defined $title;
    $props = {}                 unless defined $props;

    # Bless.
    my $self = {};
    bless $self, $class;

    # Initialization.
    $self->{'title'} = $title;
    if (exists $props->{'MediaWikiAPI'}) {
        $self->{'mwa'} = $props->{'MediaWikiAPI'};
    } else {
        # If MediaWikiAPI is not set, create a
        # MediaWiki::API object of our own.
        $self->{'mwa'} = MediaWiki::API->new({
            api_url => 'http://en.wikisource.org/w/api.php'
        });
    }

    # Load basic information.
    $self->load();

    return $self;
}

=head2 load

  $index->load();

Loads basic information about this index page from Wikisource
and the Wikimedia Commons. You should not use this yourself: it
is called automatically by L</new> during instantiation.

This method will die() if it is unable to connect to Wikipedia, or
if the title does not appear to be valid.

=cut

sub load {
    my $self = shift;

    my $title = $self->{'title'};
    my $mwa =   $self->{'mwa'};

    # Load the index page.
    my $page = WWW::Wikisource::Page->new($title, {MediaWikiAPI => $mwa});

    # die() if no such page could be found.
    die "Index page '$title' could not be found." if $page->is_missing();

    # Load the corresponding image.
    my $image_name = $title;
    $image_name =~ s/^Index/File/;

    my $image_page = WWW::Wikisource::Page->new($image_name, {MediaWikiAPI => $mwa}); 
    # Note that if the image is hosted on the Commons, Mediawiki
    # will return all the appropriate data, *but* will also set
    # $image_page->{'missing'}. So we just assume the query was
    # successful but throw an error later if we don't have a
    # valid number of pages.

    my $image = $mwa->api({
        action =>   'query',
        titles =>   $image_name,
        prop =>     'imageinfo',
        iiprop =>   'size'
    });
    die "Unable to retrieve image information: check that title '$image_name' corresponds to an actual image on Wikisource."
        unless exists $image->{'query'}->{'pages'};

    my $results = $image->{'query'}->{'pages'};
    $image = $results->{(keys %$results)[0]}->{'imageinfo'}[0];

    # Store everything.
    $self->{'page'} =       $page;
    $self->{'pages'} =      [];
    $self->{'image_page'} = $image_page;
    $self->{'imagesize'} =  $image;
    $self->{'page_count'} = $image->{'pagecount'};
}

=head2 page_count

    my $page_count = $index->page_count;

Returns the number of pages associated with this index page.

=cut

sub page_count {
    my $self = shift;

    return $self->{'page_count'};
}

=head2 get_page

    my $page = $index->get_page(3);

Returns a page by its page number (a number between
C<1> and L</page_count> page count).

The 'get_' is supposed to serve as a
reminder that this will retrieve the
page from Wikisource. This may take
a while!

=cut

sub get_page {
    state $last_upload_time = time;
    my $self =      shift;
    my $page_no =   shift;

    croak "No page number provided to get_page()!"
        unless defined $page_no;
    croak "Non-numerical page number provided: '$page_no'"
        unless $page_no =~ /^\d+$/;
    croak "Zero is not a valid page number: $page_no"
        if $page_no == 0;

    my $mwa = $self->{'mwa'};
    my $page_title = $self->{'title'};

    $page_title =~ s/^Index/Page/;

    if (not exists $self->{'pages'}->[$page_no]) {
        if ( (time - $last_upload_time) > 10) {
            sleep(5);
            $last_upload_time = time;
        }
        $self->{'pages'}->[$page_no] = WWW::Wikisource::Page->new("$page_title/$page_no", {MediaWikiAPI => $mwa});

        # print STDERR "Last upload time: $last_upload_time (" . (time - $last_upload_time) . ")\n";
        # print STDERR "# GOT (last_upload_time=$last_upload_time): " . Dumper($self->{'pages'}->[$page_no]);
        # print STDERR "Storing result in #$page_no: " . $self->{'pages'}->[$page_no];
    }
    return $self->{'pages'}->[$page_no]; 
}

sub get_all_pages {
    my $self = shift;

    my $page_count = $self->{'page_count'};
    for my $x (1..$page_count) {
        # say STDERR "# Downloading page $x";
        $self->get_page($x) 
            unless exists $self->{'pages'}->[$x];
    }

    # TODO check context before return.
    my @pages = @{$self->{'pages'}};
    shift @pages;   # Because otherwise the array goes from '1' to '$#array', which
                    # can be odd for Perl users.

    return @pages;
}

sub get_all_editors_with_revisions {
    my $self = shift;
    my %editors;

    my $page_count = $self->{'page_count'};
    for my $x (1..$page_count) {
        # say STDERR "# Downloading page $x";
        my $page = $self->get_page($x) 
            unless exists $self->{'pages'}->[$x];

        my %editors_with_revs = $page->all_editors_with_revisions();
        for my $editor (keys %editors_with_revs) {
            $editors{$editor} = 0 unless exists $editors{$editor};
            $editors{$editor} += $editors_with_revs{$editor};
        }
    }

    return \%editors;
}

sub dump {
    my $self = shift;

    use Data::Dumper;

    return Dumper({
        'title' =>      $self->{'title'},
        'page' =>       $self->{'page'}->dump(),
        'page_count' => $self->{'page_count'},
        'imagesize' =>  $self->{'imagesize'}
    });
}

sub title {
    my $self = shift;

    return $self->{'title'};
}

sub as_xml {
    my $self = shift;

    my $xml_string = "";
    my $xml = XML::Writer->new(
        OUTPUT => \$xml_string,
        DATA_MODE => 1,
        DATA_INDENT => 4
    );

    $xml->startTag("transcription",
        'title' =>      $self->title,
        'created' =>    scalar gmtime(time),
    );

    my @pages = $self->get_all_pages();
    foreach my $page (@pages) {
        $xml->startTag("page",
            'title' =>  $page->title
        );

        $xml->startTag("content");
        $xml->cdata($page->content);
        $xml->endTag("content");

        sub add_attributes {
            my ($xml, $hashref) = @_;

            foreach my $key (keys %{$hashref}) {
                next unless defined $key;

                my $value = $hashref->{$key};
                next unless defined $value;

                if(ref($value) eq 'HASH') {
                    $xml->startTag($key);
                    add_attributes($xml, $value);
                    $xml->endTag($key);
                } elsif(ref($value) eq 'ARRAY') {
                    foreach my $val (@{$value}) {
                        $xml->emptyTag("attribute", 'key' => $key, 'value' => $val);
                    }
                } else {
                    $xml->emptyTag("attribute", 'key' => $key, 'value' => $value);
                }
            }
        }

        my %attr = $page->get_attributes();
        add_attributes($xml, \%attr);

        $xml->endTag("page");
    }

    $xml->endTag("transcription");

    $xml->end();

    return $xml_string;
}

# If stringified, return the title of this page.
use overload fallback => 1,
    '""' => sub { 
        my $self = shift; 
        return $self->title() . "(" . $self->page_count() . " pages)"; 
    }
;

=head1 AUTHOR

Gaurav Vaidya, C<< <gaurav at ggvaidya.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-wikisource at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Wikisource>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Wikisource


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Wikisource>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Wikisource>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Wikisource>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Wikisource/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Gaurav Vaidya.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WWW::Wikisource
