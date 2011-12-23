require 'escape'

module Wordmove
  class LocalHost

    attr_reader :options
    attr_reader :logger
    attr_reader :ssh_extras

    def initialize(options = {})
      @options = Hashie::Mash.new(options)
      @logger = @options[:logger]
      @ssh_extras = {}
      [ :port, :password ].each do |p|
        @ssh_extras.merge!( { p => @options.ssh[p] } ) if @options.ssh and @options.ssh[p]
      end
    end

    def run(*args)
      command = shell_command(*args)
      logger.verbose "Executing locally #{command}"
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
