package Dist::Zilla::Plugin::PodWeaver;
use Moose;
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
  return unless my @pod = map {"$_"} @{ $doc->find('PPI::Token::Pod') || [] };
  $doc->prune('PPI::Token::Pod');

  my $newpod = PPI::Document->new( \( join "\n", @pod ) );

  my $end = do {
    my $end_elem = $doc->find('PPI::Statement::End');
    use Data::Dumper;
    warn Dumper($end_elem);
    join '', @{ $end_elem || [] };
  };

  $doc->prune('PPI::Statement::End');

  $content = $end ? "$doc\n\n$newpod\n\n$end" : "$doc\n__END__\n$newpod\n";

  $file->content($content);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
