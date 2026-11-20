require_relative '../test_helper'

class TarifsTest < Minitest::Test

  DATA = {
    prix_ht: 18.86, prix_ttc: 19.9, redevance: 60,
    anciens_tarifs: [{jusqu_au: '19/11/2026', prix_ht: 9.38, prix_ttc: 9.9, redevance: 50}]
  }

  def test_tarif_courant_sans_date
    assert_equal 60, Iced::UDecMois::Tarifs.at(DATA).redevance
  end

  def test_ancien_tarif_jusqu_au_inclus
    assert_equal 50, Iced::UDecMois::Tarifs.at(DATA, '19/11/2026').redevance
    assert_equal 50, Iced::UDecMois::Tarifs.at(DATA, Date.new(2026, 11, 2)).redevance
    assert_equal 60, Iced::UDecMois::Tarifs.at(DATA, Date.new(2026, 11, 20)).redevance
  end

  def test_sans_anciens_tarifs
    assert_equal 9.9, Iced::UDecMois::Tarifs.at({prix_ttc: 9.9}, '01/01/2020').prix_ttc
  end

  def test_kdp_produit_tarif_at
    prod = Iced::UDecMois::KDPProduit.new(DATA.merge(id: 58))
    assert_equal 9.38, prod.tarif_at('01/11/2026').prix_ht
    assert_equal 18.86, prod.tarif_at('25/11/2026').prix_ht
  end

end
