module Wordmove
  module Organizers
    module Ssh
      class Pull
        extend ::LightService::Organizer
        include Wordmove::Actions::Helpers
        include Wordmove::Actions::Ssh::Helpers

        def self.call(cli_options:, movefile:)
          logger = Logger.new($stdout, movefile.secrets).tap { |l| l.level = Logger::DEBUG }
          remote_options = movefile.options[movefile.environment]
          ssh_opts = ssh_options(remote_options: remote_options, simulate: cli_options[:simulate])

          LightService::Configuration.logger = ::Logger.new(STDOUT) if cli_options[:debug]

          with(
            cli_options: cli_options,
            global_options: movefile.options[:global],
            local_options: movefile.options[:local],
            remote_options: remote_options,
            movefile: movefile,
            guardian: Wordmove::Guardian.new(cli_options: cli_options, action: :pull),
            logger: logger,
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
            iterate(:folder_tasks, [Wordmove::Actions::Ssh::GetDirectory])
          ].concat [
            Wordmove::Actions::Ssh::WpcliAdapter::SetupContextForDb,
            Wordmove::Actions::Ssh::WpcliAdapter::BackupLocalDb,
            Wordmove::Actions::Ssh::WpcliAdapter::AdaptRemoteDb,
            Wordmove::Actions::Ssh::CleanupAfterAdapt
          ].concat [
            Wordmove::Actions::RunAfterPullHook
          ]
        end
      end
    end
  end
end
