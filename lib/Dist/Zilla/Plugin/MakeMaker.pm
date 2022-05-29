package Dist::Zilla::Plugin::MakeMaker;
# ABSTRACT: build a Makefile.PL that uses ExtUtils::MakeMaker

use Moose;

use Dist::Zilla::Pragmas;

use namespace::autoclean;

use Config;
use CPAN::Meta::Requirements 2.121; # requirements_for_module
use List::Util 1.29 qw(first pairs pairgrep);
use version;
use Dist::Zilla::File::InMemory;
use Dist::Zilla::Plugin::MakeMaker::Runner;

=head1 DESCRIPTION

This plugin will produce an L<ExtUtils::MakeMaker>-powered F<Makefile.PL> for
the distribution.  If loaded, the L<Manifest|Dist::Zilla::Plugin::Manifest>
plugin should also be loaded.

=cut

=attr eumm_version

This option declares the version of ExtUtils::MakeMaker required to configure
and build the distribution.  There is no default, although one may be added if
it can be determined that the generated F<Makefile.PL> requires some specific
minimum.  I<No testing has been done on this front.>

=cut

has eumm_version => (
  isa => 'Str',
  is  => 'rw',
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

=attr static_attribution

This option omits the version number in the "generated by"
comment in the Makefile.PL.  For setups that copy the Makefile.PL
back to the repo, this avoids churn just from upgrading Dist::Zilla.

=cut

has 'static_attribution' => (
  isa => 'Bool',
  is  => 'ro',
);

has '_runner' => (
  is   => 'ro',
  lazy => 1,
  handles => [qw(build test)],
  default => sub {
    my ($self) = @_;
    Dist::Zilla::Plugin::MakeMaker::Runner->new({
      zilla        => $self->zilla,
      plugin_name  => $self->plugin_name . '::Runner',
      make_path    => $self->make_path,
      default_jobs => $self->default_jobs,
    });
  },
);

# This is here, rather than at the top, so that the "build" and "test" methods
# will exist, as they are required by BuildRunner and TestRunner respectively.
# I had originally fixed this with stub methods, but stub methods do not behave
# properly with this use case until Moose 2.0300. -- rjbs, 2012-02-08
with qw(
  Dist::Zilla::Role::BuildRunner
  Dist::Zilla::Role::InstallTool
  Dist::Zilla::Role::PrereqSource
  Dist::Zilla::Role::FileGatherer
  Dist::Zilla::Role::TestRunner
  Dist::Zilla::Role::TextTemplate
);

my $template = q!# This file was automatically generated by {{ $generated_by }}.
use strict;
use warnings;

{{ $perl_prereq ? qq[use $perl_prereq;] : ''; }}

use ExtUtils::MakeMaker{{ defined $eumm_version && 0+$eumm_version ? ' ' . $eumm_version : '' }};
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
{{ $share_dir_code{postamble} || '' }}!;

sub register_prereqs ($self) {
  $self->zilla->register_prereqs(
    { phase => 'configure' },
    'ExtUtils::MakeMaker' => $self->eumm_version || 0,
  );

  return unless keys %{ $self->zilla->_share_dir_map };

  $self->zilla->register_prereqs(
    { phase => 'configure' },
    'File::ShareDir::Install' => 0.06,
  );
}

sub gather_files ($self, $arg = {}) {
  require Dist::Zilla::File::InMemory;

  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'Makefile.PL',
    content => $template,   # template evaluated later
  });

  $self->add_file($file);
  return;
}

sub share_dir_code ($self) {
  my $share_dir_code = {};

  my $share_dir_map = $self->zilla->_share_dir_map;
  if ( keys %$share_dir_map ) {
    my $preamble = <<'PREAMBLE';
use File::ShareDir::Install;
$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
$File::ShareDir::Install::INCLUDE_DOTDIRS = 1;
PREAMBLE

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

    $share_dir_code->{preamble} = "\n" . $preamble . "\n";
    $share_dir_code->{postamble}
      = qq{\n\{\npackage\nMY;\nuse File::ShareDir::Install qw(postamble);\n\}\n};
  }

  return $share_dir_code;
}

