module Wordmove
  module CLI
    module PullPushShared
      extend ActiveSupport::Concern
      WORDPRESS_OPTIONS = %i[wordpress uploads themes plugins mu_plugins languages db].freeze

      included do # rubocop:disable Metrics/BlockLength
        option :wordpress, type: :boolean, aliases: %w[w]
        option :uploads, type: :boolean, aliases: %w[u]
        option :themes, type: :boolean, aliases: %w[t]
        option :plugins, type: :boolean, aliases: %w[p]
        option :mu_plugins, type: :boolean, aliases: %w[m]
        option :languages, type: :boolean, aliases: %w[l]
        option :db, type: :boolean, aliases: %w[d]
        option :simulate, type: :boolean
        option :environment, aliases: %w[e]
        option :config, aliases: %w[c]
        option :no_adapt, type: :boolean
        option :all, type: :boolean
        # option :verbose, type: :boolean, aliases: %w[v]
        option :debug, type: :boolean

        private

        def ensure_wordpress_options_presence!(cli_options)
          return if (
            cli_options.deep_symbolize_keys.keys &
              (Wordmove::CLI::PullPushShared::WORDPRESS_OPTIONS + [:all])
          ).present?

          puts 'No options given. See wordmove --help'
          exit 1
        end

        def initial_context(cli_options)
          cli_options.deep_symbolize_keys!
          movefile = Wordmove::Movefile.new(cli_options)

          [cli_options, movefile]
        end

        def movefile_from(**cli_options)
          ensure_wordpress_options_presence!(cli_options)
          Wordmove::Movefile.new(cli_options)
        rescue MovefileNotFound => e
          Logger.new($stdout).error(e.message)
          exit 1
        end

        def call_organizer_with(klass:, movefile:, **cli_options)
          result = klass.call(cli_options: cli_options, movefile: movefile)

          result.success? ? exit(0) : exit(1)
        end
      end
    end

    module Commands
      extend Dry::CLI::Registry

      class Version < Dry::CLI::Command
        desc 'Print the version'

        def call(*)
          puts Wordmove::VERSION
        end
      end

      class Init < Dry::CLI::Command
        desc 'Generates a brand new movefile.yml'

        def call(*)
          Wordmove::Generators::Movefile.generate
        end
      end

      class Doctor < Dry::CLI::Command
        desc 'Do some local configuration and environment checks'

        def call(*)
          Wordmove::Doctor.start
        end
      end

      class List < Dry::CLI::Command
        desc 'List all environments and vhosts'

        option :config, aliases: %w[c]

        def call(**cli_options)
          Wordmove::EnvironmentsList.print(cli_options)
        rescue Wordmove::MovefileNotFound => e
          Logger.new($stdout).error(e.message)
          exit 1
        rescue Psych::SyntaxError => e
          Logger.new($stdout)
                .error("Your movefile is not parsable due to a syntax error: #{e.message}")
          exit 1
        end
      end

      class Pull < Dry::CLI::Command
        desc 'Pulls WP data from remote host to the local machine'

        include Wordmove::CLI::PullPushShared

        def call(**cli_options)
          call_pull_organizer_with(**cli_options)
        end

        private

        def call_pull_organizer_with(**cli_options)
          movefile = movefile_from(**cli_options)

          if movefile.options.dig(movefile.environment, :ssh)
            call_organizer_with(
              klass: Wordmove::Organizers::Ssh::Pull,
              movefile: movefile,
              **cli_options
            )
          elsif movefile.options.dig(movefile.environment, :ftp)
            call_organizer_with(
              klass: Wordmove::Organizers::Ftp::Pull,
              movefile: movefile,
              **cli_options
            )
          else
            raise NoAdapterFound, 'No valid adapter found.'
          end
        rescue NoAdapterFound => e
          Logger.new($stdout).error(e.message)
          exit 1
        end
      end

      class Push < Dry::CLI::Command
        desc 'Pulls WP data from remote host to the local machine'

        include Wordmove::CLI::PullPushShared

        def call(**cli_options)
          call_push_organizer_with(**cli_options)
        end

        private

        def call_push_organizer_with(**cli_options)
          movefile = movefile_from(cli_options)

          if movefile.options.dig(movefile.environment, :ssh)
            call_organizer_with(
              klass: Wordmove::Organizers::Ssh::Push,
              movefile: movefile,
              **cli_options
            )
          elsif movefile.options.dig(movefile.environment, :ftp)
            call_organizer_with(
              klass: Wordmove::Organizers::Ftp::Push,
              movefile: movefile,
              **cli_options
            )
          else
            raise NoAdapterFound, 'No valid adapter found.'
          end
        rescue NoAdapterFound => e
          Logger.new($stdout).error(e.message)
          exit 1
        end
      end

      register 'version', Version, aliases: %w[v -v --version]
      register 'init', Init
      register 'doctor', Doctor
      register 'list', List
      register 'pull', Pull
      register 'push', Push
    end
  end
end
