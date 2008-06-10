package Dist::Zilla::Plugin::PodWeaver;
# ABSTRACT: do horrible things to POD, producing better docs
use Moose;
use Moose::Autobox;
use List::MoreUtils qw(any);
with 'Dist::Zilla::Role::FileMunger';

=head1 WARNING

This code is really, really sketchy.  It's crude and brutal and will probably
break whatever it is you were trying to do.

Eventually, this code will be really awesome.  I hope.  It will probably
provide an interface to something more cool and sophisticated.  Until then,
don't expect it to do anything but bring sorrow to you and your people.

=head1 DESCRIPTION

PodWeaver is a work in progress, which rips apart your kinda-POD and
reconstructs it as boring old real POD.

=cut

sub munge_file {
  my ($self, $file) = @_;

  return $self->munge_pod($file)
    if $file->name =~ /\.(?:pm|pod)$/i
    and ($file->name !~ m{/} or $file->name =~ m{^lib/});

  return;
}

sub _filter(&\@) {
  my ($code, $array) = @_;

  my @result;
  for my $i (reverse 0 .. $#$array) {
    local $_ = $array->[$i];
    push @result, splice @$array, $i, 1 if $code->();
  }
  return @result;
}

{
  package Dist::Zilla::Plugin::PodWeaver::Eventual;
  our @ISA = 'Pod::Eventual';
  sub new {
    my ($class) = @_;
    require Pod::Eventual;
    bless [] => $class;
  }

  sub handle_event { push @{$_[0]}, $_[1] }
  sub events { @{ $_[0] } }
  sub read_string { my $self = shift; $self->SUPER::read_string(@_); $self }

  sub write_string {
    my ($self, $events) = @_;
    my $str = "\n=pod\n\n";

    EVENT: for my $event (@$events) {
      if ($event->{type} eq 'verbatim') {
        $event->{content} =~ s/^/  /mg;
        $event->{type} = 'text';
      }

      if ($event->{type} eq 'text') {
        $str .= "$event->{content}\n";
        next EVENT;
      }

      $str .= "=$event->{command} $event->{content}\n";
    }

    return $str;
  }
}

sub _h1 {
  my $name = shift;
  any { $_->{type} eq 'command' and $_->{content} =~ /^\Q$name$/m } @_;
}

sub munge_pod {
  my ($self, $file) = @_;

  require PPI;
  my $content = $file->content;
  my $doc = PPI::Document->new(\$content);
  my @pod_tokens = map {"$_"} @{ $doc->find('PPI::Token::Pod') || [] };
  $doc->prune('PPI::Token::Pod');

  if (@{ $doc->find('PPI::Token::HereDoc') || [] }) {
    $self->log(
      sprintf "can't invoke %s on %s: PPI can't munge code with here-docs",
        $self->plugin_name, $file->name
    );
    return;
  }

  my $pe = 'Dist::Zilla::Plugin::PodWeaver::Eventual';

  if ($pe->new->read_string("$doc")->events) {
    $self->log(
      sprintf "can't invoke %s on %s: there is POD inside string literals",
        $self->plugin_name, $file->name
    );
    return;
  }

  my @pod = $pe->new->read_string(join "\n", @pod_tokens)->events;
  # _filter { $_->{type} eq 'command' and $_->{command} eq 'cut' } @pod;

  unless (_h1(VERSION => @pod)) {
    unshift @pod, (
      { type => 'command', command => 'head1', content => "VERSION\n"  },
      { type => 'text',   
        content => sprintf "version %s\n", $self->zilla->version }
    );
  }

  unless (_h1(NAME => @pod)) {
    Carp::croak "couldn't find package declaration in " . $file->name
      unless my $pkg_node = $doc->find_first('PPI::Statement::Package');
    my $package = $pkg_node->namespace;

    $self->log("couldn't find abstract in " . $file->name)
      unless my ($abstract) = $doc =~ /^\s*#+\s*ABSTRACT:\s*(.+)$/m;

    my $name = $package;
    $name .= " - $abstract" if $abstract;

    unshift @pod, (
      { type => 'command', command => 'head1', content => "NAME\n"  },
      { type => 'text',                        content => "$name\n" },
    );
  }

  my (@methods, $in_method);

  $self->_regroup($_->[0] => $_->[1] => \@pod)
    for ( [ attr => 'ATTRIBUTES' ], [ method => 'METHODS' ] );

  unless (_h1(AUTHOR => @pod) or _h1(AUTHORS => @pod)) {
    my @authors = $self->zilla->authors->flatten;
    my $name = @authors > 1 ? 'AUTHORS' : 'AUTHOR';

    push @pod, (
      { type => 'command',  command => 'head1', content => "$name\n" },
      { type => 'verbatim',
        content => join("\n", @authors) . "\n"
      }
    );
  }

  unless (_h1(COPYRIGHT => @pod) or _h1(LICENSE => @pod)) {
    push @pod, (
      { type => 'command', command => 'head1',
        content => "COPYRIGHT AND LICENSE\n" },
      { type => 'text', content => $self->zilla->license->notice }
    );
  }

  @pod = grep { $_->{type} ne 'command' or $_->{command} ne 'cut' } @pod;
  push @pod, { type => 'command', command => 'cut', content => "\n" };

  my $newpod = $pe->write_string(\@pod);

  my $end = do {
    my $end_elem = $doc->find('PPI::Statement::Data')
                || $doc->find('PPI::Statement::End');
    join q{}, @{ $end_elem || [] };
  };

  $doc->prune('PPI::Statement::End');
  $doc->prune('PPI::Statement::Data');

  $content = $end ? "$doc\n\n$newpod\n\n$end" : "$doc\n__END__\n$newpod\n";

  $file->content($content);
}

sub _regroup {
  my ($self, $cmd, $header, $pod) = @_;

  my @items;
  my $in_item;

  EVENT: for (my $i = 0; $i < @$pod; $i++) {
    my $event = $pod->[$i];

    if ($event->{type} eq 'command' and $event->{command} eq $cmd) {
      $in_item = 1;
      push @items, splice @$pod, $i--, 1;
      next EVENT;
    }

    if (
      $event->{type} eq 'command'
      and $event->{command} !~ /^(?:over|item|back|head[3456])$/
    ) {
      $in_item = 0;
      next EVENT;
    }

    push @items, splice @$pod, $i--, 1 if $in_item;
  }
      
  if (@items) {
    unless (_h1($header => @$pod)) {
      push @$pod, {
        type    => 'command',
        command => 'head1',
        content => "$header\n",
      };
    }

    $_->{command} = 'head2'
      for grep { ($_->{command}||'') eq $cmd } @items;

    push @$pod, @items;
  }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
