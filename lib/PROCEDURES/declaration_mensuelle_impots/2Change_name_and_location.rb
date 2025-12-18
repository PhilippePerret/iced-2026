require 'fileutils'
module Iced
module UDecMois
class << self

  ##
  # Méthode qui change le nom des fichiers CSV dans le dossier du mois,
  # qui vérifie qu'ils existent bien tous,
  # puis les déplace au bon endroit.
  # 
  # @fin
  #   À la fin de cette opération, les fichiers inutiles ont été 
  #   détruits, les fichiers utiles ont été renommés et le dossier 
  #   de mois a été déplacé dans le dossier "kdp" des données totales
  # 
  def change_name_and_location_csv_files(annee = nil, mois = nil)

    # 
    # On renomme les fichiers (et on détruit ceux qui ne servent à
    # rien)
    # 
    Dir["#{downloads_folder}/*.csv"].each do |pth|
      nom = File.basename(pth).to_s.force_encoding('utf-8')
      new_name = 
        if nom.match?(/KENP/)                         then "KENP"
        elsif nom.match?(/Redevances(.+)livres bro/)  then "Bro"
        elsif nom.match?(/Redevances(.+)livres rel/)  then "Rel"
        elsif nom.match?(/Redevances(.+)ebooks/)      then "Num"
        elsif nom.match?(/Ventes cumulées/)           then "ALL"
        else 
          File.delete(pth)
          next
        end
      new_path = File.join(downloads_folder, "#{new_name}.csv")
      FileUtils.mv(pth, new_path)
    end
    #
    # On doit avoir le bon nombre de fichiers
    # 
    csv_count = Dir["#{downloads_folder}/*.csv"].count
    csv_count == 5 || ERR[:fatal, :bad_number_csv_files_count, [csv_count]]

    # On déplace ce dossier au bon endroit
    dst_folder = File.dirname(data_folder_mois)
    FileUtils.rm_rf(data_folder_mois) if File.exist?(data_folder_mois)
    FileUtils.mv(downloads_folder, "#{dst_folder}/")

    suivi "Fichier CSV utiles renommés et déplacés vers les données Icare."
  end

end #/<< self
end #/UDecMois
end #/Iced