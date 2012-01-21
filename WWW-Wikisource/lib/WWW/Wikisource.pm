package WWW::Wikisource;

use warnings;
use strict;

use Carp;
use Try::Tiny;

use MediaWiki::API;

use WWW::Wikisource::IndexPage;

=head1 NAME

WWW::Wikisource - An API for Wikisource

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module lets you access Wikisource; in particular, it
hopes to make Index pages (provided through the Proofread Page
extension) accessible to Perl scripts.

    use WWW::Wikisource;

    my $ws = WWW::Wikisource->new();
    $page = $ws->get('Page:Field Notes of Junius Henderson, Notebook 1.djvu/1')
    $index_page = $ws->get_index('Index:Field Notes of Junius Henderson, Notebook 1.djvu')

=head1 METHODS

=head2 new

=cut

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    # Initialization.
    $self->{'mwa'} = MediaWiki::API->new({
        api_url => 'http://en.wikisource.org/w/api.php',
        use_http_get => 1,
        retries => 4,
        max_lag => 5
    });

    return $self;
}

=head2 get

  $page = $ws->get('Wikisource:About')

Open a particular page (by title) on Wikisource.

Returns undef if the page doesn't exist, or
a 'page' (in the sense of MediaWiki::API->get_page).


=cut

sub get {
    my $self = shift;
    my $title = shift;

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
