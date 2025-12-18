require 'csv'
require 'ostruct'
module Iced
module UDecMois
class << self

  ##
  # - main -
  # 
  # Méthode qui prend les données KDP du mois dans les fichiers
  # .csv et les transforme en ventes Edic.
  # @return [Boolean] true si l'opération s'est bien déroulée,
  # false otherwise.
  #
  def data_csv_to_data_ventes(options = nil)
    options ||= {}
    options.key?(:interactif) || options.merge!(interactif: true)
    
    #####################################################
    ###      AFFICHAGE DES VENTES AVEC CHIFFRES       ###
    #####################################################
    retour = display_ventes_kdp
    unless retour.nil?
      traite_erreur_unknown_book(retour) || return 
    end

    Q.yes?("OK pour prendre ces données et passer à la suite ?".orange) || return
    clear

    # Destruction des ventes du mois si nécessaire
    # (nécessaire lorsqu'on a joué incomplètement le programme)
    retour = destroy_data_ventes_mois

    ###################################################
    ###    CRÉATION DES VENTES POUR CHAQUE LIVRE    ###
    ###################################################
    if retour == :do_ventes
      create_ventes_edic || return
    end
  end

  # --- Data Methods ---

  # @return [Array<KDPVente>] les Ventes Amazon Edic consignées, sous 
  # forme d'instance KDPVente
  def edic_ventes
    @edic_ventes ||= begin
      Dir["#{VENTES_FOLDER}/*.yaml"].map do |pvente|
        dvente = YAML.safe_load(IO.read(pvente), **YAML_OPTIONS)
        next if not(dvente[:edic_client_id] == AMAZON_CLIENT_ID) # client AMAZON KDP
        UDecMois::KDPVente.new(dvente)
      end.compact.group_by do |vente|
        vente.mois_annee
      end
    end
  end

  
end #/<< self UDecMois

TAUX_CHANGES = begin
    require "#{PROCS_FOLDER}/declaration_mensuelle_impots/tools/taux_change_devises"
    get_changes_for_devises.merge(:EUR => 1)
  end

end #/UDecMois
end #/Iced