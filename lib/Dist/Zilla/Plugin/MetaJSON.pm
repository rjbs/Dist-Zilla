package Dist::Zilla::Plugin::MetaJSON;
# ABSTRACT: produce a META.json
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

use CPAN::Meta::Converter 2.101380; # downgrade
use Dist::Zilla::File::FromCode;
use Hash::Merge::Simple ();
use JSON 2;

=head1 DESCRIPTION

This plugin will add a F<META.json> file to the distribution.

This file is meant to replace the old-style F<META.yml>.  For more information
on this file, see L<Module::Build::API> and L<CPAN::Meta>.

=attr filename

If given, parameter allows you to specify an alternate name for the generated
file.  It defaults, of course, to F<META.json>.

=cut

has filename => (
  is  => 'ro',
  isa => 'Str',
  default => 'META.json',
);

=attr version

This parameter lets you pick what version of the spec to use when generating
the output.  It defaults to 2 at present, but may be updated to new specs as
they are released and adopted.

If you want a fixed version, specify it.

=cut

has version => (
  is  => 'ro',
  isa => 'Num',
  default => '2',
);

sub gather_files {
  my ($self, $arg) = @_;

  my $zilla = $self->zilla;

  my $file  = Dist::Zilla::File::FromCode->new({
    name => $self->filename,
    code => sub {
      my $distmeta  = $zilla->distmeta;
      my $converter = CPAN::Meta::Converter->new($distmeta);
      my $output    = $converter->convert(version => $self->version);

      JSON->new->ascii(1)->canonical(1)->pretty->encode($output)
      . "\n";
    },
  });

  $self->add_file($file);
  return;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
