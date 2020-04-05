module Wordmove
  class Guardian
    attr_reader :movefile, :environment, :action, :logger

    def initialize(options: nil, action: nil)
      @movefile = Wordmove::Movefile.new(options, nil, false)
      @environment = @movefile.environment.to_sym
      @action = action
      @logger = Logger.new(STDOUT).tap { |l| l.level = Logger::DEBUG }
    end

    def allows(task)
      if forbidden?(task)
        logger.task("#{action.capitalize}ing #{task.capitalize}")
        logger.warn("You tried to #{action} #{task}, but is forbidden by configuration. Skipping")
      end

      !forbidden?(task)
    end

    private

    def forbidden?(task)
      return false unless forbidden_tasks[task].present?

      forbidden_tasks[task] == true
    end

    def forbidden_tasks
      environment_options = movefile.options[environment]
      return {} unless environment_options.key?(:forbid)
      return {} unless environment_options[:forbid].key?(action)

      environment_options[:forbid][action]
    end
  end
end
