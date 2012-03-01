package mainWin::widgets::Onglets;
=pod
Ce module cr�e les onglets de matos �quippable.

init($notebook) : � l'issue, le module travaillera sur le GtkNoteBook donn� en param�tre
new($base) : Cr�e les onglets correspondant � la base de donn�es $base (cf plus bas) 
=cut

use strict;

use common::widgets::Onglets;
use constant ONGLET_PROFIL_TITLE => 'Profils';

my $wOnglets;

sub init {
	$wOnglets = common::widgets::Onglets->new(shift);
}

sub new {
	my ($categories, $profils) = @_;
	my @tab_items = ();

	my $store_func = sub {
		my $cItem = shift;
		@tab_items[$cItem->get_model->get_id] = $cItem;
	};

	map { map { $store_func->($_)  } @{$_->get_items} } @$categories;

	$wOnglets->set_categories($categories);

	my @profil_buttons = ();
	foreach my $profil (@$profils) {
		my ($lbl, $tooltip) = common::widgets::Onglets::get_suppl_tooltip($profil->get_nom);

		my $button = Gtk2::Button->new($lbl);
		$button->set_tooltip_text($tooltip);

		my $on_clicked = sub {
			foreach my $id (@{$profil->get_ids}) {
				$tab_items[$id]->activate_Onglets();
			}
		};
		
		$button->signal_connect(clicked => $on_clicked);
		push @profil_buttons, $button;
	}

	$wOnglets->append_buttons_page(\@profil_buttons, ONGLET_PROFIL_TITLE);

}


1;
__END__

use constant NB_COL => 3;
use constant NB_LIG => 4;

use Gtk2;
use Glib;

#si les boutons ne remplissent pas tout l'espace s'il n'y en a moins que le max
use constant HOMOGENE => Glib::TRUE;
#Nombre de caract�res
use constant TAILLE_MAX => 20;

my $notebook;

=pod
Cette fonction est appel�e par InterfaceController::init
=cut
sub init {
	$notebook = shift;
}

=pod
Pour cr�er les onglets, new attends en param�tre une r�f�rence vers un tableau d'objets cat�gorie pr�sentant les m�thodes
$cat->titre : titre de la cat�gorie (nom de l'onglet)
$cat->get_items : tableau des diff�rents objets item

La classe item doit impl�menter les m�thodes
$item->get_nom
$item->get_masse
$item->get_bras
$item->on_Onglets_button_activate : cette m�thode est appel�e quand le bouton est activ�
$item->on_Onglets_button_desactivate	: cette m�thode est appel� quand le bouton est d�sactiv�

Ces deux m�thodes suivantes ne sont pas encore impl�ment�s. Peut-�tre un beau jour..
$item->set_activate_button_func ($func) : permet au controller d'appeler la fonction $func pour simuler l'action de l'utilisateur de l'activation du bouton.
$item->set_desactivate_button_func ($func) : permet au controller d'appeler la fonction $func pour simuler l'action
	de l'utilisateur de la d�sactivation du bouton (si l'utilisateur supprime dans la ListeMatos).
=cut

