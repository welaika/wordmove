module Wordmove
  module Actions
    module Ssh
      class Pull
        extend ::LightService::Organizer
        include Wordmove::Actions::Helpers
        include Wordmove::Actions::Ssh::Helpers

        def self.call(options:, cli_options:, movefile:)
        def self.call(cli_options:, movefile:)
          logger = Logger.new(STDOUT, movefile.secrets).tap { |l| l.level = Logger::DEBUG }
          remote_options = options[movefile.environment]
          remote_options = movefile.options[movefile.environment]
          ssh_opts = ssh_options(remote_options: remote_options, simulate: cli_options[:simulate])

          with(
            options: options,
            options: movefile.options,
            cli_options: cli_options,
            global_options: options[:global],
            local_options: options[:local],
            global_options: movefile.options[:global],
            local_options: movefile.options[:local],
            remote_options: remote_options,
            movefile: movefile,
            guardian: Wordmove::Guardian.new(options: options, action: :pull),
            guardian: Wordmove::Guardian.new(options: movefile.options, action: :pull),
            logger: logger,
            photocopier: Photocopier::SSH
                          .new(ssh_opts)
                          .tap { |c| c.logger = logger },
            current_task: nil
          ).reduce(actions)
        end

        def self.actions
          [
            Wordmove::Actions::RunBeforePullHook
          ].concat [
            execute(->(ctx) { ctx[:current_task] = :wordpress }),
            reduce_if(-> (ctx) { barrage(ctx) }, [
              Wordmove::Actions::Ssh::PullWordpress
            ]),
            execute(->(ctx) { ctx[:current_task] = :uploads }),
            reduce_if(-> (ctx) { barrage(ctx) }, [
              Wordmove::Actions::Ssh::PullUploads
            ]),
            execute(->(ctx) { ctx[:current_task] = :themes }),
            reduce_if(-> (ctx) { barrage(ctx) }, [
              Wordmove::Actions::Ssh::PullThemes
            ]),
            execute(->(ctx) { ctx[:current_task] = :plugins }),
            reduce_if(-> (ctx) { barrage(ctx) }, [
              Wordmove::Actions::Ssh::PullPlugins
            ]),
            execute(->(ctx) { ctx[:current_task] = :mu_plugins }),
            reduce_if(-> (ctx) { barrage(ctx) }, [
              Wordmove::Actions::Ssh::PullMuPlugins
            ]),
            execute(->(ctx) { ctx[:current_task] = :languages }),
            reduce_if(-> (ctx) { barrage(ctx) }, [
              Wordmove::Actions::Ssh::PullLanguages
            ]),
          ].concat(db_actions).concat [
            Wordmove::Actions::RunAfterPullHook
          ]
        end

        def self.db_actions
          [
            execute(->(ctx) { ctx[:current_task] = :db }),
            reduce_if(->(ctx) {
                                barrage(ctx) &&
                                ctx[:options][:global][:sql_adapter] == 'wpcli'
                              }, [Wordmove::Actions::Ssh::WpcliAdapter::PullDb]),
            reduce_if(->(ctx) {
                                barrage(ctx) &&
                                ctx[:options][:global][:sql_adapter] == 'default'
                              }, [Wordmove::Actions::Ssh::BuiltinAdapter::PullDb])
          ]
        end

        def self.barrage(ctx)
          task = ctx.fetch(:current_task)

          return false unless ctx.fetch(:guardian).allows(task)

          ctx.fetch(:cli_options)[task] ||
            (ctx.fetch(:cli_options)["all"] && ctx.fetch(:cli_options)[task] != false)
        end
      end
    end
  end
end
