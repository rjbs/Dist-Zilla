package Dist::Zilla::MVP::Assembler;
use Moose;
extends 'Config::MVP::Assembler';
with 'Config::MVP::Assembler::WithBundles';
# ABSTRACT: Dist::Zilla-specific subclass of Config::MVP::Assembler

use Dist::Zilla::Util;

=head1 DESCRIPTION

B<Take this next bit seriously!>  If you don't understand how L<Config::MVP>
works, reading about how the Dist::Zilla-specific Assembler works is not going
to be useful.

Dist::Zilla::MVP::Assembler extends L<Config::MVP::Assembler> and composes
L<Config::MVP::Assembler::WithBundles>.  For potential plugin bundles (things
composing L<Dist::Zilla::Role::PluginBundle>)

The Assembler has chrome, so it can log and will (eventually) be able to get
input from the user.

The Assembler's C<expand_package> method delegates to Dist::Zilla::Util's
L<expand_config_package_name|Dist::Zilla::Util/expand_config_package_name>
method.

The Assembler will throw an exception if it is instructed to add a value for
C<plugin_name> or C<zilla>.

=cut

has chrome => (
  is   => 'rw',
  does => 'Dist::Zilla::Role::Chrome',
  required => 1,
);

has logger => (
  is   => 'ro',
  isa  => 'Log::Dispatchouli::Proxy', # could be duck typed, I guess
  lazy => 1,
  handles => [ qw(log log_debug log_fatal) ],
  default => sub {
    $_[0]->chrome->logger->proxy({ proxy_prefix => '[DZ] ' })
  },
);

sub expand_package {
  return scalar Dist::Zilla::Util->expand_config_package_name($_[1]);
}

sub package_bundle_method {
  my ($self, $pkg) = @_;
  return unless $pkg->isa('Moose::Object')
         and    $pkg->does('Dist::Zilla::Role::PluginBundle');
  return 'bundle_config';
}

before add_value => sub {
  my ($self, $name) = @_;

  return unless $name =~ /\A(?:plugin_name|zilla)\z/;

  my $section_name = $self->current_section->name;
  $self->log_fatal(
    "$section_name arguments attempted to provide reserved argument $name"
  );
};

no Moose;
1;
