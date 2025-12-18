begin
  require_relative 'lib/required'
  App.run
rescue TTY::Reader::InputInterrupt => e
  puts "bye bye".blue
rescue => e
  puts e.message.rouge
  puts e.backtrace.join("\n").rouge
end