module Iced
module UDecMois
class << self



  ##
  # Méthode de création des instances de [Edic::Vente] à partir des
  # données du fichier ALL.csv
  # 
  def create_ventes_edic
    liste_data_ventes = []
    ecarts = []
    livres_from_csv.each do |livre|
      ecarts += ecarts_taux_redevance(livre)
      liste_data_ventes += data_ventes_for_livre(livre)
    end

    # Taux de redevance du rapport différent de celui de la fiche
    # produit (à la date de la vente)
    unless ecarts.empty?
      puts "\nTaux de redevance du rapport KDP différents de ceux des fiches produits :".rouge
      ecarts.each do |ecart|
        puts "  ##{ecart[:produit_id]} #{ecart[:date].strftime('%d/%m/%Y')} : rapport #{ecart[:rapport]} % / fiche #{ecart[:fiche].inspect} %".rouge
      end
      puts <<~TXT.orange
        (Les montants enregistrés sont ceux du rapport KDP. Si un tarif a
        changé, l'ancien doit être consigné dans :anciens_tarifs de la
        fiche produit.)
      TXT
      Q.yes?("Poursuivre malgré tout ?".jaune) || return
    end

    # Affichage des données qui vont être enregistrées (pour validation)
    header = false
    legend = ""
    liste_data_ventes.each do |dvente|
      unless header
        header = ""
        dvente.keys.each_with_index do |k, i|
          len = k == :date ? 12 : 7
          header += "#{i.to_s.ljust(len)} "
          legend += "#{i}: #{k}, "
        end
        puts header
        puts "-" * header.length
      end
      puts (dvente.map do |k, v|
        length = k == :date ? 12 : 7
        "#{v.to_s.ljust(length)}"
      end).join(' ')
    end
    puts "\n#{legend}".gris
    Q.yes?("\nEs-tu d'accord avec ces données ?".jaune) || return

    puts "Enregistrement des ventes…".bleu
    # Le dernier pour l'essai est le #792
    vente_id = get_next_vente_id - 1
    liste_data_ventes.each do |data_vente|
      vente_id += 1
      card_vente_path = File.join(VENTES_FOLDER, "#{vente_id}.yaml")
      data_vente.merge!(id: vente_id)
      IO.write(card_vente_path, data_vente.to_yaml)
    end
    # Enregistrement du LASTID
    IO.write(last_id_path, vente_id.to_s)
    puts "👌 Ventes enregistrées (#{liste_data_ventes.count})".vert

    return true
  end

  # @return [Array<Hash>] Les données des ventes Edic à créer pour le
  # livre +livre+ (LivreCheck). Les lignes du CSV sont regroupées par
  # devise, taux de redevance et redevance unitaire, pour qu'un
  # changement de prix ou de taux dans le mois produise des ventes
  # distinctes.
  def data_ventes_for_livre(livre)
    livre.ventes.group_by { |line| line.cle_vente }.map do |(devise, droits, _red_u), lines|
      quantite = lines.sum { |line| line.quantite }
      next if quantite == 0 # p.e. vente remboursée dans le mois
      benefice_u = (lines.sum { |line| line.benefice } / quantite).round(2)
      next if benefice_u.nan? || benefice_u.zero?
      data_vente = {
        edic_client_id:   AMAZON_CLIENT_ID,
        edic_produit_id:  livre.produit_id,
        nombre:           quantite,
        taux_redevance:   droits,
        redevance:        benefice_u,
        cout:             lines.first.cout_u,
        devise:           devise,
        date:             "15/#{mois}/#{annee}",
        taux_change:      nil,
        id:               nil, # cf. plus bas
      }
      data_vente.merge!(taux_change: TAUX_CHANGES[devise]) if devise != 'EUR' # (toujours vrai, devise est un Symbol : comportement d'origine conservé)
      data_vente
    end.compact
  end

  # @return [Array<Hash>] Liste des lignes du CSV du livre +livre+ dont
  # le taux de redevance diffère de celui de la fiche produit à la date
  # de la vente.
  def ecarts_taux_redevance(livre)
    livre.ventes.map do |line|
      fiche = Tarifs.at(livre.as_prod.to_h, line.date).redevance
      next if fiche.to_i == line.droits
      {produit_id: livre.produit_id, date: line.date, rapport: line.droits, fiche: fiche}
    end.compact.uniq { |e| [e[:date], e[:rapport]] }
  end

  def get_next_vente_id
    new_id = IO.read(last_id_path).strip.to_i
    new_id += 1 while File.exist?(File.join(VENTES_FOLDER, "#{new_id}.yaml"))
    return new_id
  end

  def last_id_path = @last_id_path ||= File.join(VENTES_FOLDER, 'LASTID')

end #/<< self
end #/UDecMois
end #/Iced
