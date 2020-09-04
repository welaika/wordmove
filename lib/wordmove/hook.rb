module Wordmove
  class Hook
    def self.logger
      Logger.new(STDOUT).tap { |l| l.level = Logger::DEBUG }
    end

    # rubocop:disable Metrics/MethodLength
    def self.run(action, step, movefile:, simulate: false)
      options = movefile.options
      environment = movefile.environment

      hooks = Wordmove::Hook::Config.new(
        options[environment][:hooks],
        action,
        step
      )

      return if hooks.empty?

      logger.task "Running #{action}/#{step} hooks"

      hooks.all_commands.each do |command|
        case command.fetch(:where)
        when 'local'
          Wordmove::Hook::Local.run(command, options[:local], simulate)
        when 'remote'
          if options[environment][:ftp]
            logger.debug 'You have configured remote hooks to run over '\
                         'an FTP connection, but this is not possible. Skipping.'
            next
          end

          Wordmove::Hook::Remote.run(command, options[environment], simulate)
        else
          next
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    Config = Struct.new(:options, :action, :step) do
      def empty?
        all_commands.empty?
      end

      def all_commands
        return [] if empty_step?

        options[action][step] || []
      end

      def local_commands
        return [] if empty_step?

        options[action][step]
          .select { |hook| hook[:where] == 'local' } || []
      end

      def remote_commands
        return [] if empty_step?

        options[action][step]
          .select { |hook| hook[:where] == 'remote' } || []
      end

      private

      def empty_step?
        return true unless options
        return true if options[action].nil?
        return true if options[action][step].nil?
        return true if options[action][step].empty?

        false
      end
    end

    class Local
      def self.logger
        parent.logger
      end

      def self.run(command_hash, options, simulate = false)
        wordpress_path = options[:wordpress_path]

        logger.task_step true, "Exec command: #{command_hash[:command]}"
        return true if simulate

        stdout_return = `cd #{wordpress_path} && #{command_hash[:command]} 2>&1`
        logger.task_step true, "Output: #{stdout_return}"

        if $CHILD_STATUS.exitstatus.zero?
          logger.success ''
        else
          logger.error "Error code: #{$CHILD_STATUS.exitstatus}"
          raise Wordmove::LocalHookException unless command_hash[:raise].eql? false
        end
      end
    end

    class Remote
      def self.logger
        parent.logger
      end

      def self.run(command_hash, options, simulate = false)
        ssh_options = options[:ssh]
        wordpress_path = options[:wordpress_path]

        copier = Photocopier::SSH.new(ssh_options).tap { |c| c.logger = logger }

        logger.task_step false, "Exec command: #{command_hash[:command]}"
        return true if simulate

        stdout, stderr, exit_code =
          copier.exec!("cd #{wordpress_path} && #{command_hash[:command]}")

        if exit_code.zero?
          logger.task_step false, "Output: #{stdout}"
          logger.success ''
        else
          logger.task_step false, "Output: #{stderr}"
          logger.error "Error code #{exit_code}"
          raise Wordmove::RemoteHookException unless command_hash[:raise].eql? false
        end
      end
    end
  end
end
