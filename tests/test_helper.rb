# Helper des tests unitaires de la déclaration mensuelle.
# Aucune donnée réelle n'est lue (constants.rb n'est pas chargé) et
# aucune requête de taux de change n'est faite.
#
# Usage : bundle exec rake test
#
require 'minitest/autorun'
require 'yaml'
require 'csv'
require 'date'
require 'ostruct'

LIB = File.expand_path('../lib', __dir__)
Dir["#{LIB}/xtensions/*.rb"].each { |m| require m }

module Iced
  AMAZON_CLIENT_ID = 18
  module UDecMois
    TAUX_CHANGES = {EUR: 1, USD: 0.9, CAD: 0.6}
  end
end

PROC_FOLDER = File.join(LIB, 'PROCEDURES', 'declaration_mensuelle_impots')
Dir["#{PROC_FOLDER}/tools/*.rb"].each { |m| require m }
require "#{PROC_FOLDER}/3Csv/3-create_ventes_edic"

module IcedTestHelper

  HEADER = ["Date des redevances", "Titre", "Nom de l’auteur", "ASIN/ISBN", "Marché",
    "Type de droits d'auteur", "Type de transaction", "Exemplaires vendus",
    "Exemplaires remboursés", "Nombre net d’exemplaires vendus", "Prix catalogue moyen HT",
    "Prix de vente moyen HT", "Coût moyen de livraison/fabrication", "Redevance", "Devise"]

  # @return [KDPLine] Une ligne de rapport KDP
  def kdp_line(date:, droits:, redevance:, quantite: 1, devise: 'EUR', asin: '9782487613034')
    fr = ->(n) { n.to_s.sub('.', ',') }
    row = CSV::Row.new(HEADER, [date, 'Titre', 'Auteur', asin, 'Amazon.fr', "#{droits}%",
      'Standard – Livre broché', quantite, 0, quantite, '9,38', '9,38', fr.(2.48 * quantite),
      fr.(redevance), devise])
    Iced::UDecMois::KDPLine.new(row)
  end

  # @return [LivreCheck] Un livre (sans lecture des fiches produits)
  # dont la fiche a les données +data_produit+
  def livre_check(lines, data_produit)
    livre = Iced::UDecMois::Edic::LivreCheck.new(lines.first.asin)
    lines.each { |l| livre << l }
    prod = OpenStruct.new({id: 58}.merge(data_produit))
    livre.define_singleton_method(:as_prod) { prod }
    livre
  end

end

# Mois traité : novembre 2026
Iced::UDecMois.instance_variable_set(:@mois_name, '2026_11')
