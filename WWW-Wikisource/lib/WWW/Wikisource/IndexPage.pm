package WWW::Wikisource::IndexPage;

use warnings;
use strict;
use feature 'state';

use Carp;
use Try::Tiny;

use MediaWiki::API;

=head1 NAME

WWW::Wikisource::IndexPage - An Index page on Wikisource

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module lets you access Index pages on Wikisource. Index
pages are special pages provided by the Proofread Page extension
(see http://www.mediawiki.org/wiki/Extension:Proofread_Page).
This module makes these pages accessible to Perl scripts.

While it is recommended that this module be created by 
L<WWW::Wikisource/get_index>, it can also be created 
independently if necessary.

    use WWW::Wikisource::IndexPage;

    my $index = WWW::Wikisource::IndexPage->new('Index:Field Notes of Junius Henderson, Notebook 1.djvu')

=head1 METHODS

=head2 new

    my $index = WWW::Wikisource::IndexPage->new('Index:Wind in the Willows (1913).djvu')

Creates a new IndexPage object. Calling new() will initiate HTTP
connection with Wikipedia to load some basic information; individual
transcribed pages will not, however, be loaded.

Certain properties can also be provided as a hashref as the second value.
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
        $self->{'mwa'} = MediaWiki::API->new({
            api_url => 'http://en.wikisource.org/w/api.php'
        });
    }

    # Load the basic information.
    $self->load();

    return $self;
}

=head2 load

  $index->load();

Loads basic information about this index page from Wikisource
and the Wikimedia Commons. You should not need to use this: it
is called automatically by L</new>.

This method will die() if unable to connect to Wikipedia, or
if the title does not appear to be valid.

=cut

sub load {
    my $self = shift;

    my $title = $self->{'title'};
    my $mwa =   $self->{'mwa'};

    # Load the index page.
    my $page = WWW::Wikisource::Page->new($title, {MediaWikiAPI => $mwa});

    # Return 'undef' if no such page found.
    die "Index page '$title' could not be found." if $page->is_missing();

    # Load the corresponding image.
    my $image_name = $title;
    $image_name =~ s/^Index/File/;

    my $image_page = WWW::Wikisource::Page->new($image_name, {MediaWikiAPI => $mwa}); 
    # if(exists $image_page->{'missing'}) {
    #    die "Could not find an image file at '$image_name' (to correspond to index page at '$title').";
    # }

    my $image = $mwa->api({
        action =>   'query',
        titles =>   $image_name,
        prop =>     'imageinfo',
        iiprop =>   'size'
    });
    if (exists $image->{'query'}->{'pages'}) {
        my $results = $image->{'query'}->{'pages'};
        $image = $results->{(keys %$results)[0]}->{'imageinfo'}[0];
    } else {
        $image = undef;
    }

    # Store everything.
    $self->{'page'} =       $page;
    $self->{'pages'} =      [];
    $self->{'image_page'} = $image_page;
    $self->{'imagesize'} =  $image;
    $self->{'page_count'} = $image->{'pagecount'};
}

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

sub page_count {
    my $self = shift;

    return $self->{'page_count'};
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
