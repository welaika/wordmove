module Wordmove
  module Actions
    # Given the command line options and given the denied-by-config actions,
    # selects the actions to be run altering the context.
    class FilterAndSetupTasksToRun
      extend ::LightService::Action
      include Wordmove::Actions::Helpers
      include Wordmove::Actions::Ssh::Helpers
      include WordpressDirectory::RemoteHelperMethods

      expects :guardian,
              :cli_options
      promises :folder_tasks,
               :database_task,
               :wordpress_task

      # @!method execute
      #   @param guardian [Wordmove::Guardian]
      #   @param cli_options [Hash]
      #   @return [LightService::Context] Action's context
      executed do |context|
        all_taks = Wordmove::CLI.wordpress_options

        required_tasks = all_taks.select do |task|
          context.cli_options[task] ||
            (context.cli_options[:all] && context.cli_options[task] != false)
        end

        allowed_tasks = required_tasks.select { |task| context.guardian.allows task }

        # Since we `promises` the following variables, we cannot set them as `nil`
        context.database_task = allowed_tasks.delete(:db) || false
        context.wordpress_task = allowed_tasks.delete(:wordpress) || false
        # :db and :wordpress were just removed, so we consider
        # the reminders as folder tasks. It's a weak assumption
        # though.
        context.folder_tasks = allowed_tasks
      end
    end
  end
end
