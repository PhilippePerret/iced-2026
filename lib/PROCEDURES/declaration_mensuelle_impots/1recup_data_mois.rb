module Iced
module UDecMois
class << self

  ##
  # Conversion du fichier rapport KDP (xlsx) en fichier .csv séparés
  # 
  # @fin
  #   À la fin de cette opération, il doit exister dans le dossier
  #   "téléchargements" un dossier portant le nom du mois, qui contient
  #   tous les fichiers csv des ventes du mois, avec leur nom original
  # 
  def open_report_in_number_and_convert

    return puts("je ne le fais pas, pour l'essai")

    # 
    # Trouver le dossier KDP dans le dossier des téléchargements
    # 
    files = Dir["#{File.join(Dir.home)}/Downloads/*.xlsx"].select do |pth|
      pth.match?(/KDP/)
    end

    #
    # Erreur quand aucun dossier n'est trouvé
    # 
    files.count > 0 || ERR[:fatal, :rapport_kdp_unfound]
    files.count == 1 || ERR[:fatal, :too_much_kdp_report]
    suivi "Rapport mensuel KDP trouvé."

    xls_file = files.first

    # Ouvrir le fichier dans Numbers
    `open -a Numbers "#{xls_file}"`

    begin
      n = 0
      while n == 0
        res = `osascript -e 'tell application "Numbers" to return (count of documents)'`
        n = res.strip.to_i
        sleep 0.2
      end
    rescue Exception => e
      ERR[:fatal, :numbers_count_docs_error]
    end

    #
    # Exporter dans un dossier du nom du mois
    # 
    export_from_numbers_with_name(mois_name)

    suivi "Fichiers CSV créés dans le dossier “#{UDecMois.mois_name}” du dossier téléchargement."

  end

  def export_from_numbers_with_name(folder_name)
  res = `osascript -e '
    tell application "Finder" to set dossier to ((path to home folder) & "Downloads:#{folder_name}") as string
    tell application "Numbers" to export (front document) to (file dossier) as CSV with properties {exclude summary worksheet:true, include comments:false}
    tell application "Numbers" to quit'`

  return res.strip
end
end #/ << self
end #/ UDecMois
end #/ Iced