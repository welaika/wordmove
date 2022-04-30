require 'pathname'

# rubocop:disable Metrics/BlockLength
module Wordmove
  module Actions
    module Ssh
      module Helpers
        extend ActiveSupport::Concern

        class_methods do
          #
          # Utility method to retrieve and augment ssh options from the superset of remote options.
          # This is useful most because it appends +--dy-run+ rsync's flag to ssh options based
          # on +--simulate+ flag presence
          #
          # @param [Hash] remote_options Remote host options fetcehd from movefile
          # @param [Bool] simulate Tell the moethod if you're in a simulated operation
          #
          # @return [Hash] Ssh options
          #
          def ssh_options(remote_options:, simulate: false)
            ssh_options = remote_options[:ssh]

            if simulate == true && ssh_options[:rsync_options]
              ssh_options[:rsync_options].concat(' --dry-run')
            elsif simulate == true
              ssh_options[:rsync_options] = '--dry-run'
            end

            ssh_options
          end

          #
          # Given the directory you're pushing/pulling, generates an array of path to be included
          # by rsync while pushing. Note that by design include paths are always required but are
          # only programmatically deduced and never user configured.
          #
          # @note The business logic behind how these paths are produced should be deepened
          #
          # @param [WordpressDirectory] local_task_dir An object representing a wordpress folder
          #
          # @return [Array<String>] The array of path to be included by rsync
          #
          def push_include_paths(local_task_dir:)
            Pathname.new(local_task_dir.relative_path)
                    .ascend
                    .each_with_object([]) do |directory, array|
                      path = directory.to_path
                      path.prepend('/') unless path.match? %r{^/}
                      path.concat('/') unless path.match? %r{/$}
                      array << path
                    end
          end

          #
          # Given the directory you're pushing/pulling and the user configured exclude list,
          # generates an array of path to be excluded
          # by rsync while pushing. Note that by design exclude some paths are always required
          # even when the user does not confiure any exclusion.
          #
          # @note The business logic behind how these paths are produced should be deepened
          #
          # @param [WordpressDirectory] local_task_dir An object representing a wordpress folder
          # @param [Array<String>] pats_to_exclude An array of paths
          #
          # @return [Array<String>] The array of path to be included by rsync
          #
          def push_exclude_paths(local_task_dir:, paths_to_exclude:)
            Pathname.new(local_task_dir.relative_path)
                    .dirname
                    .ascend
                    .each_with_object([]) do |directory, array|
                      path = directory.to_path
                      path.prepend('/') unless path.match? %r{^/}
                      path.concat('/') unless path.match? %r{/$}
                      path.concat('*')
                      array << path
                    end
                    .concat(paths_to_exclude)
                    .concat(['/*'])
          end

          #
          # Same as Wordmove::Actions::Ssh::Helpers.push_include_path but for pull actions
          #
          # @param [WordpressDirectory] local_task_dir An object representing a wordpress folder
          #
          # @return [Array<String>] An array of paths
          #
          def pull_include_paths(remote_task_dir:)
            Pathname.new(remote_task_dir.relative_path)
                    .ascend
                    .each_with_object([]) do |directory, array|
                      path = directory.to_path
                      path.prepend('/') unless path.match? %r{^/}
                      path.concat('/') unless path.match? %r{/$}
                      array << path
                    end
          end

          #
          # Same as Wordmove::Actions::Ssh::Helpers.push_exclude_path but for pull actions
          #
          # @param [WordpressDirectory] local_task_dir An object representing a wordpress folder
          # @param [Array<String>] paths_to_exclude User configured array of paths to exclude
          #
          # @return [Array<String>] Array of paths to be excluded
          #
          def pull_exclude_paths(remote_task_dir:, paths_to_exclude:)
            Pathname.new(remote_task_dir.relative_path)
                    .dirname
                    .ascend
                    .each_with_object([]) do |directory, array|
                      path = directory.to_path
                      path.prepend('/') unless path.match? %r{^/}
                      path.concat('/') unless path.match? %r{/$}
                      path.concat('*')
                      array << path
                    end
                    .concat(paths_to_exclude)
                    .concat(['/*'])
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