sub new {
	my ($base, $profils) = @_;
	my @tab_items = ();
	
	#Suppression des onglets d�j� pr�sents s'il y en a
	my $n = $notebook->get_n_pages;
	for (my $j = 0; $j < $n; $j++) {
		$notebook->remove_page(-1);
	}
	
	foreach my $obj (@$base) {
		my $items = $obj->get_items;
		
		#calcul du nombre de ligne, connaissant le nombre total � placer
		my $nbligne = int($#$items / NB_COL) + 1;
		#on prend minium NB_LIG quand m�me
		if ($nbligne < NB_LIG) { $nbligne = NB_LIG; }
		
		#Pour bien aligner les boutons
		my $table =	Gtk2::Table->new ($nbligne, NB_COL, HOMOGENE);
		#Pour mettre des barres d�filantes
		my $scrolledwindow = Gtk2::ScrolledWindow->new;
		$scrolledwindow->add_with_viewport($table);
		#On affiche que la barre verticale, si n�cessaire
		$scrolledwindow->set_policy ('never', 'automatic');
		
		$notebook->append_page ($scrolledwindow, $obj->get_nom);
		
		#initialisation de la position courante dans le GtkTable.
		my @idx = _init_idx();
		
		foreach my $item (@$items) {
			my $item2 = $item->get_model;
			my $nom	 = $item2->get_nom;
			my $masse = $item2->get_masse;
			my $bras = $item2->get_bras ;

			

		
			my $button = Gtk2::ToggleButton->new($nom);
			$tab_items[$item2->get_id()] = $button;

			#R�cup�ration du GtkLabel
			my $label = $button->child;
			
			#info suppl�mentaire � afficher dans l'infobulle
			my $info = '';
			#nom du	bouton
			my $lblname = $nom;
			
			#Si �a d�passe la taille maximale autoris�
			if (length($lblname) > TAILLE_MAX) {
				#le nom en entier n'est pas affich�
				$lblname = substr($lblname,0,TAILLE_MAX - 3).'...';
				#du coup le nom est affich� dans l'infobulle
				$info = "$nom\n";
			}
			
			#lib�ll� du bouton : $lblname
			$label ->set_text($lblname);
			#texte de l'info bulle
			$button->set_tooltip_text("${info}Masse : $masse\nBras : $bras");

			my $update_func = sub {
				my $masse = $item2->get_masse;
				#du fait du drag & drop, il peut y avoir nombre de chiffre
				my $bras = int($item2->get_bras);
				$button->set_tooltip_text("${info}Masse : $masse\nBras : $bras");
			};

			$item->set_update_Onglets_func ($update_func);
			
			#Callback pour pr�venir l'item qu'on a activ� ou d�sactiv� le bouton
			my $on_toggled = sub {
				if (shift->get_active) {
					$item->on_Onglets_button_activate;
				}
				else {
					$item->on_Onglets_button_desactivate;
				}
			};
			
			$button->signal_connect(toggled => $on_toggled);
			
			#Le bouton est ajout� au GtkTable � la position @idx
			$table->attach_defaults( $button, @idx);
			#On incr�mente l'index
			@idx = _incr_idx(@idx);
		}
		$scrolledwindow->show_all();
	}

	###########################
	#Occupation du profil
	############################

	#calcul du nombre de ligne, connaissant le nombre total � placer
	my $nbligne = int($#$profils / NB_COL) + 1;
	#on prend minium NB_LIG quand m�me
	if ($nbligne < NB_LIG) { $nbligne = NB_LIG; }
	
	#Pour bien aligner les boutons
	my $table = Gtk2::Table->new ($nbligne, NB_COL, HOMOGENE);
	#Pour mettre des barres d�filantes
	my $scrolledwindow = Gtk2::ScrolledWindow->new;
	$scrolledwindow->add_with_viewport($table);
	#On affiche que la barre verticale, si n�cessaire
	$scrolledwindow->set_policy ('never', 'automatic');
	
	$notebook->append_page ($scrolledwindow, ONGLET_PROFIL_TITLE);
	
	#initialisation de la position courante dans le GtkTable.
	my @idx = _init_idx();
	foreach my $profil (@$profils) {
		my $nom = $profil->get_nom();
		my $button = Gtk2::Button->new($nom);

		#R�cup�ration du GtkLabel
		my $label = $button->child;
		
		#info suppl�mentaire � afficher dans l'infobulle
		my $info = '';
		#nom du	bouton
		my $lblname = $nom;
		
		#Si �a d�passe la taille maximale autoris�
		if (length($lblname) > TAILLE_MAX) {
			#le nom en entier n'est pas affich�
			$lblname = substr($lblname,0,TAILLE_MAX - 3).'...';
			#du coup le nom est affich� dans l'infobulle
			$info = "$nom\n";
		}
		
		#lib�ll� du bouton : $lblname
		$label ->set_text($lblname);
		
		#Callback pour pr�venir l'item qu'on a activ� ou d�sactiv� le bouton
		my $on_clicked = sub {
			foreach my $id (@{$profil->get_ids}) {
				my $button = $tab_items[$id];
				if ($button) {
					$button->set_active(Glib::TRUE);
				}
				else {
					print "$id\n";
				}
			}
		};
		
		$button->signal_connect(clicked => $on_clicked);
		
		#Le bouton est ajout� au GtkTable � la position @idx
		$table->attach_defaults( $button, @idx);
		#On incr�mente l'index
		@idx = _incr_idx(@idx);
	}

	$scrolledwindow->show_all();
	
}

=pod
Fonctions utiles pour savoir o� cr�er le bouton dans le GtkTable
=cut
sub _init_idx {
	return (0,1,0,1);
}
sub _incr_idx {
	my ($l,$r,$t,$b) = @_;
	$l++;
	if ($l == NB_COL) {
		$t++; $l = 0;
	}
	return ($l,$l+1,$t,$t+1);
}
1;
