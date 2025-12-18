module Iced
module UDecMois
class << self


  def range_tous_les_elements

    # On doit trouver le justificatif de l'URSSAF
    justificatif_urssaf = get_justificatif_urssaf || raise("Impossible de trouver le justification URSSAF")

    report_path = File.join(EXPORT_FOLDER, 'rapports', "bilan-mois-#{annee}-#{mois}.pdf")
    File.exist?(report_path) || raise("Le fichier #{report_path.inspect} est introuvable…")

    # Dossier cotisations
    cotisation_folder = File.join(ALL_DATA_FOLDER,'Cotisations',"#{annee}-#{mois}")
    not(File.exist?(cotisation_folder)) || raise("Le dossier des cotisations pour le mois #{mois} de l'année #{annee} ne devrait pas exister…")
    FileUtils.mkdir_p(cotisation_folder)

    # 
    # Déplacement du rapport PDF
    # 
    report_final = File.join(cotisation_folder, File.basename(report_path))
    declar_final = File.join(cotisation_folder, 'justificatif_urssaf.pdf')
    FileUtils.move(report_path, report_final)
    FileUtils.move(justificatif_urssaf, declar_final)

  rescue => e
    puts e.message.rouge
    return false
  else 
    true
  end #/range_tous_les_elements


  private def get_justificatif_urssaf
    allfiles = Dir["#{Dir.home}/Downloads/*.pdf"]
    justif_path = Dir["#{Dir.home}/Downloads/*.pdf"].sort do |a,b|
      File.stat(a).mtime <=> File.stat(b).mtime
    end.select do |pth|
      thename = File.basename(pth)
      # Je ne comprends pas pourquoi ça foire avec /déclaration/i (peut
      # être à cause du "é" en UTF-8)
      thename.match?(/Déclaration/) || thename.match?(/déclaration/i) || thename.match?(/download_me/)
    end.last
  end #/ get_justificatif_urssaf

end #/<< self
end #/UDecMois
end #/Iced