use strict;
use warnings;
package Dist::Zilla::Plugin::SmokeTests;
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: ...
# KEYWORDS: ...

our $VERSION = '0.001';

use Moose;
with 'Dist::Zilla::Role::...';

use namespace::autoclean;

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        ...,
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };

    return $config;
};


__PACKAGE__->meta->make_immutable;
__END__

=pod

=head1 SYNOPSIS

In your F<dist.ini>:

    [SmokeTests]

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that...

=head1 CONFIGURATION OPTIONS

=head2 C<foo>

...

=head1 ACKNOWLEDGEMENTS

...

=head1 SEE ALSO

=for :list
* L<foo>

=cut
