package Dist::Zilla::Plugin::MetaYAML;
# ABSTRACT: produce a META.yml
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

use Encode qw(encode_utf8 decode_utf8 FB_CROAK);
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
      my $yaml      = YAML::Tiny::Dump($output);

      # Okay, this code is all stuff that makes rjbs cry, but it's all his
      # fault, too, because he wasn't really strict about text vs. bytes to
      # begin with.  Why not?  Because he was lazy.  He is very sorry, please
      # do not be too hard with him.  He mostly lives in an ASCII neighborhood,
      # and sometimes doesn't notice his own privilege.
      #
      # There are a few possibilities:
      #   1) It's all ASCII.  Whatevs.
      #   2) It's code points 0x00 to 0xFF and...
      #     a) it's Latin-1/Unicode text
      #     b) it's UTF-8
      #   3) It has code points above 0xFF and must be Unicode.
      #   4) Some stupid nonsense that I don't care about.
      #
      # In (1) we output the codepoints as is.
      # In (3) we can encode to UTF-8 and feel pretty good about that.
      # In (4) I don't give a darn.
      #
      # Between the other cases, the question is: did we get text or octets?
      # We *should* be sure that it's all text, but right now it's usually
      # octets.  If the document is a valid UTF-8 string, we emit it as is.  If
      # it's not, we assume it's text and encode it to UTF-8.
      #
      # -- rjbs, 2013-09-07
      if (grep {; /\P{ASCII}/ } $yaml) {
        if (
          $yaml =~ /[^\x00-\xFF]/
          or
          ! eval { decode_utf8($yaml, FB_CROAK); 1 }
        ) {
          # Characters over \xFF or not a valid UTF-8 buffer:
          # assume it's all text.
          $yaml = encode_utf8($yaml);
        } else {
          # It's already valid UTF-8.  Emit it as is.
          $yaml = encode_utf8($yaml);
        }
      }

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
