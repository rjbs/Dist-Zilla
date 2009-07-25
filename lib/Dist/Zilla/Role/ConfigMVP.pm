package Dist::Zilla::Role::ConfigMVP;
use Moose::Role;
# ABSTRACT: something that converts Config::MVP sequences to config structs

use Dist::Zilla::Config::MVPAssembler;

has assembler => (
  is   => 'ro',
  isa  => 'Dist::Zilla::Config::MVPAssembler',
  lazy => 1,
  default => sub {
    my $assembler = Dist::Zilla::Config::MVPAssembler->new;

    my $root = $assembler->section_class->new({
      name => '_',
      aliases => { author => 'authors' },
      multivalue_args => [ qw(authors) ],
    });

    $assembler->sequence->add_section($root);

    return $assembler;
  }
);

sub config_from_mvp {
  my ($self) = @_;

  my @sections = $self->assembler->sequence->sections;

  my $root_config = (shift @sections)->payload;

  my @plugins;
  for my $section (@sections) {
    my $config = {
      %{ $section->payload },
      plugin_name => $section->name,
    };

    if (eval { $section->package->does('Dist::Zilla::Role::PluginBundle') }) {
      push @plugins, $section->package->bundle_config($config);
    } else {
      push @plugins, [ $section->package => $config ];
    }
  }

  return ($root_config, \@plugins);
}

no Moose::Role;
1;
