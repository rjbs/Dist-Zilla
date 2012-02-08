package Dist::Zilla::Plugin::MakeMaker;

# ABSTRACT: build a Makefile.PL that uses ExtUtils::MakeMaker
use Moose;
use Moose::Autobox;

use namespace::autoclean;

use Config;
use Data::Dumper ();
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

my $template = q|
use strict;
use warnings;

{{ $perl_prereq ? qq[use $perl_prereq;] : ''; }}

use ExtUtils::MakeMaker {{ $eumm_version }};

{{ $share_dir_block[0] }}

my {{ $WriteMakefileArgs }}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{{ $share_dir_block[1] }}

|;

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

sub setup_installer {
  my ($self, $arg) = @_;

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

  my @share_dir_block = (q{}, q{});

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

    @share_dir_block = (
      $preamble,
      qq{package\nMY;\nuse File::ShareDir::Install qw(postamble);\n},
    );
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
    ->add_requirements($prereqs->requirements_for(qw(test requires)))
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
    PREREQ_PM          => $prereqs_dump->(qw(runtime   requires)),

    test => { TESTS => join q{ }, sort keys %test_dirs },
  );

  $self->__write_makefile_args(\%write_makefile_args);

  my $makefile_args_dumper = Data::Dumper->new(
    [ \%write_makefile_args ],
    [ '*WriteMakefileArgs' ],
  );
  $makefile_args_dumper->Sortkeys( 1 );
  $makefile_args_dumper->Indent( 1 );
  $makefile_args_dumper->Useqq( 1 );

  my $content = $self->fill_in_string(
    $template,
    {
      eumm_version      => \($self->eumm_version),
      perl_prereq       => \$perl_prereq,
      share_dir_block   => \@share_dir_block,
      WriteMakefileArgs => \($makefile_args_dumper->Dump),
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
