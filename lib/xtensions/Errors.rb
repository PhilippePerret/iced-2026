module Iced
  class FatalError < StandardError; end

  class Err

    def [](type, err_id, params = nil)
      derror = ERRORS[err_id]
      message = derror[:message] + "\n=> " + (derror[:help] || '')
      unless params.nil?
        params = [params] unless params.is_a?(Array)
        params.each_with_index { message.gsub!(/_#{_2}_/, _1.to_s) }
      end
      # Provenance de l'erreur
      caller = caller_locations(1, 1).first
      caller_name = caller.base_label # 3.4.7
      caller_file = caller.path.sub(APP_FOLDER, '.')
      caller_line = caller.lineno
      message += "\n[err_id: #{err_id.inspect} in: #{caller_file} at: #{caller_line}]"
      raise TYPES[type].new(message)
    end

    TYPES = {
      fatal: FatalError
    }

    ERRORS = {
      rapport_kdp_unfound: {
        message: "Le rapport KDP du mois est introuvable",
        help: "Rejoindre le site KDP et exporter la rapport du mois précédent"
      },
      too_much_kdp_report: {
        message: "J'ai trouvé plusieurs rapport KDP pour le mois…",
        help: "Supprimer les rapports des autres mois."
      },
      numbers_count_docs_error: {
        message:  <<~ERR,
                  Un problème est survenu en essayant de compter le nombre de 
                  documents dans l’application Numbers. Le problème vient peut-être
                  d’un problème d’accessibilité (si l’application a été actualisée
                  par exemple).
                  ERR
        help: <<~HELP
              POUR TENTER DE REMÉDIER AU PROBLÈME :
                - ouvrir les préférences système, 
                - dans la partie "Confidentialité et sécurité", chercher "Accès complet au disque"
                - ajouter l’application Numbers.
              HELP

      },
      downloads_folder_unfound: {
        message: "Le dossier _0_ est introuvable, dans le dossier des téléchargements.",
        help: "Relancer la procédure précédente pour palier cet écueil."
      },
      bad_number_csv_files_count: {
        message: "Je n'ai pas pu trouver le nombre de fichier CSV attendus…\nAttendus : 5\nTrouvés : _0_",
        help: "Relancer la procédure précédente où regardez ce qui se passe dans 2Change_name_and_location.rb"
      },
      kdp_folder_in_data_unfound: {
        message: "Dossier de destination “_0_” introuvable à l'adresse : _0_",
        help: "Modifier la donnée REAL_EDITIONS_FOLDER dans xutils/constants pour indiquer\n  le nouvel emplacement du dossier des données Editions Icare."
      },
      data_csv_folder_unfound_in_data: {
        message: "Le dossier “_0_” est introuvable dans les données des éditions Icare. Je dois renoncer.",
        help: "Refaire les procédures précédente ou voir dans le fichier 2Change_name_and_location.rb ce qui a pu se passer"
      },
    }
  end #/Err
end #/Iced

ERR = Iced::Err.new