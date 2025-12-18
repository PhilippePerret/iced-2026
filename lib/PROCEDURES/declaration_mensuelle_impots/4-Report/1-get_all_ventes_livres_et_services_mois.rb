require_relative '../tools/usefull_methods'
module Iced
module UDecMois

  NOW         = Time.now
  FROM_DATE   = Time.new(UDecMois.annee, UDecMois.mois, 1, 0,0,0)
  TO_DATE     = Time.new(NOW.year, NOW.month, 1, 0,0,0)

  class << self

# Retourne une table avec toutes les ventes, livres et produits du
# mois précédent.
# {
#   ventes: {...}
#   services: {...}
# }
def get_all_ventes_livres_et_services_mois
  resultat = OpenStruct.new({
    livres:   {},
    services: {},
  })
  nombre_vente_precedentes = 0

  Dir["#{VENTES_FOLDER}/*.yaml"].sort do |a, b|
    # Pour lire les fichiers depuis le dernier, et s'interrompren dès
    # qu'on aura atteint le mois d'avant
    File.basename(a,File.extname(a)).to_i <=> File.basename(b,File.extname(b)).to_i
  end
  .reverse.each_with_index do |pth, idx|
    # Il peut arriver qu'une vente ait été ajoutée entre les deux, 
    # donc on confirme qu'on a bien été jusqu'au bout lorsqu'on a
    # trouvé 10 ventes du mois d'avant
    break if nombre_vente_precedentes > 10
    vente = UDecMois::KDPVente.new(YAML.safe_load(IO.read(pth), **YAML_OPTIONS))

    # On ne doit prendre que les ventes du mois (précédent)
    next if vente.time > TO_DATE
    if vente.time < FROM_DATE
      nombre_vente_precedentes += 1
      next
    end

    # Relever le produit correspond à la vente
    produit = UDecMois::KDPProduit.get(vente.produit_id)

    resultat = 
      if produit.type == 'livre'
        traite_produit_as_livre(resultat, produit, vente)
      else
        traite_produit_as_service(resultat, produit, vente)
      end
  end

  return resultat
end

  def traite_produit_as_livre(res, produit, vente)
    unless res.livres.key?(produit.id)
      res.livres.merge!(produit.id => {
        produit: produit, 
        ventes_distinctes: []
      })
    end
    produit.quantite_totale += vente.nombre
    res.livres[produit.id][:ventes_distinctes] << {quantite: vente.nombre, prix_vente: vente.redevance}
    return res
  end

  def traite_produit_as_service(res, produit, vente)
    unless res.services.key?(produit.id)
      res.services.merge!(produit.id => {
        produit: produit,
        ventes_distinctes: []
      }) 
    end
    produit.quantite_totale += vente.nombre
    res.services[produit.id][:ventes_distinctes] << {quantite: vente.nombre, prix_vente: produit.prix_ht}
    return res
  end

end #/<< self
end #/UDecMois
end #/Iced
