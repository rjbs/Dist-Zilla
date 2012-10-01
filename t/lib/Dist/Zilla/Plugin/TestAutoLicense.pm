package Dist::Zilla::Plugin::TestAutoLicense;

use Moose;
with(
  'Dist::Zilla::Role::LicenseProvider',
);

use Software::License::None;

sub provide_license {
  my ($self, $arg) = @_;
  return Software::License::None->new({
    holder => $arg->{copyright_holder} || 'Vyacheslav Matjukhin',
    year   => $arg->{copyright_year}   || 2010,
  });
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
