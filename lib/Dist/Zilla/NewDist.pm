package Dist::Zilla::NewDist;
use Moose;

use File::HomeDir ();
use Moose::Autobox;
use Path::Class;

use namespace::autoclean;

### BEGIN STUFF SHARED WITH DZ

has chrome => (
  is  => 'rw',
  isa => 'Object', # will be does => 'Dist::Zilla::Role::Chrome' when it exists
  required => 1,
);

has logger => (
  is   => 'ro',
  isa  => 'Log::Dispatchouli::Proxy', # could be duck typed, I guess
  lazy => 1,
  handles => [ qw(log log_debug log_fatal) ],
  default => sub {
    $_[0]->chrome->logger->proxy({ proxy_prefix => '[DZ] ' })
  },
);

has plugins => (
  is   => 'ro',
  isa  => 'ArrayRef[Dist::Zilla::Role::Plugin]',
  init_arg => undef,
  default  => sub { [ ] },
);

### END STUFF SHARED WITH DZ

sub _new_from_profile {
  my ($class, $profile_name, $arg) = @_;
  $arg ||= {};

  my $config_class = $arg->{config_class} ||= 'Dist::Zilla::Config::Finder';
  Class::MOP::load_class($config_class);

  $arg->{chrome}->logger->log_debug(
    { prefix => '[DZ] ' },
    "reading configuration using $config_class"
  );

  my $profile_dir = dir( File::HomeDir->my_home )->subdir(qw(.dzil profiles));

  my $sequence;

  if ($profile_name eq 'default' and ! -e $profile_dir->subdir('default')) {
    ...
  } else {
    ($sequence) = $config_class->new->read_config({
      root     => $profile_dir->subdir($profile_name),
      basename => 'profile',
    });
  }

  my $self = $class->new({
    chrome => $arg->{chrome},
  });

  for my $section ($sequence->sections) {
    next if $section->name eq '_';

    my ($name, $plugin_class, $arg) = (
      $section->name,
      $section->package,
      $section->payload,
    );

    $self->log_fatal("$name arguments attempted to override plugin name")
      if defined $arg->{plugin_name};

    $self->log_fatal("$name arguments attempted to override plugin name")
      if defined $arg->{zilla};

    my $plugin = $plugin_class->new(
      $arg->merge({
        plugin_name => $name,
        zilla       => $self,
      }),
    );

    my $version = $plugin->VERSION || 0;

    $plugin->log_debug([ 'online, %s v%s', $plugin->meta->name, $version ]);

    $self->plugins->push($plugin);
  }

  return $self;
}

sub mint_dist {
  my ($self, $arg) = @_;

  $self->log([
    'dzil new does nothing; if it did something, it would have created %s',
    $arg->{name},
  ]);
}

1;
