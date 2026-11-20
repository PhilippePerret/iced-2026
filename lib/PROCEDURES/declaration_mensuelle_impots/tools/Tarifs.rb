=begin

  Module Iced::UDecMois::Tarifs
  ------------------------------
  Gestion de l'historique des tarifs d'un produit.

  Les valeurs :prix_ht, :prix_ttc et :redevance de la fiche du produit
  sont toujours les valeurs COURANTES. Quand un tarif change, on
  consigne l'ancien dans la liste :anciens_tarifs de la fiche, avec la
  date (incluse) jusqu'à laquelle il s'est appliqué :

    :anciens_tarifs:
    - :jusqu_au: 19/11/2026
      :prix_ht: 9.38
      :prix_ttc: 9.9
      :redevance: 50

  Une valeur absente d'un ancien tarif est prise dans le tarif
  courant.

  @note
    Ce module est dupliqué (à l'identique) dans edic
    (lib/classes/tarifs.rb). Toute modification doit être reportée.

=end
require 'date'
module Iced
module UDecMois
module Tarifs

  Tarif = Struct.new(:prix_ht, :prix_ttc, :redevance, keyword_init: true)

  PROPS = [:prix_ht, :prix_ttc, :redevance].freeze

  class << self

    # @return [Tarif] Le tarif qui s'appliquait à la date +date+ pour
    # le produit de données +data+. Le tarif courant si +date+ est nil
    # ou postérieure à tous les anciens tarifs.
    #
    # @param [Hash] data Les données de la fiche produit
    # @param [String|Date|Time|NilClass] date "JJ/MM/AAAA", Date ou Time
    def at(data, date = nil)
      ancien = date.nil? ? nil : ancien_tarif_at(data, to_date(date))
      Tarif.new(**PROPS.to_h { |p| [p, (ancien&.key?(p) ? ancien : data)[p]] })
    end

    # @return [Date|NilClass] Date de début du tarif courant (le
    # lendemain du dernier ancien tarif) ou nil s'il n'y a pas
    # d'ancien tarif.
    def debut_tarif_courant(data)
      periode_at(data, nil)[0]
    end

    # @return [Array<Date|NilClass>] [début, fin] (inclus) de la
    # période du tarif qui s'appliquait à +date+ (tarif courant si
    # +date+ est nil). nil = sans limite.
    def periode_at(data, date)
      fins = anciens_tarifs(data).map { |t| to_date(t[:jusqu_au]) }
      jour = date.nil? ? nil : to_date(date)
      fin  = jour && fins.find { |f| jour <= f }
      prec = fin ? fins.select { |f| f < fin }.last : fins.last
      [prec && (prec + 1), fin]
    end

    def anciens_tarifs(data)
      (data[:anciens_tarifs] || []).sort_by { |t| to_date(t[:jusqu_au]) }
    end

    def to_date(date)
      case date
      when Date then date.to_date
      when Time then date.to_date
      when String
        jour, mois, annee = date.split('/').map(&:to_i)
        Date.new(annee, mois, jour)
      else raise ArgumentError, "Date de tarif invalide : #{date.inspect}"
      end
    end

    private

    def ancien_tarif_at(data, jour)
      anciens_tarifs(data).find { |t| jour <= to_date(t[:jusqu_au]) }
    end

  end #/<< self
end #/Tarifs
end #/UDecMois
end #/Iced
