require 'csv'
require 'ostruct'

module Iced
module UDecMois
class << self


  ##
  # Affiche les ventes du mois relevées dans le fichier CSV, par
  # ASIN, et ensuite par devise.
  #
  # @return nil en cas de succès ou un hash contenant : 
  # {
  #   cause: :<cause de l'erreur>
  #   data:   {les données à connaitre}
  # }
  def display_ventes_kdp

    puts "*** Check #{mois}/#{annee} ***".bleu
    header1 = "\n  #{' '.ljust(15)} #{' Fichier CSV '.ljust(16)}"
    header2 = "  #{'ISBN/ASIN'.ljust(15)} #{'QT'.ljust(4)} #{'BÉNÉFICE'.ljust(11)} TITRE (#id type)"

    separator = "-" * (header2.length + 50)
    puts header1
    puts header2
    puts separator
    
    # 
    # Boucle sur les instances [LivreCheck] des livres
    # 
    une_erreur = false
    errors_returned = nil
    livres_from_csv.group_by do |livre|
      livre.titre[0..10]
    end.each do |titre, livres|
      livres.each do |livre|
        # --- Ligne d'information ---
        if livre.known?
          puts "  #{livre.asin.ljust(15)} #{livre.quantite.to_s.ljust(4)} #{€(livre.benefice).rjust(8)}   #{livre.titre}"
        else
          une_erreur = true
          errors_returned = OpenStruct.new({cause: :unknown_book, data: []}) if errors_returned.nil?
          errors_returned.data << livre
          puts "  #{livre.asin.ljust(15)} #{livre.quantite.to_s.ljust(4)} #{€(livre.benefice).rjust(8)}   #{livre.titre_par_csv}".rouge
        end
        livre.ventes.group_by do |vente|
          vente.devise
        end.each do |devise, ventes|
          puts "#{' ' * 32}=> Vente : #{ventes.sum { |vente| vente.quantite }} x #{ventes.first.benefice_u } #{devise}"
        end
      end
    end

    puts separator
    puts "\n\n"

    return errors_returned
  end



  # Méthode permettant de corriger les erreurs
  #
  # @return true pour continuer ou false pour s'arrêter
  def traite_erreur_unknown_book(retour)
    puts "\nDes erreurs sont à corriger avant de pouvoir poursuivre.".rouge
    case retour.to_h
    in {cause: :unknown_book} then
      if Q.yes?("Voulez-vous qu'on crée ensemble les fiches des livres manquants ?".jaune)
        clear
        retour.data.each do |livre|
          puts "\n\n\nNous allons traiter le livre d'asin #{livre.asin} ".jaune
          if Q.yes?( "Dois-je l'afficher dans Amazon ?".jaune)
            `open https://www.amazon.fr/s?k=#{livre.asin}`
          end
          clear
          livre_data = {
            id:             new_id_for_book,
            name:           nil,
            type:           'livre',
            stype:          livre.stype_livre,
            lang:           nil,
            redevance:      livre.pourcentage_redevance,
            edic_livree_id: nil,
            taille:         nil,
            date:           nil,
            ean:            livre.asin,
            isbn:           livre.asin,
          }
          while true # jusqu'à ce qu'on soit satisfait
            livre_data.merge!({
              name:           Q.ask("Quel est le titre de ce livre ?".jaune, default: livre_data[:name]),
              edic_livree_id: Q.select("À quelle livrée appartient-il ?".jaune, livrees_pour_ttprompt, default: livre_data[:edic_livree_id]),
              format:         Q.ask("Format du livre (largeur x hauteur unité) : ".jaune, default: livre_data[:format]),
              lang:           Q.select("Langue : ".jaune, ["fr", "us", "de", "it", "es"], default: livre_data[:lang]),
              taille:         Q.ask("Nombre de pages : ".jaune, default: livre_data[:taille]).to_i,
              date:           Q.ask("Date de publication (JJ/MM/AAAA) : ".jaune, default: livre_data[:date])
            })

            # Afficher les données pour les confirmer
            livre_data.each do |k, v|
              puts "#{k.to_s.ljust(15)} #{v.to_s}".bleu
            end
            break if Q.yes?("Ces données sont-elles valides ?".jaune)
          end #/repeat
          # On crée la fiche
          card_path = File.join(PRODUITS_FOLDER, "#{livre_data[:id]}.yaml")
          IO.write(card_path, livre_data.to_yaml)
          IO.write(File.join(PRODUITS_FOLDER,'LASTID'), livre_data[:id].to_s)
          if File.exist?(card_path)
            puts "👌 Carte du livre #{livre_data[:name]} crée avec succès".green
          else
            puts "⚡️ Bizarrement, la carte du livre #{livre_data[:name]} n'a pas pu être traitée…".rouge
          end
        end
      end
    end
    return false # pour le moment
  end

  def livrees_pour_ttprompt
    Dir["#{LIVREES_FOLDER}/*.yaml"].map do |ypath|
      livree = OpenStruct.new(YAML.safe_load(IO.read(ypath), **YAML_OPTIONS))
      { name: livree.name, value: livree.id }
    end << {name: "Aucune", value: nil}
  end

  def new_id_for_book
    last_id_path = File.join(PRODUITS_FOLDER, 'LASTID')
    last_saved = IO.read(last_id_path).to_i
    produit_path = File.join(PRODUITS_FOLDER, "#{last_saved}.yaml")
    produit_path = File.join(PRODUITS_FOLDER, "#{last_saved +=1}.yaml") while File.exist?(produit_path)
    return last_saved
  end



  # @return [Array<LivreCheck>] Liste des livres pas asin unique re-
  # levés dans le fichier ALL.csv
  def livres_from_csv
    @livres_from_csv ||= begin
      CSV.read(csv_path, **{col_sep:';', headers:true}).map do |drow|
        KDPLine.new(drow)
      end.group_by do |row|
        row.asin
      end.map do |asin, rows|
        livre = Edic::LivreCheck.new(asin)
        rows.each { |row| livre << row }
        livre.ventes_edic = ventes_edic_mois.select {|vente| vente.edic_produit_id == livre.produit_id}
        livre
      end
    end    
  end

  def csv_path
    @csv_path ||= begin
      File.join(KDP_FOLDER, mois_name, 'ALL.csv').tap do |pth|
        File.exist?(pth) || raise("Le fichier #{pth.inspect} des ventes KDP est introuvable".rouge)
      end
    end
  end

end #/<< self
end #/UDecMois
end #/Iced
