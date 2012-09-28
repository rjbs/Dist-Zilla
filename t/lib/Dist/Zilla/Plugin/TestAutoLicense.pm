package Dist::Zilla::Plugin::TestAutoLicense;

use Moose;
with(
  'Dist::Zilla::Role::LicenseProvider',
);

use Software::License::None;

sub provide_license {
  my ($self, $copyright_holder, $copyright_year) = @_;
  return Software::License::None->new({
    holder => $copyright_holder || 'Vyacheslav Matjukhin',
    year => $copyright_year || 2010,
  });
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
