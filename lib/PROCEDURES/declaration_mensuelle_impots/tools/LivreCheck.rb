=begin

class LivreCheck
----------------
Pour la gestion des livres (par ASIN) dans la déclaration mensuelle URSSAF

=end
module Iced
module UDecMois
module Edic
class LivreCheck
  attr_reader :asin
  attr_reader :ventes
  attr_accessor :ventes_edic
  def initialize(asin)
    @asin   = asin
    @ventes = []
  end
  # Ajouter une vente relevée dans le fichier CSV
  def << vente
    @ventes << vente
  end
  # Quantité totale vendue de ce livre/ASIN
  def quantite
    @quantite ||= ventes.sum {|v| v.quantite }
  end
  def benefice
    @benefice ||= ventes.sum { |v| v.benefice }
  end
  # --- Edic Infos ---
  def quantite_edic
    ventes_edic.sum { |v| v.quantite }    
  end
  def benefice_edic
    0
  end

  # Return true si le livre est connu (défini dans Icare éditions)
  def known?
    :TRUE == @is_known ||= (as_prod.nil? ? :FALSE : :TRUE)
  end

  # --- Infos Methods ---
  # Identifiant produit de ce livre (fichier DATA/produits)
  def produit_id
    @produit_id ||= known? && as_prod.id
  end

  # Le livre en tant que produit des éditions (Iced/Edic)
  def as_prod
    @as_prod ||= begin
      Edic::Produit.get_by_isbn(asin) || begin
        # Cette erreur survient lorsqu'il s'agit d'un nouveau livre
        # qui n'a pas encore été enregistré comme produit.
        puts <<~TXT.rouge
        Le produit d'asin/isbn/ean #{asin.inspect} 
        est inconnu. Il faut le renseigner dans books.yaml ou dans 
        la fiche du produit (dossier Produits) puis relancer la 
        procédure.
        On peut utiliser la procédure `iced add produit' (normalement…)
        TXT
        nil
      end
    end
  end

  def titre_par_csv
    @titre_par_csv ||= begin
      "#{datarow["Titre"]} (#{datarow["Nom de l’auteur"]})"
    end
  end

  def datarow = @datarow ||= ventes.first.row

  def pourcentage_redevance = @pourcentage_redevance ||= datarow["Type de droits d'auteur"][..2].to_i
  def stype_livre
    @stype_livre ||= begin
      datarow["Type de transaction"].match?(/broché/) ? 'bro' : 'rel'
    end
  end

  def titre
    @titre ||= begin
      if known?
        "#{as_prod.name[0..30]} […] (##{as_prod.id} #{as_prod.stype})"
      else
        "- livre inconnu -"
      end
    end
  end
end #/class LivreCheck
end #/Edic
end #/UDecMois
end #/Iced