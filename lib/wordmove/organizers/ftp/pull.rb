module Wordmove
  module Organizers
    module Ftp
      class Pull
        extend ::LightService::Organizer
        include Wordmove::Actions::Helpers
        include Wordmove::Actions::Ftp::Helpers

        # Can't use keyword arguments since LightService still has some problems with modern
        # ruby syntax: https://github.com/adomokos/light-service/pull/224
        def self.call(cli_options, movefile)
          logger = Logger.new($stdout, movefile.secrets).tap { |l| l.level = Logger::DEBUG }
          remote_options = movefile.options[movefile.environment]
          ftp_opts = ftp_options(remote_options:)

          LightService::Configuration.logger = ::Logger.new($stdout) if cli_options[:debug]

          with(
            cli_options:,
            global_options: movefile.options[:global],
            local_options: movefile.options[:local],
            remote_options:,
            movefile:,
            guardian: Wordmove::Guardian.new(cli_options:, action: :pull),
            logger:,
            photocopier: Photocopier::FTP
                          .new(ftp_opts)
                          .tap { |c| c.logger = logger }
          ).reduce(actions)
        end

        def self.actions
          [
            Wordmove::Actions::RunBeforePullHook, # Will fail and warn the user
            Wordmove::Actions::FilterAndSetupTasksToRun,
            reduce_if(
              ->(ctx) { ctx.wordpress_task },
              [Wordmove::Actions::Ftp::PullWordpress]
            ),
            iterate(:folder_tasks, [Wordmove::Actions::Ftp::GetDirectory]),
            reduce_if(->(ctx) { ctx.database_task },
                      [
                        Wordmove::Actions::SetupContextForDb,
                        Wordmove::Actions::BackupLocalDb,
                        Wordmove::Actions::Ftp::DownloadRemoteDb,
                        Wordmove::Actions::AdaptRemoteDb,
                        Wordmove::Actions::Ftp::CleanupAfterAdapt
                      ]),
            Wordmove::Actions::RunAfterPullHook # Will fail and warn the user
          ]
        end
      end
    end
  end
end
