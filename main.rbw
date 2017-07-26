# frozen_string_literal: true

if not defined?(Ocra)
  #remove system ruby
  ENV["Path"] = ENV["Path"].sub(/;?[a-zA-Z]?:[a-zA-z]*\\ruby[^;]*/i,"")

  #add local bin to path
  ENV["Path"] = ENV["Path"]+";#{(Dir.pwd).sub("src","bin")}"
end

require 'win32ole'
require 'optparse'
require 'date'
require 'gtk3'
require 'watir'
# require 'pry'
# require 'ap'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: main.rb [options]"

  opts.on("-s", "--[no-]scheduler", "Run schduler") do |s|
    options[:scheduler] = s
  end
end.parse!

begin
if options[:scheduler]
  require File.join(File.dirname(__FILE__), 'lib/gui_scheduler.rb')
   $PROGRAM_NAME = "scheduler"
   window = SchedulerGui.new
else
  require File.join(File.dirname(__FILE__), 'lib/gui.rb')
  window = Gui.new
end
rescue => e
  p e.backtrace
  p e.message
  exit!
end

Gtk.main
