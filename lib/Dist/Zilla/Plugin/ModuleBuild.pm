package Dist::Zilla::Plugin::ModuleBuild;
# ABSTRACT: build a Build.PL that uses Module::Build
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::InstallTool';
with 'Dist::Zilla::Role::TextTemplate';
with 'Dist::Zilla::Role::TestRunner';
with 'Dist::Zilla::Role::MetaProvider';

use Dist::Zilla::File::InMemory;

=head1 DESCRIPTION

This plugin will create a F<Build.PL> for installing the dist using
L<Module::Build>.

=cut

=attr mb_version

B<Optional:> Specify the minimum version of L<Module::Build> to depend on.

Defaults to 0.35.

=cut

has 'mb_version' => (
  isa => 'Str',
  is  => 'rw',
  default => '0.35',
);

my $template = q|
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name   => '{{ $module_name }}',
  license       => '{{ $dist->license->meta_yml_name }}',
  dist_abstract => "{{ quotemeta($dist->abstract) }}",
  dist_name     => "{{ quotemeta($dist->name) }}",
  dist_author   => [
{{
    $OUT .= q{"} . quotemeta($_) . q{",} for @{ $dist->authors };
    chomp $OUT;
    return '';
}}
  ],
  requires      => {
{{
    my $prereq = $dist->prereq;
    $OUT .= qq{    "$_" => '$prereq->{$_}',\n} for keys %$prereq;
    chomp $OUT;
    return '';
}}
  },
  script_files => [ qw({{ $exe_files }}) ],
);

$build->create_build_script;
|;

#  module_name   => "{{ quotemeta(
#    (sort {length $a <=> length $b}
#     grep { m{^lib/.+\.pm$} } @{$dist->files})[0]
#  ) }}",

sub metadata {
  my $self = shift;
  return {
    configure_requires => { 'Module::Build' => $self->mb_version },
    build_requires     => { 'Module::Build' => $self->mb_version },
  };
}

sub setup_installer {
  my ($self, $arg) = @_;

  Carp::croak("can't build a Build.PL; license has no known META.yml value")
    unless $self->zilla->license->meta_yml_name;

  (my $name = $self->zilla->name) =~ s/-/::/g;

  my $exe_files = $self->zilla->files
                ->grep(sub { ($_->install_type||'') eq 'bin' })
                ->map(sub { $_->name })
                ->join(' ');

  my $content = $self->fill_in_string(
    $template,
    {
      module_name => $name,
      dist        => \$self->zilla,
      exe_files   => \$exe_files,
    },
  );

  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'Build.PL',
    content => $content,
  });

  $self->add_file($file);
  return;
}

sub test {
  my ( $self, $target ) = @_;
  eval {
    ## no critic Punctuation
    system($^X => 'Build.PL') and die "error with Makefile.PL\n";
    system('./Build') and die "error running make\n";
    system('./Build test') and die "error running make test\n";
    1;
  } or return $@;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
