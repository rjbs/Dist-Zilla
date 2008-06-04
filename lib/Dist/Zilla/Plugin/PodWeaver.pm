package Dist::Zilla::Plugin::PodWeaver;
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileMunger';

sub munge_file {
  my ($self, $file) = @_;

  return $self->munge_pod($file)
    if $file->name =~ /\.pm$/i
    and ($file->name !~ m{/} or $file->name =~ m{^lib/});

  return;
}

sub munge_pod {
  my ($self, $file) = @_;
  require PPI;
  my $content = $file->content;
  my $doc = PPI::Document->new(\$content);
  my @pod = map {"$_"} @{ $doc->find('PPI::Token::Pod') || [] };
  $doc->prune('PPI::Token::Pod');

  my $newpod = q{} . (@pod ? PPI::Document->new( \( join "\n", @pod ) ) : q{});

  unless ($newpod =~ /^=head1 VERSION$/m) {
    $newpod = sprintf "\n=head1 VERSION\n\nversion %s\n\n%s",
      $self->zilla->version, $newpod;
  }

  unless ($newpod =~ /^=head1 NAME$/m) {
    Carp::croak "couldn't find package declaration in " . $file->name
      unless my $pkg_node = $doc->find_first('PPI::Statement::Package');

    my $package = $pkg_node->namespace;
    $newpod = sprintf "\n=head1 NAME\n\n%s - %s\n\n%s",
      $package, $self->zilla->abstract, $newpod;
  }

  unless ($newpod =~ /^=head1 AUTHORS?$/m) {
    my @authors = $self->zilla->authors->flatten;
    my $name = @authors > 1 ? 'AUTHORS' : 'AUTHOR';
    $newpod .= "\n=head1 $name\n\n";
    $newpod .= "  $_\n" for @authors;
    $newpod .= "\n\n";
  }

  unless ($newpod =~ /^=head1 (COPYRIGHT|LICENSE)/m) {
    $newpod .= "\n=head1 COPYRIGHT AND LICENSE\n\n"
            .  $self->zilla->license->notice;
    $newpod .= "\n\n";
  }

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
