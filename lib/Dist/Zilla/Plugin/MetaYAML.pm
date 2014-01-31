package Dist::Zilla::Plugin::MetaYAML;
# ABSTRACT: produce a META.yml

use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

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

=attr version

This parameter lets you pick what version of the spec to use when generating
the output.  It defaults to 1.4, the most commonly supported version at
present.

B<This may change without notice in the future.>

Once version 2 of the META file spec is more widely supported, this may default
to 2.

=cut

has version => (
  is  => 'ro',
  isa => 'Num',
  default => '1.4',
);

around dump_config => sub {
  my $orig = shift;
  my $self = shift;

  my $config = $self->$orig;

  $config->{'' . __PACKAGE__} = { version => $self->version };

  return $config;
};

sub gather_files {
  my ($self, $arg) = @_;

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
      my $output    = $converter->convert(version => $self->version);
      my $yaml = try {
        YAML::Tiny->new($output)->write_string; # text!
      }
      catch {
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
