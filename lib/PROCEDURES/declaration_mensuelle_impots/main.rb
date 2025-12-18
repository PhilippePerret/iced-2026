module Iced
class Ope

  ONLY_RANGEMENT = false # true # pour développement

  DATA = {}

  def run
    clear
    require_folder('PROCEDURES/declaration_mensuelle_impots/tools')
    puts "Nous allons procéder à la déclaration mensuelle des impôts.".jaune
    
    # Récupérer le rapport du mois sur Amazon KDP
    unless ONLY_RANGEMENT
      skipit = if File.exist?(UDecMois.downloads_folder) || File.exist?(UDecMois.data_folder_mois)
        !Q.yes?("Faut-il récupérer les fichiers CSV du rapport KPD des ventes du mois ? (je demande car un dossier “#{UDecMois.mois_name}” existe déjà…)".orange)
      else false end
      skipit || UDecMois.open_report_in_number_and_convert
      File.exist?(UDecMois.downloads_folder) || \
        File.exist?(UDecMois.data_folder_mois) || \
        ERR[:fatal, :downloads_folder_unfound, UDecMois.downloads_folder]

      # Préparer les fichiers CSV et les placer dans le dossier des données
      # des éditions Icare
      skipit = if File.exist?(UDecMois.data_folder_mois)
        !Q.yes?("Faut-il refaire le dossier “#{UDecMois.mois_name}” dans les data des éditions Icare ?(je demande car il existe déjà)".orange)
      else false end
      skipit || UDecMois.change_name_and_location_csv_files
      File.exist?(UDecMois.data_folder_mois) || ERR[:fatal, :data_csv_folder_unfound_in_data, UDecMois.mois_name]


      # On transforme les données CSV en ventes pour les éditions
      skipit = if UDecMois.data_ventes_mois_registered?
        !Q.yes?("Faut-il refaire les données ventes du mois ? (je demande car elles existent déjà)".orange)
      else false end
      skipit || UDecMois.data_csv_to_data_ventes

      #############################################
      ###     RAPPORT DE DÉCLARATION URSSAF     ###
      #############################################
      retour = UDecMois.produce_report_declaration_urssaf || return

      # Affichage des valeurs à déclarer
      puts <<~TEXT.bleu
      Les valeurs à déclarer à l'URSSAF sont :
        Livres (biens) : #{retour.declaration_livres.to_s.rjust(6)} €
        Services       : #{retour.declaration_services.to_s.rjust(6)} €

      TEXT
      sleep 2

      ########################################
      ###      DÉCLARATION À L'URSSAF      ###
      ########################################
      if Q.yes?("Rejoignons nous le site de l'URSSAF pour déclarer ces recettes ?".orange)
        `open -a Safari https://www.autoentrepreneur.urssaf.fr/portail/accueil.html`
      end

    end #/ONLY_RANGEMENT

    #####################################
    ###    RANGEMENT DES ÉLÉMENTS     ###
    #####################################
    while true
      if Q.yes?("Avez-vous bien téléchargé le justificatif de l'URSSAF ? (si ce n'est pas le cas, téléchargez-le avant de cliquer OK)".orange)
        break if UDecMois.range_tous_les_elements
      end
    end

    clear
    puts "\n\n🥳 Nous en avons terminé avec la déclaration du mois !".green

  end

end #/Ope
end #/Iced