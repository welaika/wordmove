module Wordmove
  class LocalHost

    attr_reader :options

    def initialize(options = {})
      @options = Hashie::Mash.new(options)
    end

    def run(*args)
      command = shell_command(*args)
      pa "Executing locally #{command}", :green, :bright
      unless system(command)
        raise Thor::Error, "Error executing \"#{command}\""
      end
    end

    def close
    end

    protected

    def shell_command(*args)
      options = args.extract_options!
      command = Escape.shell_command(args)
      if options[:stdin]
        command += " < #{options[:stdin]}"
      end
      if options[:stdout]
        command += " > #{options[:stdout]}"
      end
      command
    end

  end
end
