require 'colored'

module Wordmove
  class Logger

    ERROR = 0
    INFO = 1
    VERBOSE = 2

    attr_accessor :level

    def log(l, message)
      colors = [ :red, :green, :cyan ]
      if l <= level
        puts "  " * [l-1, 0].max + message.send(colors[l])
      end
    end

    def info(message)
      log INFO, message
    end

    def verbose(message)
      log VERBOSE, message
    end

    def error(message)
      log ERROR, message
    end

  end
end
