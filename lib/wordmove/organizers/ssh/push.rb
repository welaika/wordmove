module Wordmove
  module Organizers
    module Ssh
      class Push
        extend ::LightService::Organizer
        include Wordmove::Actions::Helpers
        include Wordmove::Actions::Ssh::Helpers

        # Can't use keyword arguments since LightService still has some problems with modern
        # ruby syntax: https://github.com/adomokos/light-service/pull/224
        def self.call(cli_options, movefile)
          logger = Logger.new($stdout, movefile.secrets).tap { |l| l.level = Logger::DEBUG }
          remote_options = movefile.options[movefile.environment]
          ssh_opts = ssh_options(remote_options:, simulate: cli_options[:simulate])

          LightService::Configuration.logger = ::Logger.new($stdout) if cli_options[:debug]

          with(
            cli_options:,
            global_options: movefile.options[:global],
            local_options: movefile.options[:local],
            remote_options:,
            movefile:,
            guardian: Wordmove::Guardian.new(cli_options:, action: :push),
            logger:,
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
            iterate(:folder_tasks, [Wordmove::Actions::Ssh::PutDirectory]),
            reduce_if(->(ctx) { ctx.database_task },
                      [
                        Wordmove::Actions::SetupContextForDb,
                        Wordmove::Actions::Ssh::DownloadRemoteDb,
                        Wordmove::Actions::Ssh::BackupRemoteDb,
                        Wordmove::Actions::AdaptLocalDb,
                        Wordmove::Actions::Ssh::PutAndImportDumpRemotely,
                        Wordmove::Actions::Ssh::CleanupAfterAdapt
                      ]),
            Wordmove::Actions::RunAfterPushHook
          ]
        end
      end
    end
  end
end
