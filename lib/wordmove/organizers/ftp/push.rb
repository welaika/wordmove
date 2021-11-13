module Wordmove
  module Organizers
    module Ftp
      class Push
        extend ::LightService::Organizer
        include Wordmove::Actions::Helpers
        include Wordmove::Actions::Ftp::Helpers

        def self.call(cli_options:, movefile:)
          logger = Logger.new($stdout, movefile.secrets).tap { |l| l.level = Logger::DEBUG }
          remote_options = movefile.options[movefile.environment]
          ftp_opts = ftp_options(remote_options: remote_options)

          LightService::Configuration.logger = ::Logger.new($stdout) if cli_options[:debug]

          with(
            cli_options: cli_options,
            global_options: movefile.options[:global],
            local_options: movefile.options[:local],
            remote_options: remote_options,
            movefile: movefile,
            guardian: Wordmove::Guardian.new(cli_options: cli_options, action: :push),
            logger: logger,
            photocopier: Photocopier::FTP
                          .new(ftp_opts)
                          .tap { |c| c.logger = logger }
          ).reduce(actions)
        end

        def self.actions
          [
            Wordmove::Actions::RunBeforePushHook, # Will fail and warn the user
            Wordmove::Actions::FilterAndSetupTasksToRun,
            reduce_if(
              ->(ctx) { ctx.wordpress_task },
              [Wordmove::Actions::Ftp::PushWordpress]
            ),
            iterate(:folder_tasks, [Wordmove::Actions::Ftp::PutDirectory])
          ].concat [
            Wordmove::Actions::SetupContextForDb,
            Wordmove::Actions::Ftp::DownloadRemoteDb,
            Wordmove::Actions::Ftp::BackupRemoteDb,
            Wordmove::Actions::AdaptLocalDb,
            Wordmove::Actions::Ftp::PutAndImportDumpRemotely,
            Wordmove::Actions::Ftp::CleanupAfterAdapt
          ].concat [
            Wordmove::Actions::RunAfterPushHook # Will fail and warn the user
          ]
        end
      end
    end
  end
end
