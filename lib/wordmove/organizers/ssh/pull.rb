module Wordmove
  module Organizers
    module Ssh
      class Pull
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
            guardian: Wordmove::Guardian.new(cli_options:, action: :pull),
            logger:,
            photocopier: Photocopier::SSH
                          .new(ssh_opts)
                          .tap { |c| c.logger = logger }
          ).reduce(actions)
        end

        def self.actions
          [
            Wordmove::Actions::RunBeforePullHook,
            Wordmove::Actions::FilterAndSetupTasksToRun,
            reduce_if(
              ->(ctx) { ctx.wordpress_task },
              [Wordmove::Actions::Ssh::PullWordpress]
            ),
            iterate(:folder_tasks, [Wordmove::Actions::Ssh::GetDirectory]),
            reduce_if(->(ctx) { ctx.database_task },
                      [
                        Wordmove::Actions::SetupContextForDb,
                        Wordmove::Actions::BackupLocalDb,
                        Wordmove::Actions::Ssh::DownloadRemoteDb,
                        Wordmove::Actions::AdaptRemoteDb,
                        Wordmove::Actions::Ssh::CleanupAfterAdapt
                      ]),
            Wordmove::Actions::RunAfterPullHook
          ]
        end
      end
    end
  end
end
