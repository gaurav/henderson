package WWW::Wikisource::Page;

use warnings;
use strict;
use feature 'state';

use Carp;
use Try::Tiny;

use MediaWiki::API;

=head1 NAME

WWW::Wikisource::Page - A page on Wikisource

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module lets you access pages on Wikisource. It's
really just a simple wrapper over MediaWiki::API's
hash result (see L<MediaWiki::API/get_page>).

While it is recommended that this module be created by 
L<WWW::Wikisource/get>, it can also be created 
independently if necessary.

    use WWW::Wikisource::Page;

    my $page = WWW::Wikisource::Page->new('Index:Field Notes of Junius Henderson, Notebook 1.djvu')

=head1 METHODS

=head2 new

    my $page = WWW::Wikisource::Page->new('Index:Wind in the Willows (1913).djvu')

Creates a new Page object. Calling new() will initiate an HTTP
connection with Wikipedia to load all page information.

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
    if (exists $props->{'MediaWikiAPI'}) {
        $self->{'mwa'} = $props->{'MediaWikiAPI'};
    } else {
        $self->{'mwa'} = MediaWiki::API->new({
            api_url => 'http://en.wikisource.org/w/api.php'
        });
    }

    # Load the basic information.
    $self->{'page'} = $self->{'mwa'}->get_page({title => $title});

    return $self;
}

sub as_hash {
    my $self = shift;

    return $self->{'page'};
}

sub content {
    my $self = shift;

    return $self->{'page'}->{'*'};
}

sub is_missing {
    my $self = shift;

    return exists $self->{'page'}->{'missing'};
}

sub size {
    my $self = shift;

    return $self->{'page'}->{'size'};
}

sub revid {
    my $self = shift;

    return $self->{'page'}->{'revid'};
}

sub title {
    my $self = shift;

    return $self->{'page'}->{'title'};
}

sub ns {
    my $self = shift;

    return $self->{'page'}->{'ns'};
}

sub dump {
    my $self = shift;

    return $self->{'page'};
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