module Iced
module UDecMois
class << self



  ##
  # Méthode de création des instances de [Edic::Vente] à partir des
  # données du fichier ALL.csv
  # 
  def create_ventes_edic
    liste_data_ventes = []
    livres_from_csv.each do |livre|
      livre.ventes.group_by do |vente|
        vente.devise
      end.each do |devise, ventes|
        # ventes = Array de Edic::Command::KDPLine
        # puts "#{' ' * 32}=> Vente : #{ventes.sum { |vente| vente.quantite }} x #{ventes.first.benefice_u } #{devise}"
        quantite = ventes.sum { |vente| vente.quantite }
        taux_redev = ventes.first.droits
        if taux_redev != livre.as_prod.redevance
          msg = "
          Bizarrement, le taux de redevance (% droits) dans le 
          rapport (#{taux_redev} %) ne correspond pas aux droits
          obtenus par livre.as_prod.redevance (#{livre.as_prod.redevance})
          livre.as_prod = #{livre.as_prod.inspect}
          livre.as_prod.data = #{livre.as_prod.inspect}
          ".rouge
          puts msg
          exit
        end
        data_vente = {
          edic_client_id:   AMAZON_CLIENT_ID,
          edic_produit_id:  livre.produit_id,
          nombre:           quantite,
          taux_redevance:   taux_redev,
          redevance:        ventes.first.benefice_u,
          cout:             ventes.first.cout_u,
          devise:           devise,
          date:             "15/#{mois}/#{annee}",
          taux_change:      nil, # cf. ci-dessous
          id:               nil, # cf. plus bas
        }

        # Quand remboursement par exemple
        rede = data_vente[:redevance]
        next if (rede.is_a?(Float) && rede.nan?) || rede.to_i == 0

        if devise != 'EUR'
          data_vente.merge!(taux_change: TAUX_CHANGES[devise])
        end
        liste_data_ventes << data_vente
      end
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

  def get_next_vente_id
    new_id = IO.read(last_id_path).strip.to_i
    new_id += 1 while File.exist?(File.join(VENTES_FOLDER, "#{new_id}.yaml"))
    return new_id
  end

  def last_id_path = @last_id_path ||= File.join(VENTES_FOLDER, 'LASTID')

end #/<< self
end #/UDecMois
end #/Iced
