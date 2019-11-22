module Wordmove
  class Logger < ::Logger
    MAX_LINE = 70

    def task(title)
      prefix = "▬" * 2
      title = " #{title} "
      padding = "▬" * padding_length(title)
      add(INFO, prefix + title.light_white + padding)
    end

    def task_step(local_step, title)
      if local_step
        add(INFO, "    local".cyan + " | ".black + title.to_s)
      else
        add(INFO, "   remote".yellow + " | ".black + title.to_s)
      end
    end

    def error(message)
      add(ERROR, "    ❌  error".red + " | ".black + message.to_s)
    end

    def success(message)
      add(INFO, "    ✅  success".green + " | ".black + message.to_s)
    end

    def debug(message)
      add(DEBUG, "    🛠  debug".magenta + " | ".black + message.to_s)
    end

    def warn(message)
      add(WARN, "    ⚠️  warning".yellow + " | ".black + message.to_s)
    end

    def info(message)
      add(INFO, "    ℹ️  info".yellow + " | ".black + message.to_s)
    end

    def plain(message)
      puts message.to_s
    end

    private

    def padding_length(line)
      result = MAX_LINE - line.length
      result.positive? ? result : 0
    end
  end
end
