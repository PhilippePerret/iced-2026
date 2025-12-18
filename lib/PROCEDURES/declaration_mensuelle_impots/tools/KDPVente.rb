# - Class KDPVente -
# Pour les ventes relevées des fiches edic.
# Cette classe permet de checker la validité finale des données 
# créées.
module Iced
module UDecMois
class KDPVente

  attr_reader :data
  def initialize(dvente)
    @data = dvente
  end
  def time
    @time ||= begin 
      jour, mois, annee = date.split('/').map {|n| n.to_i}
      Time.new(annee, mois, jour)
    end
  end

  def date        = data[:date]
  def produit_id  = data[:edic_produit_id]
  def nombre      = data[:nombre]
  def redevance   = data[:redevance]
  # def devise; @devise ||= data[:devise] end
  def cout_u; @cout_u ||= data[:cout] end

  # def benefice
  #   0
  # end
  def mois_annee # p.e. 11_2021
    @mois_annee ||= begin
      dd = date.split('/')[1..2]
      dd[0] = dd[0].to_s.rjust(2,'0')
      dd.join('_')
    end
  end
end #/class KDPVente
end #/UDecMois
end #/Iced