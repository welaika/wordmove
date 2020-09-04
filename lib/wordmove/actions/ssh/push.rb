module Wordmove
  module Actions
    module Ssh
      class Push
        extend ::LightService::Organizer
        include Wordmove::Actions::Helpers
        include Wordmove::Actions::Ssh::Helpers

        def self.call(cli_options:, movefile:)
          logger = Logger.new(STDOUT, movefile.secrets).tap { |l| l.level = Logger::DEBUG }
          remote_options = movefile.options[movefile.environment]
          ssh_opts = ssh_options(remote_options: remote_options, simulate: cli_options[:simulate])

          LightService::Configuration.logger = ::Logger.new(STDOUT) if cli_options[:debug]

          with(
            options: movefile.options,
            cli_options: cli_options,
            global_options: movefile.options[:global],
            local_options: movefile.options[:local],
            remote_options: remote_options,
            movefile: movefile,
            guardian: Wordmove::Guardian.new(cli_options: cli_options, action: :push),
            logger: logger,
            photocopier: Photocopier::SSH
                          .new(ssh_opts)
                          .tap { |c| c.logger = logger }
          ).reduce(actions)
        end

        def self.actions
          [
            Wordmove::Actions::RunBeforePushHook,
            Wordmove::Actions::FilterAndSetupTasksToRun,
            reduce_if(
              ->(ctx) { ctx.wordpress_task },
              [Wordmove::Actions::Ssh::PushWordpress]
            ),
            iterate(:folder_tasks, [Wordmove::Actions::Ssh::PutDirectory])
          ].concat(
            db_actions
          ).concat [
            Wordmove::Actions::RunAfterPushHook
          ]
        end

        # rubocop:disable Metrics/MethodLength
        def self.db_actions
          [
            reduce_if(
              lambda do |ctx|
                ctx.database_task &&
                ctx.dig(:global_options, :sql_adapter) == 'wpcli'
              end,
              [
                Wordmove::Actions::Ssh::WpcliAdapter::SetupContextForDb,
                Wordmove::Actions::Ssh::WpcliAdapter::BackupRemoteDb,
                Wordmove::Actions::Ssh::WpcliAdapter::AdaptLocalDb,
                Wordmove::Actions::Ssh::PutAndImportDumpRemotely,
                Wordmove::Actions::Ssh::CleanupAfterAdapt
              ]
            ),
            reduce_if(
              lambda do |ctx|
                ctx.database_task &&
                ctx.dig(:global_options, :sql_adapter) == 'default'
              end,
              [Wordmove::Actions::Ssh::BuiltinAdapter::PushDb]
            )
          ]
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
