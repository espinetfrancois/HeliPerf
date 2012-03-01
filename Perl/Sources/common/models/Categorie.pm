package models::Categorie;

=pod
****CLASSE Categorie*****

Repr�sente une cat�gorie de mat�riel (qui donnera lieu � un onglet)
=cut

use strict;

sub new {
  my ($class, $titre, $tabl) = @_;
  my $this = {_TITRE => $titre, _ITEMS => $tabl};
  return bless ($this, $class);
}

sub get_nom {
  return shift->{_TITRE};
}

#renvoie la liste des $items relevant de cette cat�gorie
sub get_items {
  return shift->{_ITEMS};
}

1;
