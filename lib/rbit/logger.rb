require 'logger'
require 'paint'

module Rbit
  class Logger < ::Logger
    COLORS = {
      'DEBUG' => :green,
      'INFO' => :blue,
      'WARN' => :yellow,
      'ERROR' => :red,
      'FATAL' => :red
    }

    def initialize(file, log_level)
      super(file)
      self.level = log_level
      self.formatter = proc do |level, time, prefix, msg|
        prefix ||= Paint['--', :yellow]
        color = COLORS[level]
        Paint['[', color, :bright] + time.asctime + Paint[']', color, :bright] + " #{prefix} #{msg}\n"
      end
    end

    def in(msg)
      debug(Paint['>>', :cyan]) { msg.to_s }
    end

    def out(msg)
      debug(Paint['<<', :magenta]) { msg.to_s }
    end
  end
end
