# encoding: utf-8

require 'colored'
require 'logger'

module Wordmove
  class Logger < ::Logger

    def task(title)
      puts ""
      title = " ✓ #{title} "
      puts "▬" * 2 + title.green + "▬" * (70 - title.length)
    end

    def task_step(local_step, title)
      if local_step
        puts "    local".cyan + " | ".black + title
      else
        puts "   remote".yellow + " | ".black + title
      end
    end

  end
end
