# - Class KDPProduit -
# Pour les ventes relevées des fiches edic.
# Cette classe permet de checker la validité finale des données 
# créées.
module Iced
module UDecMois
class KDPProduit

  # Pour mettre le nombre totale de ventes
  attr_accessor :quantite_totale

  class << self
    # @return [KDPProduit] L'instance produit du produit
    def get(id)
      @table ||= {}
      @table[id] ||= begin
        path_produit = File.join(PRODUITS_FOLDER, "#{id}.yaml")
        new(YAML.safe_load(IO.read(path_produit), **YAML_OPTIONS))
      end
    end

  end #/<< self KDPProduit

  attr_reader :data

  def initialize(data)
    @data = data
    self.quantite_totale = 0
  end

  def id      = data[:id]
  def type    = data[:type]
  def prix_ht = data[:prix_ht]
  def name    = data[:name] || data[:titre]

end #/ KDPProduit
end #/UDecMois
end #/Iced
