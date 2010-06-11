package Dist::Zilla::Role::MintingProfile;
# ABSTRACT: something that can find a minting profile dir
use Moose::Role;

=head1 DESCRIPTION

Plugins implementing this role should provide C<profile_dir> method, which,
given a profile name, should return a directory with it.

The default implementation looks in the module's L<ShareDir|File::ShareDir>.

=cut

sub profile_dir {
  my ($self, $profile_name) = @_;

  my $profile_dir = dir( File::ShareDir::module_dir($self->meta->name) )
                  ->subdir( $profile_name );

  return $profile_dir if -d $profile_dir;

  die "Can't find profile $profile_name via $self";
}

no Moose::Role;
1;
