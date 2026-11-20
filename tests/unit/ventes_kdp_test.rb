require_relative '../test_helper'

# Création des ventes Edic à partir des lignes du rapport KDP, quand le
# prix et le taux de redevance d'un livre changent dans le mois.
class VentesKDPTest < Minitest::Test
  include IcedTestHelper

  UDM = Iced::UDecMois

  DATA_58 = {
    prix_ht: 18.86, prix_ttc: 19.9, redevance: 60,
    anciens_tarifs: [{jusqu_au: '19/11/2026', prix_ht: 9.38, prix_ttc: 9.9, redevance: 50}]
  }

  def lignes_novembre
    [
      kdp_line(date: '2026-11-28', droits: 60, redevance: 8.84),
      kdp_line(date: '2026-11-25', droits: 60, redevance: 8.84),
      kdp_line(date: '2026-11-22', droits: 60, redevance: 8.84),
      kdp_line(date: '2026-11-12', droits: 50, redevance: 2.21),
      kdp_line(date: '2026-11-05', droits: 50, redevance: 2.21),
    ]
  end

  def test_kdp_line_date
    assert_equal Date.new(2026, 11, 28), lignes_novembre.first.date
  end

  def test_une_vente_par_prix_et_taux
    ventes = UDM.data_ventes_for_livre(livre_check(lignes_novembre, DATA_58))
    assert_equal 2, ventes.count
    v60 = ventes.find { |v| v[:taux_redevance] == 60 }
    v50 = ventes.find { |v| v[:taux_redevance] == 50 }
    assert_equal 3, v60[:nombre]
    assert_equal 8.84, v60[:redevance]
    assert_equal 2, v50[:nombre]
    assert_equal 2.21, v50[:redevance]
    assert_equal '15/11/2026', v60[:date]
    assert_equal 58, v60[:edic_produit_id]
    assert_equal 18, v60[:edic_client_id]
  end

  def test_total_declare_exact
    ventes = UDM.data_ventes_for_livre(livre_check(lignes_novembre, DATA_58))
    total = ventes.sum { |v| v[:nombre] * v[:redevance] }
    assert_in_delta 3 * 8.84 + 2 * 2.21, total, 0.001
  end

  def test_devises_distinctes_et_conversion
    lignes = [
      kdp_line(date: '2026-11-10', droits: 60, redevance: 5.0, devise: 'USD'),
      kdp_line(date: '2026-11-11', droits: 60, redevance: 8.84),
    ]
    ventes = UDM.data_ventes_for_livre(livre_check(lignes, DATA_58))
    usd = ventes.find { |v| v[:devise] == :USD }
    assert_equal 4.5, usd[:redevance] # 5.0 x 0.9
    assert_equal 0.9, usd[:taux_change]
    assert_equal 2, ventes.count
  end

  def test_ligne_a_plusieurs_exemplaires
    lignes = [kdp_line(date: '2026-11-10', droits: 60, redevance: 17.68, quantite: 2),
              kdp_line(date: '2026-11-12', droits: 60, redevance: 8.84)]
    ventes = UDM.data_ventes_for_livre(livre_check(lignes, DATA_58))
    assert_equal 1, ventes.count
    assert_equal 3, ventes.first[:nombre]
    assert_equal 8.84, ventes.first[:redevance]
  end

  def test_redevance_inferieure_a_un_euro_conservee
    lignes = [kdp_line(date: '2026-11-10', droits: 60, redevance: 0.51)]
    ventes = UDM.data_ventes_for_livre(livre_check(lignes, DATA_58))
    assert_equal 1, ventes.count
    assert_equal 0.51, ventes.first[:redevance]
  end

  def test_vente_remboursee_dans_le_mois_ignoree
    lignes = [kdp_line(date: '2026-11-10', droits: 60, redevance: 0, quantite: 0)]
    assert_empty UDM.data_ventes_for_livre(livre_check(lignes, DATA_58))
  end

  # --- Contrôle du taux de redevance ---

  def test_aucun_ecart_quand_l_ancien_tarif_est_consigne
    assert_empty UDM.ecarts_taux_redevance(livre_check(lignes_novembre, DATA_58))
  end

  def test_ecart_quand_l_ancien_tarif_n_est_pas_consigne
    data = DATA_58.reject { |k, _| k == :anciens_tarifs }
    ecarts = UDM.ecarts_taux_redevance(livre_check(lignes_novembre, data))
    assert_equal 2, ecarts.count
    assert(ecarts.all? { |e| e[:rapport] == 50 && e[:fiche] == 60 })
  end

end
