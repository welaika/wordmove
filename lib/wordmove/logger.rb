require 'colored'

module Wordmove
  class Logger

    INFO = 0
    VERBOSE = 1

    attr_accessor :level

    def log(l, message)
      colors = [ :green, :cyan ]
      if l <= level
        puts "  " * l + message.send(colors[l])
      end
    end

    def info(message)
      log INFO, message
    end

    def verbose(message)
      log VERBOSE, message
    end

  end
end
