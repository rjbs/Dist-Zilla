use strict;
use warnings;
package Dist::Zilla::Util;
# ABSTRACT: random snippets of code that Dist::Zilla wants

use Carp ();
use Encode ();
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
      $self->{abstract} =~ s/\s+/\x20/g;
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

  my $chars = $file->content;
  my $bytes = Encode::encode('UTF-8', $chars, Encode::FB_CROAK);

  $e->read_string($bytes);

  return $e->{abstract};
}

=method expand_config_package_name

  my $pkg_name = Util->expand_config_package_name($string);

This method, I<which is likely to change or go away>, rewrites the given string
into a package name.

Prefixes are rewritten as follows:

=for :list
* C<=> becomes nothing
* C<@> becomes C<Dist::Zilla::PluginBundle::>
* C<%> becomes C<Dist::Zilla::Stash::>
* otherwise, C<Dist::Zilla::Plugin::> is prepended

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
  require Path::Class;
  return Path::Class::dir($ENV{DZIL_GLOBAL_CONFIG_ROOT}) if $ENV{DZIL_GLOBAL_CONFIG_ROOT};

  require File::HomeDir;
  my $homedir = File::HomeDir->my_home
    or Carp::croak("couldn't determine home directory");

  return Path::Class::dir($homedir)->subdir('.dzil');
}

sub _assert_loaded_class_version_ok {
  my ($self, $pkg, $version) = @_;

  require CPAN::Meta::Requirements;
  my $req = CPAN::Meta::Requirements->from_string_hash({
    $pkg => $version,
  });

  my $have_version = $pkg->VERSION;
  unless ($req->accepts_module($pkg => $have_version)) {
    die( sprintf
      "%s version (%s) does not match required version: %s\n",
      $pkg,
      $have_version,
      $version,
    );
  }
}

1;
