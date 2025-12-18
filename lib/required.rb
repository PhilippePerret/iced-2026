require 'tty-prompt'
Q = TTY::Prompt.new(symbols: {radio_on:"☒", radio_off:"☐"})

# To required a folder (only in ./lib)
def require_folder(folder)
  Dir["#{__dir__}/#{folder}/**/*.rb"].each { |m| require m }#.tap{|l| puts 'REQUIRED ' + l.inspect}
end


require_folder('xtensions')
require_folder('xutils')
require_folder('classes')


App = Iced::App.new