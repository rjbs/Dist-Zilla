package Dist::Zilla::PluginBundle::Filter;
# ABSTRACT: use another bundle, with some plugins removed
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::PluginBundle';

=head1 SYNOPSIS

In your F<dist.ini>:

  [@Filter]
  bundle = @Classic
  remove = PodVersion
  remove = Manifest

=head1 DESCRIPTION

This plugin bundle actually wraps and modified another plugin bundle.  It
includes all the configuration for the bundle named in the C<bundle> attribute,
but removes all the entries whose package is given in the C<remove> attributes.

=cut

sub multivalue_args { return qw(remove) }

sub bundle_config {
  my ($self, $config) = @_;
  my $class = ref $self;

  Carp::croak("no bundle given for bundle filter")
    unless my $bundle = $config->{bundle};

  $bundle = Dist::Zilla::Config->_expand_package($bundle);

  eval "require $bundle; 1" or die;

  my @plugins = $bundle->bundle_config;

  return @plugins unless my $remove = $config->{remove};

  require List::MoreUtils;
  for my $i (reverse 0 .. $#plugins) {
    splice @plugins, $i, 1 if List::MoreUtils::any(sub {
      $plugins[$i][0] eq Dist::Zilla::Config->_expand_package($_)
    }, @$remove);
  }

  return @plugins;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
