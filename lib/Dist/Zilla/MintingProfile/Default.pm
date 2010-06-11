package Dist::Zilla::MintingProfile::Default;
use Moose;
with 'Dist::Zilla::Role::MintingProfile';

use File::ShareDir;
use Path::Class;

use namespace::autoclean;

sub profile_dir {
  my ($self, $profile_name) = @_;
  $profile_name ||= 'default';

  my $profile_dir = dir( File::HomeDir->my_home )
                  ->subdir('.dzil', 'profiles', $profile_name);

  return $profile_dir if -d $profile_dir;

  $profile_dir = dir( File::ShareDir::dist_dir('Dist-Zilla') )
               ->subdir('profiles', $profile_name);
 
  return $profile_dir if -d $profile_dir;

  confess "can't find profile $profile_name via $self";
}

1;
