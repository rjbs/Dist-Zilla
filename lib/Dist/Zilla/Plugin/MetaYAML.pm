package Dist::Zilla::Plugin::MetaYAML;
# ABSTRACT: produce a META.yml

use Moose;
with 'Dist::Zilla::Role::FileGatherer';

use Dist::Zilla::Dialect;

use Try::Tiny;
use namespace::autoclean;

=head1 DESCRIPTION

This plugin will add a F<META.yml> file to the distribution.

For more information on this file, see L<Module::Build::API> and L<CPAN::Meta>.

=attr filename

If given, parameter allows you to specify an alternate name for the generated
file.  It defaults, of course, to F<META.yml>.

=cut

has filename => (
  is  => 'ro',
  isa => 'Str',
  default => 'META.yml',
);

sub gather_files ($self) {
  require Dist::Zilla::File::FromCode;
  require YAML::Tiny;
  require CPAN::Meta::Converter;
  CPAN::Meta::Converter->VERSION(2.101550); # improved downconversion
  require CPAN::Meta::Validator;
  CPAN::Meta::Validator->VERSION(2.101550); # improved downconversion

  my $zilla = $self->zilla;

  my $file  = Dist::Zilla::File::FromCode->new({
    name => $self->filename,
    code_return_type => 'text',
    code => sub {
      my $distmeta  = $zilla->distmeta;

      my $validator = CPAN::Meta::Validator->new($distmeta);

      unless ($validator->is_valid) {
        my $msg = "Invalid META structure.  Errors found:\n";
        $msg .= join( "\n", $validator->errors );
        $self->log_fatal($msg);
      }

      my $converter = CPAN::Meta::Converter->new($distmeta);
      my $output    = $converter->convert(version => '1.4');
      $output->{x_serialization_backend} = sprintf '%s version %s',
            'YAML::Tiny', YAML::Tiny->VERSION;

      my $yaml = try {
        YAML::Tiny->new($output)->write_string; # text!
      } catch {
        $self->log_fatal("Could not create YAML string: " . YAML::Tiny->errstr)
      };
      return $yaml;
    },
  });

  $self->add_file($file);
  return;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 SEE ALSO

Core Dist::Zilla plugins:
L<@Basic|Dist::Zilla::PluginBundle::Basic>,
L<Manifest|Dist::Zilla::Plugin::Manifest>.

Dist::Zilla roles:
L<FileGatherer|Dist::Zilla::Role::FileGatherer>.

Other modules:
L<CPAN::Meta>,
L<CPAN::Meta::Spec>, L<YAML>.

=cut
