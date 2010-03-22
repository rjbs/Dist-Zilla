package Dist::Zilla::Plugin::ModuleBuild;
# ABSTRACT: build a Build.PL that uses Module::Build
use List::MoreUtils qw(any uniq);
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::BuildRunner';
with 'Dist::Zilla::Role::InstallTool';
with 'Dist::Zilla::Role::TextTemplate';
with 'Dist::Zilla::Role::TestRunner';
with 'Dist::Zilla::Role::MetaProvider';

use Dist::Zilla::File::InMemory;
use List::MoreUtils qw(any uniq);
use Data::Dumper;

=head1 DESCRIPTION

This plugin will create a F<Build.PL> for installing the dist using
L<Module::Build>.

=cut

=attr mb_version

B<Optional:> Specify the minimum version of L<Module::Build> to depend on.

Defaults to 0.3601

=cut

has 'mb_version' => (
  isa => 'Str',
  is  => 'rw',
  default => '0.3601',
);

my $template = q|
use strict;
use warnings;

use Module::Build {{ $plugin->mb_version }};

my {{ $module_build_args }}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
|;

sub metadata {
  my ($self) = @_;
  return {
    configure_requires => { 'Module::Build' => $self->mb_version },
    build_requires     => { 'Module::Build' => $self->mb_version },
  };
}

sub setup_installer {
  my ($self, $arg) = @_;

  $self->log_fatal("can't build Build.PL; license has no known META.yml value")
    unless $self->zilla->license->meta_yml_name;

  (my $name = $self->zilla->name) =~ s/-/::/g;

  my @exe_files =
    $self->zilla->find_files(':ExecFiles')->map(sub { $_->name })->flatten;

  $self->log_fatal("can't install files with whitespace in their names")
    if grep { /\s/ } @exe_files;

  my %module_build_args = (
    module_name   => $name,
    license       => $self->zilla->license->meta_yml_name,
    dist_abstract => $self->zilla->abstract,
    dist_name     => $self->zilla->name,
    dist_version  => $self->zilla->version,
    dist_author   => [ $self->zilla->authors->flatten ],
    script_files  => \@exe_files,
    ($self->zilla->_share_dir ? (share_dir => $self->zilla->_share_dir) : ()),

    # I believe it is a happy coincidence, for the moment, that this happens to
    # return just the same thing that is needed here. -- rjbs, 2010-01-22
    $self->zilla->prereq->as_distmeta->flatten,
  );

  $self->__module_build_args(\%module_build_args);

  my $module_build_dumper = Data::Dumper->new(
    [ \%module_build_args ],
    [ '*module_build_args' ],
  );

  my $content = $self->fill_in_string(
    $template,
    {
      plugin            => \$self,
      module_build_args => \($module_build_dumper->Dump),
    },
  );

  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'Build.PL',
    content => $content,
  });

  $self->add_file($file);
  return;
}

# XXX:  Just here to facilitate testing. -- rjbs, 2010-03-20
has __module_build_args => (
  is   => 'rw',
  isa  => 'HashRef',
);

sub build {
  my $self = shift;
  system($^X => 'Build.PL') and die "error with Build.PL\n";
  system('./Build')         and die "error running ./Build\n";
  return;
}

sub test {
  my ( $self, $target ) = @_;
  ## no critic Punctuation
  $self->build;
  system('./Build test') and die "error running ./Build test\n";
  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
