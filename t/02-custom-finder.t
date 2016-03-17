use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

use Test::Requires { 'Dist::Zilla::Plugin::MakeMaker' => '5.022' };

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ MakeMaker => ],
                [ SmokeTests => { finder => 'MySmokeTests' } ],
                [ 'FileFinder::ByName' => 'MySmokeTests' => {
                    dir => 'xt/smoke',
                    match => '\.t$',
                  }
                ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            path(qw(source t foo.t)) => "foo\n",
            path(qw(source xt author foo.t)) => "foo\n",
            path(qw(source xt smoke bar.t)) => "bar\n",
            path(qw(source xt smoke baz.t)) => "baz\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

my $build_dir = path($tzil->tempdir)->child('build');

my $file = $build_dir->child('Makefile.PL');
ok(-e $file, 'Makefile.PL created');

my $makefile = $file->slurp_utf8;
unlike($makefile, qr/[^\S\n]\n/, 'no trailing whitespace in modified file');

my $version = Dist::Zilla::Plugin::SmokeTests->VERSION;
isnt(
    index(
        $makefile,
        <<CONTENT),
# inserted by Dist::Zilla::Plugin::SmokeTests $version
\$WriteMakefileArgs{test}{TESTS} .= " xt/smoke/bar.t xt/smoke/baz.t" if \$ENV{AUTOMATED_TESTING};

CONTENT
    -1,
    'code inserted into Makefile.PL generated by [MakeMaker]',
) or diag "found Makefile.PL content:\n", $makefile;

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::SmokeTests',
                    config => {
                        'Dist::Zilla::Plugin::SmokeTests' => {
                            finder => [ 'MySmokeTests' ],
                        },
                    },
                    name => 'SmokeTests',
                    version => Dist::Zilla::Plugin::SmokeTests->VERSION,
                },
            ),
        }),
    }),
    'plugin metadata, including dumped configs',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
