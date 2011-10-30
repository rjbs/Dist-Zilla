use strict;
use warnings;
package Dist::Zilla::Util;
# ABSTRACT: random snippets of code that Dist::Zilla wants

use File::HomeDir ();
use Path::Class;
use String::RewritePrefix 0.002; # better string context behavior

{
  package
    Dist::Zilla::Util::PEA;
  @Dist::Zilla::Util::PEA::ISA = ('Pod::Eventual');
  sub _new  {
    # Load Pod::Eventual only when used (and not yet loaded)
    unless (exists $INC{'Pod/Eventual.pm'}) {
      require Pod::Eventual;
      Pod::Eventual->VERSION(0.091480); # better nonpod/blank events
    }

    bless {} => shift;
  }
  sub handle_nonpod {
    my ($self, $event) = @_;
    return if $self->{abstract};
    return $self->{abstract} = $1
      if $event->{content}=~ /^\s*#+\s*ABSTRACT:\s*(.+)$/m;
    return;
  }
  sub handle_event {
    my ($self, $event) = @_;
    return if $self->{abstract};
    if (
      ! $self->{in_name}
      and $event->{type} eq 'command'
      and $event->{command} eq 'head1'
      and $event->{content} =~ /^NAME\b/
    ) {
      $self->{in_name} = 1;
      return;
    }

    return unless $self->{in_name};

    if (
      $event->{type} eq 'text'
      and $event->{content} =~ /^(?:\S+\s+)+?-+\s+(.+)\n$/s
    ) {
      $self->{abstract} = $1;
    }
  }
}

=method abstract_from_file

This method, I<which is likely to change or go away>, tries to guess the
abstract of a given file, assuming that it's Perl code.  It looks for a POD
C<=head1> section called "NAME" or a comment beginning with C<ABSTRACT:>.

=cut

sub abstract_from_file {
  my ($self, $file) = @_;
  my $e = Dist::Zilla::Util::PEA->_new;
  $e->read_string($file->content);
  return $e->{abstract};
}

=method expand_config_package_name

  my $pkg_name = Util->expand_config_package_name($string);

This method, I<which is likely to change or go away>, rewrites the given string
into a package name.  Consult L<Dist::Zilla::Config|Dist::Zilla::Config> for
more information.

=cut

sub expand_config_package_name {
  my ($self, $package) = @_;

  my $str = String::RewritePrefix->rewrite(
    {
      '=' => '',
      '@' => 'Dist::Zilla::PluginBundle::',
      '%' => 'Dist::Zilla::Stash::',
      ''  => 'Dist::Zilla::Plugin::',
    },
    $package,
  );

  return $str;
}

sub _global_config_root {
  return dir($ENV{DZIL_GLOBAL_CONFIG_ROOT}) if $ENV{DZIL_GLOBAL_CONFIG_ROOT};

  my $homedir = File::HomeDir->my_home
    or Carp::croak("couldn't determine home directory");

  return dir($homedir)->subdir('.dzil');
}

1;
