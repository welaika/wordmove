module Wordmove
  module Actions
    module Ssh
      module WpcliAdapter
        class SetupContextForPullDb
          extend ::LightService::Action
          include Wordmove::Actions::Helpers
          include WordpressDirectory::LocalHelperMethods
          expects :cli_options,
                  :local_options,
                  :remote_options,
                  :logger,
                  :photocopier,
                  :movefile
          promises :backup_path,
                   :gzipped_backup_path,
                   :local_dump_path,
                   :local_gzipped_dump_path

          executed do |context|
            context.logger.task 'Pulling Database'

            next context if simulate?(cli_options: context.cli_options)

            content_dir = local_wp_content_dir(local_options: context.local_options)
            context.backup_path = content_dir.path("local-backup-#{Time.now.to_i}.sql")
            context.gzipped_backup_path = context.backup_path + '.gz'
            context.local_dump_path = content_dir.path('dump.sql')
            context.local_gzipped_dump_path = context.local_dump_path + '.gz'
          end
        end
      end
    end
  end
end
