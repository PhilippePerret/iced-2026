module Iced
module UDecMois
class << self


  ##
  # Méthode de destruction des ventes éventuelles qui ont été 
  # enregistrées par ce module pour le mois concerné.
  # 
  def destroy_data_ventes_mois
    if data_ventes_mois_registered?
      unless Q.yes?("Les données ventes KDP de ce mois existent déjà. Dois-je les détruire pour les refaire ?".orange)
        return :undo_ventes # pour continuer
      end
      ventes_edic_mois.each do |vente|
        pth = File.join(VENTES_FOLDER, "#{vente.id}.yaml")
        File.delete(pth)
      end
    else
      puts "Aucune vente n'a encore été créée pour ce mois.".bleu
      sleep 1.5
    end
    return :do_ventes
  end

  # --- Helper Methods ---

  # --- Functional Methods ---

  def ventes_edic_mois
    @ventes_edic_mois ||= edic_ventes[mois_annee] || []
  end

  def data_ventes_mois_registered?
    ventes_edic_mois.count > 0
  end



end #/<< self
end #/UDecMois
end #/Iced