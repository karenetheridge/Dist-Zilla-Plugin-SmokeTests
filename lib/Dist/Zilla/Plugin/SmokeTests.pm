use strict;
use warnings;
package Dist::Zilla::Plugin::SmokeTests;
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: Tell smoke testers to run your smoke tests
# KEYWORDS: makemaker smoke smoker tests testing automated

our $VERSION = '0.001';

use constant DEFAULT_FINDER => 'xt/smoke/*.t';

use Moose;
with 'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [ DEFAULT_FINDER ],
    };

use List::Util 1.33 qw(any first);
use Dist::Zilla::Plugin::FinderCode;
use namespace::autoclean;

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        finder => [ sort @{ $self->finder } ],
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };

    return $config;
};

sub munge_files
{
    my $self = shift;

    my @finders = @{ $self->finder };
    my $smoke_test_files =
          @finders == 1 && $finders[0] eq DEFAULT_FINDER ? DEFAULT_FINDER
          # TODO, some sort of escaping of special characters?
        : join(' ', sort map { $_->name } @{ $self->found_files });

    if (my $file = first { $_->name eq 'Makefile.PL' } @{$self->zilla->files})
    {
        my $content = $file->content;

        $self->log_fatal('failed to find position in Makefile.PL to munge!')
            if $content !~ m/^my \{\{ \$fallback_prereqs \}\}$/mg;

        $self->log_debug('Adding smoke tests to list of test files in Makefile.PL...');

        my $pos = pos($content);

        $content = substr($content, 0, $pos)
            . "\n"
            . '# inserted by ' . blessed($self) . ' ' . $self->VERSION . "\n"
            . '$WriteMakefileArgs{test}{TESTS} .= " ' . $smoke_test_files . '" if $ENV{AUTOMATED_TESTING};'
            . substr($content, $pos);

        $file->content($content);
    }

    if (my $file = first { $_->name eq 'Build.PL' } @{$self->zilla->files})
    {
        # figure out if Module::Build or Module::Build::Tiny...
        $self->log_fatal('Build.PL munging not yet supported!');
    }
}

__PACKAGE__->meta->make_immutable;
__END__

=pod

=for Pod::Coverage::TrustPod DEFAULT_FINDER munge_files

=head1 SYNOPSIS

In your F<dist.ini>:

    [SmokeTests]

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that modifies F<Makefile.PL> in such a way
that, when run, the C<test> argument passed to L<ExtUtils::MakeMaker> will
include your smoke tests if (and only if) C<$ENV{AUTOMATED_TESTING}> is set.
This variable is set when your distribution is being run by an automated
testing (smoker) system.

=head1 CONFIGURATION OPTIONS

=head2 C<finder>

=for stopwords FileFinder

This is the name of a L<FileFinder|Dist::Zilla::Role::FileFinder> for finding
your smoke test files to include in F<Makefile.PL>.  By default, a special value
is used which references files matching F<xt/smoke/*.t>.

Predefined finders are listed in
L<Dist::Zilla::Role::FileFinderUser/default_finders>.
You can define your own with the
L<[FileFinder::ByName]|Dist::Zilla::Plugin::FileFinder::ByName> and
L<[FileFinder::Filter]|Dist::Zilla::Plugin::FileFinder::Filter> plugins.


=head1 SEE ALSO

=for :list
* L<The Lancaster Consensus discussion of AUTOMATED_TESTING|https://github.com/Perl-Toolchain-Gang/toolchain-site/blob/master/lancaster-consensus.md#environment-variables-for-testing-contexts>
* L<Dist::Zilla::Plugin::MakeMaker>
* L<Dist::Zilla::Plugin::MakeMaker::Awesome>
* L<Dist::Zilla::Plugin::RunExtraTests>

=cut
