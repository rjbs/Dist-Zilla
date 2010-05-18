package Dist::Zilla::Plugin::MetaYAML;
# ABSTRACT: produce a META.yml
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

use CPAN::Meta::Converter 2.101380; # downgrade
use Hash::Merge::Simple ();

=head1 DESCRIPTION

This plugin will add a F<META.yml> file to the distribution.

For more information on this file, see L<Module::Build::API> and L<CPAN::Meta>.

=cut

has filename => (
  is  => 'ro',
  isa => 'Str',
  default => 'META.yml',
);

has version => (
  is  => 'ro',
  isa => 'Num',
  default => '1.4',
);

sub gather_files {
  my ($self, $arg) = @_;

  require Dist::Zilla::File::FromCode;
  require YAML::Tiny;

  my $zilla = $self->zilla;

  my $file  = Dist::Zilla::File::FromCode->new({
    name => $self->filename,
    code => sub {
      my $distmeta  = $zilla->distmeta;
      my $converter = CPAN::Meta::Converter->new($distmeta);
      my $output    = $converter->convert(version => $self->version);

      $output->{generated_by} = $distmeta->{generated_by};

      YAML::Tiny::Dump($output);
    },
  });

  $self->add_file($file);
  return;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
