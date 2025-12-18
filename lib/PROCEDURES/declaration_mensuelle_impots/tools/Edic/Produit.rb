=begin

Class Edit::Produit
-------------------
Tout ce dont on a besoin concernant les produits dans l'établissement
de la déclaration mensuelle Urssaf.

=end
require 'ostruct'
module Iced
module UDecMois
module Edic
class Produit
  class << self

    def get_by_isbn(asin)
      asin = asin.to_s
      return table_par_asin[asin.to_s] # nil si non défini
    end

    # Table contenant en clé l'asin ou l'isbn du livre et en valeur le livre
    # en tant de produit Icare
    def table_par_asin
      @table_par_asin ||= begin
        tbl = Hash.new
        produits.each do |produit|
          tbl.merge!({
            produit.isbn.to_s => produit,
            produit.asin.to_s => produit,
            produit.isbn.to_s.gsub(/\-/.freeze,'') => produit
          })
        end
        tbl
      end
    end

    def produits
      @produits ||= begin
        Dir["#{folder}/*.yaml"].map do |path|
          OpenStruct.new(YAML.safe_load(IO.read(path), **YAML_OPTIONS))
        end
      end
    end

    def folder = @folder ||= PRODUITS_FOLDER

  end #/<< self

end #/Produit
end #/Edic
end #/UDecMois
end #/Iced