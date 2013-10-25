package Dist::Zilla::Plugin::MakeMaker;

# ABSTRACT: build a Makefile.PL that uses ExtUtils::MakeMaker
use Moose;
use Moose::Autobox;

use namespace::autoclean;

use Config;
use CPAN::Meta::Requirements 2.121; # requirements_for_module
use List::MoreUtils qw(any uniq);

use Dist::Zilla::File::InMemory;
use Dist::Zilla::Plugin::MakeMaker::Runner;

=head1 DESCRIPTION

This plugin will produce an L<ExtUtils::MakeMaker>-powered F<Makefile.PL> for
the distribution.  If loaded, the L<Manifest|Dist::Zilla::Plugin::Manifest>
plugin should also be loaded.

=cut

=attr eumm_version

This option declares the version of ExtUtils::MakeMaker required to configure
and build the distribution.  It defaults to 6.30, which ensures a working
C<INSTALL_BASE>.  It can be safely set to earlier versions, although I<no
testing has been done to determine the minimum version actually required>.

=cut

has eumm_version => (
  isa => 'Str',
  is  => 'rw',
  default => '6.30',
);

=attr make_path

This option sets the path to F<make>, used to build your dist and run tests.
It defaults to the value for C<make> in L<Config>, or to C<make> if that isn't
set.

You probably won't need to set this option.

=cut

has 'make_path' => (
  isa => 'Str',
  is  => 'ro',
  default => $Config{make} || 'make',
);

has '_runner' => (
  is   => 'ro',
  lazy => 1,
  handles => [qw(build test)],
  default => sub {
    my ($self) = @_;
    Dist::Zilla::Plugin::MakeMaker::Runner->new({
      zilla       => $self->zilla,
      plugin_name => $self->plugin_name . '::Runner',
      make_path   => $self->make_path,
    });
  },
);

# This is here, rather than at the top, so that the "build" and "test" methods
# will exist, as they are required by BuildRunner and TestRunner respectively.
# I had originally fixed this with stub methods, but stub methods to not behave
# properly with this use case until Moose 2.0300. -- rjbs, 2012-02-08
with qw(
  Dist::Zilla::Role::BuildRunner
  Dist::Zilla::Role::InstallTool
  Dist::Zilla::Role::PrereqSource
  Dist::Zilla::Role::TestRunner
  Dist::Zilla::Role::TextTemplate
);

my $template = q!
use strict;
use warnings;

{{ $perl_prereq ? qq[use $perl_prereq;] : ''; }}

use ExtUtils::MakeMaker {{ $eumm_version }};

{{ $share_dir_code{preamble} || '' }}

my {{ $WriteMakefileArgs }}

my {{ $fallback_prereqs }}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{{ $share_dir_code{postamble} || '' }}

!;

sub register_prereqs {
  my ($self) = @_;

  $self->zilla->register_prereqs(
    { phase => 'configure' },
    'ExtUtils::MakeMaker' => $self->eumm_version,
  );

  return unless keys %{ $self->zilla->_share_dir_map };

  $self->zilla->register_prereqs(
    { phase => 'configure' },
    'File::ShareDir::Install' => 0.03,
  );
}

sub share_dir_code {
  my ($self) = @_;

  my $share_dir_code = {};

  my $share_dir_map = $self->zilla->_share_dir_map;
  if ( keys %$share_dir_map ) {
    my $preamble = qq{use File::ShareDir::Install;\n};

    if ( my $dist_share_dir = $share_dir_map->{dist} ) {
      $dist_share_dir = quotemeta $dist_share_dir;
      $preamble .= qq{install_share dist => "$dist_share_dir";\n};
    }

    if ( my $mod_map = $share_dir_map->{module} ) {
      for my $mod ( keys %$mod_map ) {
        my $mod_share_dir = quotemeta $mod_map->{$mod};
        $preamble .= qq{install_share module => "$mod", "$mod_share_dir";\n};
      }
    }

    $share_dir_code->{preamble} = $preamble;
    $share_dir_code->{postamble}
      = qq{\{\npackage\nMY;\nuse File::ShareDir::Install qw(postamble);\n\}\n};
  }

  return $share_dir_code;
}

