use strict;
use warnings;
package Dist::Zilla::Util;
# ABSTRACT: random snippets of code that Dist::Zilla wants

{
  package
    Dist::Zilla::Util::PEA;
  use base 'Pod::Eventual';
  sub _new  { bless {} => shift; }
  sub handle_nonpod {
    my ($self, $str) = @_;
    return if $self->{abstract};
    return $self->{abstract} = $1 if $str =~ /^#+ ABSTRACT:\s+(.+)$/;
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
      and $event->{content} =~ /^\S+\s+-+\s+(.+)$/
    ) {
      $self->{abstract} = $1;
    }
  }
}

sub _abstract_from_file {
  my ($self, $filename) = @_;
  my $e = Dist::Zilla::Util::PEA->_new;
  $e->read_file($filename);
  return $e->{abstract};
}

1;
