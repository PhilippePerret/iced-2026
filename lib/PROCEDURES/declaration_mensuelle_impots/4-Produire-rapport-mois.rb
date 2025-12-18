=begin

  Une fois qu'on a enregistré les livres comme ventes dans les 
  données des éditions, on peut relever toutes les ventes pour
  faire le rapport du mois.

=end
module Iced
module UDecMois

  MOIS = {
    1 => "Janvier", 2 => "Février", 3 => "Mars", 4 => "Avril", 5 => "Mai", 6 => "Juin", 
    7 => "Juillet", 8 => "Aout", 9 => "Septembre", 10 => "Octobre", 11 => "Novembre",
    12 => "Décembre"
  }
class << self


  ##
  # @api
  #
  # Méthode principale pour produire le rapport qui va donner les
  # renseignement pour l'urssaf
  #
  def produce_report_declaration_urssaf

    #
    # Variables pour mettre les valeurs
    # 

    # 
    # Récupération des ventes de ce mois
    all_ventes = get_all_ventes_livres_et_services_mois

    template_line = '<tr><td>_id_</td><td>_name_</td><td>_tarif_u_</td><td>_quantite_</td><td>_recette_</td></tr>'

    lignes_livres = ''
    total_livres  = 0.0
    all_ventes.livres.values.each do |livre|
      produit = livre[:produit]
      livre[:ventes_distinctes].each do |vente|
        recette = vente[:prix_vente].to_f * vente[:quantite]
        lignes_livres << (template_line.dup
          .sub('_id_', produit.id.to_s)
          .sub('_name_', produit.name)
          .sub('_tarif_u_', €(vente[:prix_vente].to_s))
          .sub('_quantite_', vente[:quantite].to_s)
          .sub('_recette_', €(recette)))
        total_livres += recette
      end
    end

    lignes_services = ''
    total_services = 0.0
    all_ventes.services.values.each do |service|
      produit = service[:produit]
      service[:ventes_distinctes].each do |vente|
        recette = vente[:prix_vente].to_f * vente[:quantite]
        lignes_services << (template_line.dup
          .sub('_id_', produit.id.to_s)
          .sub('_name_', produit.name)
          .sub('_tarif_u_', €(vente[:prix_vente]))
          .sub('_quantite_', vente[:quantite].to_s)
          .sub('_recette_', €(recette)))
        total_services += recette
      end
    end

    # puts "all_ventes".jaune
    # pp all_ventes

    mois_humain   = "#{MOIS[mois.to_i]} #{annee}"
    le_aujourdhui = "le #{Time.new.strftime('%d/%m/%Y')}"
    
    code_html = template.dup

    [
      ['NOMBRE_CELLULES'          , 5],
      ['NOMBRE_CELLULES_MOINS_UN' , 4],
      ['VENTES_LIVRES'            , lignes_livres],
      ['VENTES_SERVICES'          , lignes_services],
      ['TOTAL_TOTAL'              , €(total_livres + total_services)],
      ['TOTAL_LIVRES'             , €(total_livres)],
      ['TOTAL_SERVICES'           , €(total_services)],
      ['<!-- STYLES_CSS -->'      , style_css],
      ['ICARE_SIRET'              , ICARE_SIRET],
      ['ICARE_DESIGNATION'        , ICARE_DESIGNATION],
      ['PERIODE_COUVERTURE'       , mois_humain],
      ['DATE_EMISSION'            , le_aujourdhui],
      ['LIEU_EMISSION'            , "Uchacq et Parentis"]
    ].each do |balise, remplacement|
      code_html.gsub!(balise, remplacement.to_s)
    end
    
    report_name = "bilan-mois-#{annee}-#{mois}.html"
    report_path = File.join(folder_rapports, report_name)
    IO.write(report_path, code_html)

    # Convertir le rapport en PDF
    puts "Production du PDF, merci de patienter…".jaune
    report_path_pdf = pdfize(report_path, false)
    if File.exist?(report_path_pdf)
      # 
      # Le fichier PDF a été produit, on ouvre son dossier pour pouvoir
      # le récupérer
      # 
      File.delete(report_path)
      puts "Ouverture du dossier 'exports' pour récupérer les valeurs du\nrapport #{report_name.inspect} (ne pas le déplacer)".bleu
      sleep 1
      `open -a Finder "#{File.dirname report_path_pdf}"`
      return OpenStruct.new({
        declaration_livres: total_livres.ceil, 
        declaration_services: total_services.ceil
      })
    else
      puts "Bizarrement, le fichier PDF de la facture ne semble pas avoir été produit…".rouge
      return nil
    end
  end #/produce_report_declaration_urssaf


  def style_css
    %Q(<style type="text/css">#{IO.read(File.join(__dir__,'4-Report', 'main.css'))}</style>)
  end

  def template
    IO.read(File.join(__dir__,'4-Report', 'template.htm'))
  end

  def siret_icare
    "SIRET À DÉFINIR"
  end

  # Tranforme le fichier +html_path+ en fichier PDF.
  # Détruit le fichier HTML si +delete_html+ est true.
  # 
  # @return [String] Chemin d'accès au fichier PDF
  #         ou NilClass si le fichier PDF n'a pas pu être produit
  # 
  # @param [String] html_path Chemin d'accès au fichier HTML
  # @param [Boolean] delete_html Si true, détruit le HTML
  def pdfize(html_path, delete_html = false)
    affixe    = File.basename(html_path, File.extname(html_path))
    pdf_path  = File.join(File.dirname(html_path), "#{affixe}.pdf")
    `wkhtmltopdf -O landscape --quiet --enable-local-file-access "#{html_path}" "#{pdf_path}"`
    if File.exist?(pdf_path)  
      return pdf_path
    else
      raise "Un problème est survenu, le fichier #{pdf_path.inspect} n'a pas pu être produit."
    end
  end


end #/<< self
end #/UDecMois
end #/Iced
