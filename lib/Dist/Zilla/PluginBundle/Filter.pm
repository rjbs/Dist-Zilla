package Dist::Zilla::PluginBundle::Filter;
# ABSTRACT: use another bundle, with some plugins removed

use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::PluginBundle';

use namespace::autoclean;

use Class::Load qw(try_load_class);
use Dist::Zilla::Util;

=head1 SYNOPSIS

In your F<dist.ini>:

  [@Filter]
  -bundle = @Basic
  -remove = ShareDir
  -remove = UploadToCPAN
  option = for_basic

=head1 DESCRIPTION

This plugin bundle actually wraps and modifies another plugin bundle.  It
includes all the configuration for the bundle named in the C<-bundle> attribute,
but removes all the entries whose package is given in the C<-remove> attributes.

Options not prefixed with C<-> will be passed to the bundle to be filtered.

=head1 SEE ALSO

Core Dist::Zilla plugins: L<@Basic|Dist::Zilla::PluginBundle::Basic>.

Dist::Zilla roles: L<PluginBundle|Dist::Zilla::Role::PluginBundle>.

=cut

sub mvp_multivalue_args { qw(remove -remove) }

sub bundle_config {
  my ($self, $section) = @_;
  my $class = (ref $self) || $self;

  my $config = {};

  my $has_filter_args = $section->{payload}->keys->grep(sub { /^-/ })->length;
  for my $key ($section->{payload}->keys->flatten) {
    my $val = $section->{payload}->{$key};
    my $target = $has_filter_args && ($key !~ /^-/)
      ? 'bundle'
      : 'filter';
    $key =~ s/^-// if $target eq 'filter';
    $config->{$target}->{$key} = $val;
  }

  Carp::croak("no bundle given for bundle filter")
    unless my $bundle = $config->{filter}->{bundle};

  my $pkg = Dist::Zilla::Util->expand_config_package_name($bundle);

  my $load_opts = {};
  if( my $v = $config->{filter}->{version} ){
    $load_opts->{'-version'} = $v;
  }

  unless (try_load_class($pkg, $load_opts)) {
    # XXX Naughty! -- rjbs, 2013-07-23
    Config::MVP::Section->missing_package($pkg, $bundle);
  }

  my @plugins = $pkg->bundle_config({
    name    => $section->{name}, # not 100% sure about this -- rjbs, 2010-03-06
    package => $pkg,
    payload => $config->{bundle} || {},
  });

  return @plugins unless my $remove = $config->{filter}->{remove};

  require List::MoreUtils;
  for my $i (reverse 0 .. $#plugins) {
    splice @plugins, $i, 1 if List::MoreUtils::any(sub {
      $plugins[$i][1] eq Dist::Zilla::Util->expand_config_package_name($_)
    }, @$remove);
  }

  return @plugins;
}

__PACKAGE__->meta->make_immutable;
1;
