package WWW::Wikisource;

use warnings;
use strict;

use Carp;
use Try::Tiny;

use MediaWiki::API;

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
    $index_page = $ws->lookup('Index:Field Notes of Junius Henderson, Notebook 1.djvu')

=head1 METHODS

=head2 new

=cut

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    # Initialization.
    $self->{'mwa'} = MediaWiki::API->new({
        api_url => 'http://en.wikisource.org/w/api.php'
    });

    return $self;
}

=head2 get

  $page = $ws->get('Wikisource:About')

Open a particular page (by title) on Wikisource.

Returns undef if the page doesn't exist, or
a 'page' (in the sense of MediaWiki::API->get_page),
or a WWW::Wikisource::IndexPage if you've got one
of them.

=cut

sub get {
    my $self = shift;
    my $title = shift;

    croak "lookup() needs one argument: a page title to look up"
        if not defined $title;
    
    my $mw = $self->{'mwa'};

    my $page = $mw->get_page({title => $title});

    # Return 'undef' if no such page found.
    return undef if exists $page->{'missing'};
    
    # An index page!
    if($page->{'ns'} eq '106') {
        # TODO: Make an index page.
    }

    return $page;
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