sub write_makefile_args ($self) {
  my $name = $self->zilla->name =~ s/-/::/gr;

  my @exe_files = map { $_->name }
    @{ $self->zilla->find_files(':ExecFiles') };

  $self->log_fatal("can't install files with whitespace in their names")
    if grep { /\s/ } @exe_files;

  my %test_dirs;
  for my $file (@{ $self->zilla->files }) {
    next unless $file->name =~ m{\At/.+\.t\z};
    my $dir = $file->name =~ s{/[^/]+\.t\z}{/*.t}gr;

    $test_dirs{ $dir } = 1;
  }

  my $prereqs = $self->zilla->prereqs;
  my $perl_prereq = $prereqs->requirements_for(qw(runtime requires))
    ->clone
    ->add_requirements($prereqs->requirements_for(qw(configure requires)))
    ->add_requirements($prereqs->requirements_for(qw(build requires)))
    ->add_requirements($prereqs->requirements_for(qw(test requires)))
    ->as_string_hash->{perl};

  $perl_prereq = version->parse($perl_prereq)->numify if $perl_prereq;

  my $prereqs_dump = sub {
    $self->_normalize_eumm_versions(
      $prereqs->requirements_for(@_)
              ->clone
              ->clear_requirement('perl')
              ->as_string_hash
    );
  };

  my %require_prereqs = map {
    $_ => $prereqs_dump->($_, 'requires');
  } qw(configure build test runtime);

  # EUMM may soon be able to support this, but until we decide to inject a
  # higher configure-requires version, we should at least warn the user
  # https://github.com/Perl-Toolchain-Gang/ExtUtils-MakeMaker/issues/215
  foreach my $phase (qw(configure build test runtime)) {
    if (my @version_ranges = pairgrep { defined($b) && !version::is_lax($b) } %{ $require_prereqs{$phase} }
        and ($self->eumm_version || 0) < '7.1101') {
      $self->log_fatal([
        'found version range in %s prerequisites, which ExtUtils::MakeMaker cannot parse (must specify eumm_version of at least 7.1101): %s %s',
        $phase, $_->[0], $_->[1]
      ]) foreach pairs @version_ranges;
    }
  }

  my %write_makefile_args = (
    DISTNAME  => $self->zilla->name,
    NAME      => $name,
    AUTHOR    => join(q{, }, @{ $self->zilla->authors }),
    ABSTRACT  => $self->zilla->abstract,
    VERSION   => $self->zilla->version,
    LICENSE   => $self->zilla->license->meta_yml_name,
    @exe_files ? ( EXE_FILES => [ sort @exe_files ] ) : (),

    CONFIGURE_REQUIRES => $require_prereqs{configure},
    keys %{ $require_prereqs{build} } ? ( BUILD_REQUIRES => $require_prereqs{build} ) : (),
    keys %{ $require_prereqs{test} } ? ( TEST_REQUIRES => $require_prereqs{test} ) : (),
    PREREQ_PM          => $require_prereqs{runtime},

    test => { TESTS => join q{ }, sort keys %test_dirs },
  );

  $write_makefile_args{MIN_PERL_VERSION} = $perl_prereq if $perl_prereq;

  return \%write_makefile_args;
}

sub _normalize_eumm_versions ($self, $prereqs) {
  for my $v (values %$prereqs) {
    if (version::is_strict($v)) {
      my $version = version->parse($v);
      if ($version->is_qv) {
        if ((() = $v =~ /\./g) > 1) {
          $v =~ s/^v//;
        }
        else {
          $v = $version->numify;
        }
      }
    }
  }
  return $prereqs;
}

sub _dump_as ($self, $ref, $name) {
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
    = $self->_normalize_eumm_versions(
      $self->zilla->prereqs->merged_requires
      ->clone
      ->clear_requirement('perl')
      ->as_string_hash
    );
  return $self->_dump_as( $fallback, '*FallbackPrereqs' );
}

sub setup_installer ($self) {
  my $write_makefile_args = $self->write_makefile_args;

  $self->__write_makefile_args($write_makefile_args); # save for testing

  my $perl_prereq = $write_makefile_args->{MIN_PERL_VERSION};

  my $dumped_args = $self->_dump_as($write_makefile_args, '*WriteMakefileArgs');

  my $file = first { $_->name eq 'Makefile.PL' } @{$self->zilla->files};

  $self->log_debug([ 'updating contents of Makefile.PL in memory' ]);

  my $attribution = $self->static_attribution
    ? ref($self)
    : sprintf("%s v%s", ref($self), $self->VERSION || '(dev)');

  my $content = $self->fill_in_string(
    $file->content,
    {
      eumm_version      => \($self->eumm_version),
      perl_prereq       => \$perl_prereq,
      share_dir_code    => $self->share_dir_code,
      fallback_prereqs  => \($self->fallback_prereq_pm),
      WriteMakefileArgs => \$dumped_args,
      generated_by      => \$attribution,
    },
  );

  $file->content($content);

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
