module Iced
module UDecMois
class << self

  def mois_name
    @mois_name ||= begin
      ilya_un_mois = Time.now - 1.mois
      annee = ilya_un_mois.year
      mois  = ilya_un_mois.month.to_s.rjust(2,'0')
      "#{annee}_#{mois}"
    end
  end

  def mois_annee = @mois_annee ||= "#{mois}_#{annee}"
  def annee_mois = @annee_mois ||= "#{annee}_#{mois}"

  def mois  = @mois   ||= mois_name.split('_')[1]
  def annee = @annee  ||= mois_name.split('_')[0]

  # Le dossier des CSV dans le dossier téléchargement
  def downloads_folder = @downloads_folder ||= File.join(Dir.home, 'Downloads', mois_name)

  # Le dossier du mois dans les données des éditions Icare
  def data_folder_mois
    @data_folder_mois ||= begin
      dst_folder = File.join(ALL_DATA_FOLDER, 'kdp')
      File.exist?(dst_folder) || ERR[:fatal, :kdp_folder_in_data_unfound, [dst_folder]]
      File.join(dst_folder, mois_name)
    end
  end

  def folder_rapports
    @folder_rapports ||= File.join(EXPORT_FOLDER,'rapports')
  end

  def €(montant)
    "#{montant.to_f.round(2)} €"
  end

end #/<< self UDecMois

module Edic


##
# Pour traiter tous les mois (ATTENTION !)
# 
def traite_all_ventes_kdp
  puts "

  ATTENTION : cette opération va détruire toutes les ventes KDP
  consignées, pour les rafraichir en repartant des données KDP en
  fichier .csv (rapports KDP).

  ".orange

  Q.no?("Dois-je vraiment procéder à cette opération ?".jaune) || return
  (2021..Time.now.year).each do |annee|
    (1..12).each do |mois|
      # mois_s = mois.to_s.rjust(2,'0')
      folder = File.join(ALL_DATA_FOLDER,'kdp',"#{annee}_#{mois}")
      if File.exist?(folder)
        traite_ventes_kdp_for_mois(annee, mois, **{interactif:false})
      end
    end
  end
end

##
# Pour traiter les données KDP des ventes de façon forcée
# 
def traite_ventes_kdp_for_mois(annee = nil, mois = nil, options = nil)
  annee, mois = ask_for_annee_and_mois(annee, mois)
  traiteur = KDPVenteMoisTreator.new(annee, mois)
  return traiteur.csv_to_edic(options)
end


##
# Pour checker les données actuelles (voir si elles correspondent
# entre les données CSV et les données edic-ventes)
def check_final_data(annee = nil, mois = nil)
  annee, mois = ask_for_annee_and_mois(annee, mois)
  traiteur = KDPVenteMoisTreator.new(annee, mois)
  traiteur.check_final_data
end

def ask_for_annee_and_mois(annee, mois)
  mois  ||= CLI.components[0] || Q.select("Quel mois ?".jaune, CHOICES_MOIS, {per_page:12})
  mois = mois.to_i

  annee ||= CLI.components[1] || Q.select("Quelle année ?".jaune, [2021,2022])
  annee = annee.to_i

  return [annee, mois]  
end



end #/Edic
end #/UDecMois
end #/Iced