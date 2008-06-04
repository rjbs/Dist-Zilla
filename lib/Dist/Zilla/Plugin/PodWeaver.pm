package Dist::Zilla::Plugin::PodWeaver;
# ABSTRACT: do horrible things to POD, producing better docs
use Moose;
use Moose::Autobox;
use List::MoreUtils qw(any);
with 'Dist::Zilla::Role::FileMunger';

=head1 WARNING

This code is really, really awful.  It's crude and brutal and will probably
break whatever it is you were trying to do.

Eventually, this code will be really awesome.  I hope.  It will probably
provide an interface to something more cool and sophisticated.  Until then,
don't expect it to do anything but bring sorrow to you and your people.

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

sub munge_pod {
  my ($self, $file) = @_;
  require PPI;
  my $content = $file->content;
  my $doc = PPI::Document->new(\$content);
  my @pod = map {"$_"} @{ $doc->find('PPI::Token::Pod') || [] };
  $doc->prune('PPI::Token::Pod');

  unless (any { /^=head1 VERSION$/m } @pod) {
    unshift @pod, sprintf "\n=head1 VERSION\n\nversion %s\n\n",
      $self->zilla->version;
  }

  unless (any { /^=head1 NAME$/m } @pod) {
    Carp::croak "couldn't find package declaration in " . $file->name
      unless my $pkg_node = $doc->find_first('PPI::Statement::Package');
    my $package = $pkg_node->namespace;

    $self->log("couldn't find abstract in " . $file->name)
      unless my ($abstract) = $doc =~ /^\s*#+\s*ABSTRACT:\s*(.+)$/m;

    my $name = $package;
    $name .= " - $abstract" if $abstract;
    unshift @pod, sprintf "\n=head1 NAME\n\n%s\n\n", $name;
  }

  if (my @methods = _filter { /^=method / } @pod) {
    unless (any { /^=head1 METHODS$/m } @pod) {
      push @pod, "\n=head1 METHODS\n\n";
    }

    push @pod, map { s/^=method /=head2 /gm; $_ } @methods;
  }

  unless (any { /^=head1 AUTHORS?$/m } @pod) {
    my @authors = $self->zilla->authors->flatten;
    my $name = @authors > 1 ? 'AUTHORS' : 'AUTHOR';

    push @pod, "\n=head1 $name\n\n"
            . join("\n", map { "  $_" } @authors)
            . "\n\n";
  }

  unless (any { /^=head1 (?:COPYRIGHT|LICENSE)$/m } @pod) {
    push @pod, ("\n=head1 COPYRIGHT AND LICENSE\n\n"
               . $self->zilla->license->notice
               . "\n\n");
  }


  my $newpod = join qq{\n}, @pod;
  $newpod .= "\n=cut" unless $newpod =~ /=cut\n+/ms;

  my $end = do {
    my $end_elem = $doc->find('PPI::Statement::End');
    join q{}, @{ $end_elem || [] };
  };

  $doc->prune('PPI::Statement::End');

  $content = $end ? "$doc\n\n$newpod\n\n$end" : "$doc\n__END__\n$newpod\n";

  $file->content($content);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
