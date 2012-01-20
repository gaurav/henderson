package WWW::Wikisource::IndexPage;

use warnings;
use strict;

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
    
    croak "No title provided!"  unless exists $title;
    $props = {}                 unless defined $props;

    # Bless.
    my $self = {};
    bless $self, $class;

    # Initialization.
    if (exists $props->{'MediaWikiAPI'}) {
        $self->{'mwa'} = $props->{'MediaWikiAPI'};
    } else {
        $self->{'mwa'} = MediaWiki::API->new({
            api_url => 'http://en.wikisource.org/w/api.php'
        });
    }

    # Load the basic information.
    $self->load()

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

sub new {
    my $self = shift;

    my $title = $self->{'title'};
    my $mwa =   $self->{'mwa'};

    croak "get() needs one argument: a page title to look up"
        if not defined $title;
    
    my $mw = $self->{'mwa'};

    my $page = $mw->get_page({title => $title});

    # Return 'undef' if no such page found.
    return undef if exists $page->{'missing'};
    
    return $page;
}

=head2 get_index

  $index = $ws->get_index('Index:Wind in the Willows (1913).djvu');

Returns undef if this Index page doesn't exist, or a WWW::Wikisource::IndexPage
object if it does.


=cut

sub get_index {
    my $self = shift;
    my $title = shift;

    croak "get_index() needs one argument: a page title to look up"
        if not defined $title;
    
    my $mw = $self->{'mwa'};

    return WWW::Wikisource::IndexPage->new($title, {MediaWikiAPI => $mw}) 
}

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
