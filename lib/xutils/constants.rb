require 'ostruct'
require 'date'
require 'yaml'

YAML_OPTIONS = {symbolize_names: true, permitted_classes: [Date, Integer, Symbol, Time]}

module Iced
  def self.test? = false

  LIB_FOLDER      = File.dirname(__dir__)
  APP_FOLDER      = File.dirname(LIB_FOLDER)
  PROCS_FOLDER    = File.join(LIB_FOLDER, 'PROCEDURES')
  EXPORT_FOLDER   = File.join(APP_FOLDER, 'exports')

  # ÉDITIONS ICARE
  REAL_EDITIONS_FOLDER = "#{Dir.home}/ICARE_EDITIONS"
  EDITIONS_FOLDER = test? ? TEST_EDITIONS_FOLDER : REAL_EDITIONS_FOLDER
  ALL_DATA_FOLDER = File.join(EDITIONS_FOLDER,'Administration','DATA').freeze

  PRODUITS_FOLDER = File.join(ALL_DATA_FOLDER, 'produits')
  KDP_FOLDER      = File.join(ALL_DATA_FOLDER, 'kdp')
  LIVREES_FOLDER  = File.join(ALL_DATA_FOLDER, 'livrees')
  VENTES_FOLDER   = File.join(ALL_DATA_FOLDER, 'ventes')

  # Données Icare
  DATA_EDITIONS_PATH = File.join(ALL_DATA_FOLDER, 'editions.yaml')
  DATA_ICARE = OpenStruct.new(YAML.safe_load(IO.read(DATA_EDITIONS_PATH), **YAML_OPTIONS))
  ICARE_DESIGNATION = "#{DATA_ICARE.name} — #{DATA_ICARE.adresse.split("\n").map{|n|n.strip}.join(' — ')}"
  ICARE_SIRET       = DATA_ICARE.siret.to_s


  AMAZON_CLIENT_ID = 18

end #/Iced