sub write_makefile_args {
  my ($self) = @_;

  (my $name = $self->zilla->name) =~ s/-/::/g;

  my @exe_files =
    $self->zilla->find_files(':ExecFiles')->map(sub { $_->name })->flatten;

  $self->log_fatal("can't install files with whitespace in their names")
    if grep { /\s/ } @exe_files;

  my %test_dirs;
  for my $file ($self->zilla->files->flatten) {
    next unless $file->name =~ m{\At/.+\.t\z};
    (my $dir = $file->name) =~ s{/[^/]+\.t\z}{/*.t}g;

    $test_dirs{ $dir } = 1;
  }

  my $prereqs = $self->zilla->prereqs;
  my $perl_prereq = $prereqs->requirements_for(qw(runtime requires))
    ->clone
    ->add_requirements($prereqs->requirements_for(qw(build requires)))
    ->as_string_hash->{perl};

  $perl_prereq = version->parse($perl_prereq)->numify if $perl_prereq;

  my $prereqs_dump = sub {
    $prereqs->requirements_for(@_)
            ->clone
            ->clear_requirement('perl')
            ->as_string_hash;
  };

  my $build_prereq
    = $prereqs->requirements_for(qw(build requires))
    ->clone
    ->clear_requirement('perl')
    ->as_string_hash;

  my $test_prereq
    = $prereqs->requirements_for(qw(test requires))
    ->clone
    ->clear_requirement('perl')
    ->as_string_hash;

  my %write_makefile_args = (
    DISTNAME  => $self->zilla->name,
    NAME      => $name,
    AUTHOR    => $self->zilla->authors->join(q{, }),
    ABSTRACT  => $self->zilla->abstract,
    VERSION   => $self->zilla->version,
    LICENSE   => $self->zilla->license->meta_yml_name,
    EXE_FILES => [ @exe_files ],

    CONFIGURE_REQUIRES => $prereqs_dump->(qw(configure requires)),
    BUILD_REQUIRES     => $build_prereq,
    TEST_REQUIRES      => $test_prereq,
    PREREQ_PM          => $prereqs_dump->(qw(runtime   requires)),

    test => { TESTS => join q{ }, sort keys %test_dirs },
  );

  $write_makefile_args{MIN_PERL_VERSION} = $perl_prereq if $perl_prereq;

  return \%write_makefile_args;
}

sub _dump_as {
  my ($self, $ref, $name) = @_;
  require Data::Dumper;
  my $dumper = Data::Dumper->new( [ $ref ], [ $name ] );
  $dumper->Sortkeys( 1 );
  $dumper->Indent( 1 );
  $dumper->Useqq( 1 );
  return $dumper->Dump;
}

sub fallback_prereq_pm {
  my $self = shift;
  my $fallback
    = $self->zilla->prereqs->merged_requires
    ->clone
    ->clear_requirement('perl')
    ->as_string_hash;
  return $self->_dump_as( $fallback, '*FallbackPrereqs' );
}

sub setup_installer {
  my ($self, $arg) = @_;

  my $write_makefile_args = $self->write_makefile_args;

  $self->__write_makefile_args($write_makefile_args); # save for testing

  my $perl_prereq = delete $write_makefile_args->{MIN_PERL_VERSION};

  my $dumped_args = $self->_dump_as($write_makefile_args, '*WriteMakefileArgs');

  my $content = $self->fill_in_string(
    $template,
    {
      eumm_version      => \($self->eumm_version),
      perl_prereq       => \$perl_prereq,
      share_dir_code    => $self->share_dir_code,
      fallback_prereqs  => \($self->fallback_prereq_pm),
      WriteMakefileArgs => \$dumped_args,
    },
  );

  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'Makefile.PL',
    content => $content,
  });

  $self->add_file($file);
  return;
}

# XXX:  Just here to facilitate testing. -- rjbs, 2010-03-20
has __write_makefile_args => (
  is   => 'rw',
  isa  => 'HashRef',
);

__PACKAGE__->meta->make_immutable;
1;

=head1 SEE ALSO

Core Dist::Zilla plugins:
L<@Basic|Dist::Zilla::PluginBundle::Basic>,
L<ModuleBuild|Dist::Zilla::Plugin::ModuleBuild>,
L<Manifest|Dist::Zilla::Plugin::Manifest>.

Dist::Zilla roles:
L<BuildRunner|Dist::Zilla::Role::FileGatherer>,
L<InstallTool|Dist::Zilla::Role::InstallTool>,
L<PrereqSource|Dist::Zilla::Role::PrereqSource>,
L<TestRunner|Dist::Zilla::Role::TestRunner>.

=cut
