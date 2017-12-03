module Wordmove
  class Logger < ::Logger
    MAX_LINE = 70

    def task(title)
      prefix = "▬" * 2
      title = " ✓ #{title} "
      padding = "▬" * padding_length(title)

      puts "\n" + prefix + title.green + padding
    end

    def task_step(local_step, title)
      if local_step
        puts "    local".cyan + " | ".black + title.to_s
      else
        puts "   remote".yellow + " | ".black + title.to_s
      end
    end

    def error(message)
      puts "    error".red + " | ".black + message.to_s
    end

    def success(message)
      puts "    success".green + " | ".black + message.to_s
    end

    def debug(message)
      puts "    debug".magenta + " | ".black + message.to_s
    end

    private

    def padding_length(line)
      result = MAX_LINE - line.length
      result > 0 ? result : 0
    end
  end
end
