package Dist::Zilla::Plugin::MakeMaker;

# ABSTRACT: build a Makefile.PL that uses ExtUtils::MakeMaker
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::BuildRunner';
with 'Dist::Zilla::Role::FixedPrereqs';
with 'Dist::Zilla::Role::InstallTool';
with 'Dist::Zilla::Role::TestRunner';
with 'Dist::Zilla::Role::TextTemplate';

=head1 DESCRIPTION

This plugin will produce an L<ExtUtils::MakeMaker>-powered F<Makefile.PL> for
the distribution.  If loaded, the L<Manifest|Dist::Zilla::Plugin::Manifest>
plugin should also be loaded.

=cut

use Data::Dumper ();
use List::MoreUtils qw(any uniq);

use namespace::autoclean;

use Dist::Zilla::File::InMemory;

my $template = q|
use strict;
use warnings;

{{ $perl_prereq ? qq{ BEGIN { require $perl_prereq; } } : ''; }}

use ExtUtils::MakeMaker 6.11;

{{ $share_dir_block[0] }}

my {{ $WriteMakefileArgs }}

delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);

{{ $share_dir_block[1] }}

|;

sub prereq {
  my ($self) = @_;

  $self->zilla->register_prereqs(
    { phase => 'configure' },
    'ExtUtils::MakeMaker' => $self->eumm_version,
  );

  my @dir_plugins = $self->zilla->plugins
    ->grep( sub { $_->isa('Dist::Zilla::Plugin::InstallDirs') })
    ->flatten;

  return {} unless uniq map {; $_->share->flatten } @dir_plugins;

  $self->zilla->register_prereqs(
    { phase => 'configure' },
    'File::ShareDir::Install' => 0.03,
  );
    
  return {};
}

sub setup_installer {
  my ($self, $arg) = @_;

  (my $name = $self->zilla->name) =~ s/-/::/g;

  # XXX: SHAMELESSLY COPIED AND PASTED INTO ModuleBuild -- rjbs, 2010-01-05
  my @dir_plugins = $self->zilla->plugins
    ->grep( sub { $_->isa('Dist::Zilla::Plugin::InstallDirs') })
    ->flatten;

  my @bin_dirs    = uniq map {; $_->bin->flatten   } @dir_plugins;
  my @share_dirs  = uniq map {; $_->share->flatten } @dir_plugins;

  confess "can't install more than one ShareDir" if @share_dirs > 1;

  my @exe_files = $self->zilla->files
    ->grep(sub { my $f = $_; any { $f->name =~ qr{^\Q$_\E[\\/]} } @bin_dirs; })
    ->map( sub { $_->name })
    ->flatten;

  confess "can't install files with whitespace in their names"
    if grep { /\s/ } @exe_files;

  my %test_dirs;
  for my $file ($self->zilla->files->flatten) {
    next unless $file->name =~ m{\At/.+\.t\z};
    (my $dir = $file->name) =~ s{/[^/]+\.t\z}{/*.t}g;

    $test_dirs{ $dir } = 1;
  }

  my @share_dir_block = (q{}, q{});

  if ($share_dirs[0]) {
    my $share_dir = quotemeta $share_dirs[0];
    @share_dir_block = (
      qq{use File::ShareDir::Install;\ninstall_share "$share_dir";\n},
      qq{package\nMY;\nuse File::ShareDir::Install qw(postamble);\n},
    );
  }

  my $prereq = $self->zilla->prereq;

  my %write_makefile_args = (
    DISTNAME  => $self->zilla->name,
    NAME      => $name,
    AUTHOR    => $self->zilla->authors->join(q{, }),
    ABSTRACT  => $self->zilla->abstract,
    VERSION   => $self->zilla->version,
    LICENSE   => $self->zilla->license->meta_yml_name,
    EXE_FILES => [ @exe_files ],
    PREREQ_PM    => {
      map {; $_ => $prereq->{$_} } grep { $_ ne 'perl' } keys %$prereq
    },
    test => { TESTS => join q{ }, sort keys %test_dirs },
  );

  my $makefile_args_dumper = Data::Dumper->new(
    [ \%write_makefile_args ],
    [ '*WriteMakefileArgs' ],
  );

  my $content = $self->fill_in_string(
    $template,
    {
      perl_prereq       => \($self->zilla->prereq->{perl}),
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

sub build {
  my $self = shift;
  system($^X => 'Makefile.PL') and die "error with Makefile.PL\n";
  system('make')               and die "error running make\n";
  return;
}

sub test {
  my ( $self, $target ) = @_;
  ## no critic Punctuation
  $self->build;
  system('make test') and die "error running make test\n";
  return;
}

has 'eumm_version' => (
  isa => 'Str',
  is  => 'rw',
  default => '6.11',
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;
