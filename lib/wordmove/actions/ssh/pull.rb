module Wordmove
  module Actions
    module Ssh
      class Pull
        extend ::LightService::Organizer
        include Wordmove::Actions::Helpers
        include Wordmove::Actions::Ssh::Helpers

        before_actions(lambda do |ctx|
          task = ctx.fetch(:current_task)
          return unless ctx.guardian.allows(task)
          return unless ctx.options[task] || (ctx.options["all"] && ctx.options[task] != false)
        end)

        def self.call(options:, movefile:)
          logger = Logger.new(STDOUT, movefile.secrets).tap { |l| l.level = Logger::DEBUG }

          with(
            options: options,
            movefile: movefile,
            guardian: Wordmove::Guardian.new(options: options, action: :pull),
            logger: logger,
            photocopier: Photocopier::SSH
                          .new(ssh_options(options: options, movefile: movefile))
                          .tap { |c| c.logger = logger },
            current_task: nil
          ).reduce(actions)
        end

        def self.actions
          [
            execute(->(ctx) { ctx[:current_task] = :wordpress }),
            Wordmove::Actions::Ssh::Common::PullWordpress,
            execute(->(ctx) { ctx[:current_task] = :uploads }),
            Wordmove::Actions::Ssh::Common::PullUploads,
            execute(->(ctx) { ctx[:current_task] = :themes }),
            Wordmove::Actions::Ssh::Common::PullThemes,
            execute(->(ctx) { ctx[:current_task] = :plugins }),
            Wordmove::Actions::Ssh::Common::PullPlugins,
            execute(->(ctx) { ctx[:current_task] = :mu_plugins }),
            Wordmove::Actions::Ssh::Common::PullMuPlugins,
            execute(->(ctx) { ctx[:current_task] = :languages }),
            Wordmove::Actions::Ssh::Common::PullLanguages
          ].concat(db_actions)
        end

        def self.db_actions
          [
            execute(->(ctx) { ctx[:current_task] = :db }),
            reduce_if(->(ctx) { ctx.options[:global][:sql_adapter] == 'wpcli' },
                      [
                        Wordmove::Actions::Ssh::WpcliAdapter::PullDb
                      ]),
            reduce_if(->(ctx) { ctx.options[:global][:sql_adapter] == 'default' },
                      [
                        Wordmove::Actions::Ssh::BuiltinAdapter::PullDb
                      ])
          ]
        end
      end
    end
  end
end
