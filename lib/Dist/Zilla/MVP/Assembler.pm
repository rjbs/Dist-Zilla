package Dist::Zilla::MVP::Assembler;
use Moose;
extends 'Config::MVP::Assembler';
with 'Config::MVP::Assembler::WithBundles';
# ABSTRACT: Dist::Zilla-specific subclass of Config::MVP::Assembler

use Dist::Zilla::Util;

has chrome => (
  is  => 'rw',
  isa => 'Object', # will be does => 'Dist::Zilla::Role::Chrome' when it exists
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

no Moose;
1;
