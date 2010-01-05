package Dist::Zilla::Plugin::MakeMaker;

# ABSTRACT: build a Makefile.PL that uses ExtUtils::MakeMaker
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::InstallTool';
with 'Dist::Zilla::Role::TextTemplate';
with 'Dist::Zilla::Role::TestRunner';

=head1 DESCRIPTION

This plugin will produce an L<ExtUtils::MakeMaker>-powered F<Makefile.PL> for
the distribution.  If loaded, the L<Manifest|Dist::Zilla::Plugin::Manifest>
plugin should also be loaded.

=cut

use List::MoreUtils qw(any uniq);

use namespace::autoclean;

use Dist::Zilla::File::InMemory;

my $template = q|
use strict;
use warnings;

{{
  my $prereq = $dist->prereq;
  exists $prereq->{perl}
    ? qq{ BEGIN { require $prereq->{perl}; } }
    : '';
}}

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => '{{ $dist->name     }}',
  NAME      => '{{ $module_name    }}',
  AUTHOR    => "{{ $author_str     }}",
  ABSTRACT  => "{{ quotemeta($dist->abstract) }}",
  VERSION   => '{{ $dist->version  }}',
  EXE_FILES => [ {{ $exe_files }} ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => '{{ $dist->license->meta_yml_name }}') : ()),
  PREREQ_PM    => {
{{
      my $prereq = $dist->prereq;
      $OUT .= qq{    "$_" => '$prereq->{$_}',\n} for grep { $_ ne 'perl' } keys %$prereq;
      chomp $OUT;
      return '';
}}
  },
  test => {TESTS => '{{ $test_dirs }}'}
);

|;

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

  my $exe_files = join q{, }, map { q{"} . quotemeta($_) . q{"} } @exe_files;

  my %test_dirs;
  for my $file ($self->zilla->files->flatten) {
    next unless $file->name =~ m{\At/.+\.t\z};
    (my $dir = $file->name) =~ s{/[^/]+\.t\z}{/*.t}g;

    $test_dirs{ $dir } = 1;
  }

  my $content = $self->fill_in_string(
    $template,
    {
      module_name => $name,
      dist        => \$self->zilla,
      exe_files   => \$exe_files,
      author_str  => \quotemeta( $self->zilla->authors->join(q{, }) ),
      test_dirs   => join (q{ }, sort keys %test_dirs),
    },
  );

  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'Makefile.PL',
    content => $content,
  });

  $self->add_file($file);
  return;
}

sub test {
  my ( $self, $target ) = @_;
  ## no critic Punctuation
  system($^X => 'Makefile.PL') and die "error with Makefile.PL\n";
  system('make') and die "error running make\n";
  system('make test') and die "error running make test\n";
  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
