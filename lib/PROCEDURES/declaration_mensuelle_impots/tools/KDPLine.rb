=begin
- Classe KDPLine -
Pour gérer UNE LIGNE RELEVÉE DANS LE FICHIER CSV du mois
Cette ligne correspond la vente de PLUSIEURS exemplaires d'un 
livre en particulier.
=end
module Iced
module UDecMois
class KDPLine
  attr_reader :row
  def initialize(dline)
    @row = dline
  end
  def asin; @asin ||= row[3] end
  def quantite; @quantite ||= row[9].to_i end
  def cout_u
    @cout_u ||= begin
      ((row[12].sub(/,/,'.').to_f * TAUX_CHANGES[devise]) / quantite).round(3)
    end
  end
  # Redevance totale
  def redevance
    @redevance ||= row[13].sub(/,/,'.').to_f 
  end
  # Redevance unitaire
  def redevance_u
    (redevance / quantite).round(2)
  end
  def benefice 
    (redevance * TAUX_CHANGES[devise]).round(2)
  end
  # Le bénéfice unitaire, en fonction de la devise et du nombre de
  # ventes. C'est la donnée qui sera utilisée pour la vente
  def benefice_u 
    ( (redevance * TAUX_CHANGES[devise]) / quantite ).round(2)
  end
  def devise
    @devise ||= begin
      row[14].to_sym.tap do |dev|
        TAUX_CHANGES.keys.include?(dev) || begin
          raise <<~TXT
          La devise #{dev.inspect} est inconnue… Les colonnes KDP ont peut-être changé…
          Si c'est une devise existante, il faut l'ajouter dans le fichier 
          lib/modules/taux_change_devises.rb dans la constantes DEVISES et
          détruire le fichier pour l'actualiser.

          TAUX_CHANGES = #{TAUX_CHANGES.inspect}
          TXT
        end
      end
    end
  end
  def droits # p.e. 60 pour '60%'
    @droits ||= row[5].sub(/%/,'').strip.to_i
  end
end #/class KDPLine

end #/UDecMois
end #/Iced