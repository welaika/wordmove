require 'pathname'

# rubocop:disable Metrics/BlockLength
module Wordmove
  module Actions
    module Ssh
      module Helpers
        extend ActiveSupport::Concern

        class_methods do
          def ssh_options(remote_options:, simulate: false)
            ssh_options = remote_options[:ssh]

            if simulate == true && ssh_options[:rsync_options]
              ssh_options[:rsync_options].concat(' --dry-run')
            elsif simulate == true
              ssh_options[:rsync_options] = '--dry-run'
            end

            ssh_options
          end

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
