=begin

  Pour obtenir les taux de changes des principales monnaies.

  Je suis abonné à https://apilayer.com pour les obtenir par
  simple requête

  Voir :
  https://apilayer.com/marketplace/currency_data-api?utm_source=apilayermarketplace&utm_medium=featured

=end
require "yaml"
require "json"

# 
# Toutes les devises connues
# 
DEVISES = ['AUD','USD','CAD','GBP','JPY','CHF','CNY','DKK','HKD','NZD','MXN','BRL']

#
# Clé API pour apilayer.com
# OBSOLÈTE (ne fonctionne plus)
# CURRENCYLAYER_KEY = File.read(File.join(Dir.home,'.secret','currentcylayer_key')).strip

# 
# Clé API pour le site fixer.io
# 
FIXERIO_ACCESS_KEY = File.read(File.join(Dir.home, ".secret","fixer.io.access_key")).strip

def devises_changes_path
  File.join(Iced::ALL_DATA_FOLDER, 'devises_changes.yaml')
end

# @return [Hash] Une table contenant en clé les devises string au
#         format 'XXX' et en valeur le taux de change.
# @note
#   Pour obtenir la valeur en euro, il faut multiplier le montant
#   dans la devise par ce taux de change.
#   cf. https://apilayer.com/marketplace/currency_data-api?live_demo=show
# 
def get_changes_for_devises
  
  if File.exist?(devises_changes_path)
    # 
    # Le fichier existe, on regarde s'il n'est pas trop vieux
    # (> semaine)
    # 
    data_devises = get_old_data_devises

    if (data_devises[:date] + (7 * 3600 * 24) > Time.now.to_i)
      return data_devises[:taux_change]
    end
  end

  # On doit récupérer les taux de changes et les enregistrer
  curl = "https://data.fixer.io/api/latest?access_key=#{FIXERIO_ACCESS_KEY}&base=EUR&symbols=#{DEVISES.join(',')}"

  res = `cURL "#{curl}"`
  # puts "#{res.class.name}::#{res.inspect}"
  # => Un retour de la forme : 
  # {"success":true,"timestamp":1749629655,"base":"EUR","date":"2025-06-11","rates":{"USD":1.14227,"AUD":1.75431,"CAD":1.5623}}
  table = JSON.parse(res)
  if table["success"]
    save_and_return_new_taux_changes(table)
  else
    puts "Malheureusement, je n’ai pas réussi à relever les taux de change. Je dois utiliser les anciennes valeurs."
    get_old_data_devises[:taux_change]
  end

end

def get_old_data_devises
  YAML.safe_load(IO.read(devises_changes_path), **YAML_OPTIONS)
end

def save_and_return_new_taux_changes(table)
  # 
  # On récupère les taux de change dans la table retournée
  # 
  table_devises = {date: Time.now.to_i, taux_change: {}}
  DEVISES.each do |devise|
    change = table['rates']["#{devise}"]
    change = (1.0 / change).round(4)
    table_devises[:taux_change].merge!({
      devise.to_s   => change,
      devise.to_sym => change
    })
  end
  # 
  # On écrit ces taux de change dans un fichier YAML qui
  # servira toute la semaine
  # 
  File.open(devises_changes_path,'wb') { |f| f.write table_devises.to_yaml }
  # puts "table_devises: #{table_devises.inspect}".bleu
  return table_devises[:taux_change]
end


# Pour essayer de relever le taux de change en appelant directement
# ce fichier. Peut servir, en cas de problème, à actualiser à la main
# les taux de change.
# puts get_changes_for_devises
