module Iced
class App

  def run
    op = (defined?(ICED_OPE) && ICED_OPE) || ARGV[0] || ask_for_operation
    case op
    when NilClass then return
    when :impots, 'impots'
      traite_operation(op.to_sym)
    else puts "Je ne traite pas encore l'opération #{op.inspect}".rouge
    end
  end

  def traite_operation(ope)
    require_folder("PROCEDURES/#{OPE2FOLDER[ope]}")
    Iced::Ope.new.run
  end

  OPE2FOLDER = {
    impots: 'declaration_mensuelle_impots'
  }

  private def ask_for_operation
    op = Q.select("Opération".jaune, OPERATIONS).tap do 
      puts "La prochaine fois, tu pourras jouer directement la commande `iced #{it}'".gris
    end
  end

  OPERATIONS = [
    {name: "Déclaration mensuelle URSSAF", value: :impots}, 
    {name: 'autre', value: :autre},
    {name: 'Renoncer'.orange, value: nil}
  ]
end #/App
end #/Iced