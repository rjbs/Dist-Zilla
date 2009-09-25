package Dist::Zilla::Plugin::MakeMaker;

# ABSTRACT: build a Makefile.PL that uses ExtUtils::MakeMaker
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::InstallTool';
with 'Dist::Zilla::Role::TextTemplate';

=head1 DESCRIPTION

This plugin will produce an L<ExtUtils::MakeMaker>-powered F<Makefile.PL> for
the distribution.  It loaded, the L<Manifest|Dist::Zilla::Plugin::Manifest>
plugin should also be loaded.

=cut

use Dist::Zilla::File::InMemory;

my $template = q|
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => '{{ $dist->name     }}',
  NAME      => '{{ $module_name    }}',
  AUTHOR    => '{{ $author_str     }}',
  ABSTRACT  => '{{ quotemeta($dist->abstract) }}',
  VERSION   => '{{ $dist->version  }}',
  EXE_FILES => [ qw({{ $exe_files }}) ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => '{{ $dist->license->meta_yml_name }}') : ()),
  PREREQ_PM    => {
{{
      my $prereq = $dist->prereq;
      $OUT .= qq{    "$_" => '$prereq->{$_}',\n} for keys %$prereq;
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

  my $exe_files = $self->zilla->files
    ->grep( sub { ( $_->install_type || '' ) eq 'bin' } )
    ->map(  sub { $_->name } )
    ->join(q{ });

  my %test_dirs;
  $self->zilla->files->grep( sub {
    $_->name =~ /\.t$/
    && $_->name =~ /^(.*\/).*?$/
    && ($test_dirs{$1 . '*.t'}++)
  });
  
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

__PACKAGE__->meta->make_immutable;
no Moose;
1;
