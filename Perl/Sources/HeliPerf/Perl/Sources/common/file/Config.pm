package file::Config;

use strict;
use LoadDat;

=pod
Charge le fichier de configuration contenant la liste des h�licos et le mot de passe
renvoie un tableau de {nom => nom de l'h�lico, dossier => r�pertoire de l'h�lico} avec le mot de passe coupl�,

load($filename) : $filename nom du fichier � lire
=cut

#Num�ro de la section helicos apparaissant dans le fichier config.dat
use constant SECTION_TYPEHELICOS => 0;
use constant SECTION_HELICOS => 1;
use constant SECTION_MOTDEPASSE => 2;

use constant COL_DOSSIER  => 1;
use constant COL_TYPE     => 0;
use constant COL_NOM      => 0;


#ca me parait clair
#renvoie undef si erreur
sub load {
  my ($base_filename) = @_;
  my $base = LoadDat::load($base_filename);

  if (!$base) {
    GenericWin::erreur_msg("Impossible de charger le fichier de configuration $base_filename : ".LoadDat::get_erreur);
    return undef;
  }

  #R�cuperation de la liste des types d'h�licos
  my $obj = $base->[SECTION_TYPEHELICOS];
  my @tab_typeheli = ();
  foreach my $ligne (@{$obj->{contenu}}) {
    push @tab_typeheli, {type => $ligne->[COL_TYPE], dossier => $ligne->[COL_DOSSIER]};
  }

  #R�cup�ration de la liste des h�licos
  $obj = $base->[SECTION_HELICOS];
  my @tab_heli = ();
  foreach my $ligne (@{$obj->{contenu}}) {
    push @tab_heli, { nom => $ligne->[COL_NOM], dossiertype => $ligne->[COL_DOSSIER] };
  }

  # if (!$base) {
    # GenericWin::erreur_msg("Impossible de charger le fichier de configuration $base_filename : ".LoadDat::get_erreur);
    # return undef;
  # }

  #R�cup�ration des mots de passe
  #Premi�re ligne, premier �l�ment
  my $mdpadmin = $base->[SECTION_MOTDEPASSE]->{contenu}->[0][0] ;
  my $mdpsuperadmin = $base->[SECTION_MOTDEPASSE]->{contenu}->[1][0];
  ############################################################################################
  #dev echanger les 2 premiers parametres -> fait                                            #
  ############################################################################################
  return (\@tab_heli,\@tab_typeheli, $mdpadmin, $mdpsuperadmin);
}

1;
